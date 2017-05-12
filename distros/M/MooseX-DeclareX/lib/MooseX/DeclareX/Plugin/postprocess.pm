package MooseX::DeclareX::Plugin::postprocess;

BEGIN {
	$MooseX::DeclareX::Plugin::postprocess::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::postprocess::VERSION   = '0.009';
}

use Moose;
with 'MooseX::DeclareX::Plugin';

use MooseX::Declare ();
use Moose::Util ();

sub plugin_setup
{
	my ($class, $kw) = @_;
	
	$kw->meta->add_around_method_modifier('default_inner', \&_default_inner)
		if $kw->can('default_inner');
}

sub _default_inner
{
	my $orig = shift;
	my $self = shift;
	
	my $return = $self->$orig(@_);
	
	push @$return,
		'MooseX::DeclareX::Plugin::postprocess::MethodModifier'->new(
			identifier    => 'postprocess',
			modifier_type => 'around',
		);
	
	return $return;
}

package MooseX::DeclareX::Plugin::postprocess::MethodModifier;

BEGIN {
	$MooseX::DeclareX::Plugin::postprocess::MethodModifier::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::postprocess::MethodModifier::VERSION   = '0.009';
}

use Moose;
extends 'MooseX::Declare::Syntax::Keyword::MethodModifier';

override register_method_declaration => sub
{
	my ($me, $meta, $name, $method) = @_;
	
	my $subroutine = sub
	{
		my $orig = shift;
		my $self = shift;
		
		if (wantarray)
		{
			my @rv = $self->$orig(@_);
			return $method->body->($self, @rv);
		}
		elsif (defined wantarray)
		{
			my $rv = $self->$orig(@_);
			return $method->body->($self, $rv);
		}
		else
		{
			unshift @_, $self;
			goto $orig;
		}
	};
	
	return Moose::Util::add_method_modifier(
		$meta->name,
		$me->modifier_type,
		[$name => $subroutine],
	);
};

1;
