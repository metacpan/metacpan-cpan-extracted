package MooseX::DeclareX::Plugin::build;

BEGIN {
	$MooseX::DeclareX::Plugin::build::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::build::VERSION   = '0.009';
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
		'MooseX::DeclareX::Plugin::build::MethodModifier'->new(
			identifier    => 'build',
		);
	
	return $return;
}

package MooseX::DeclareX::Plugin::build::MethodModifier;

BEGIN {
	$MooseX::DeclareX::Plugin::build::MethodModifier::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::build::MethodModifier::VERSION   = '0.009';
}

use Moose;
extends 'MooseX::Declare::Syntax::Keyword::Method';

override register_method_declaration => sub
{
	my ($me, $meta, $name, $method) = @_;

	if (my $attr = $meta->find_attribute_by_name($name))
	{
		no warnings 'uninitialized';
		$meta->add_attribute("+$name" => (lazy_build => 1))
			unless $attr->builder eq "_build_$name";
	}
	else
	{
		$meta->add_attribute(
			$name => (
				lazy_build => 1,
				is         => 'ro',
				isa        => ($method->has_return_signature ? $method->return_signature : 'Any'),
			)
		);
	}

	$meta->add_method("_build_$name", $method);
};

1;
