package MooseX::DeclareX::Plugin::test_case;

BEGIN {
	$MooseX::DeclareX::Plugin::test_case::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::test_case::VERSION   = '0.004';
}

use Moose;
with 'MooseX::DeclareX::Plugin';

use MooseX::Declare ();
use Moose::Util ();

sub plugin_setup
{
	my ($class, $kw) = @_;
	
	$kw->meta->add_around_method_modifier('default_inner', \&_default_inner)
		if $kw->can('default_inner') && $kw->does('MooseX::DeclareX::Keyword::interface::SupportsTestCases');
}

sub _default_inner
{
	my $orig = shift;
	my $self = shift;
	
	my $return = $self->$orig(@_);
	
	push @$return,
		'MooseX::DeclareX::Plugin::test_case::MethodModifier'->new(
			identifier    => 'test_case',
		);
	
	return $return;
}

package MooseX::DeclareX::Plugin::test_case::MethodModifier;

BEGIN {
	$MooseX::DeclareX::Plugin::test_case::MethodModifier::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::test_case::MethodModifier::VERSION   = '0.004';
}

use Moose;
extends 'MooseX::Declare::Syntax::Keyword::Method';

override register_method_declaration => sub
{
	my ($me, $meta, $name, $method) = @_;
	$meta->add_test_case($method->actual_body, $name);
};

1;
