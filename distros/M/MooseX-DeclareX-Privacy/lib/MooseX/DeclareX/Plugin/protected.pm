package MooseX::DeclareX::Plugin::protected;

BEGIN {
	$MooseX::DeclareX::Plugin::protected::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::protected::VERSION   = '0.006';
}

use Moose;
with 'MooseX::DeclareX::Plugin';

use MooseX::Declare ();
use Moose::Util ();
use MooseX::Privacy ();
use MooseX::Privacy::Meta::Method::Protected ();

sub plugin_setup
{
	my ($class, $kw) = @_;
	
	Moose::Util::apply_all_roles(
		$kw,
		'MooseX::DeclareX::Plugin::protected::Role',
	)
		if $kw->can('add_namespace_customizations');
}

sub HAS
{
	my $attrs = shift;
	Moose->throw_error('Usage: protected has \'name\' => ( key => value, ... )')
		if @_ % 2 == 1;
	$attrs = [$attrs] unless ref $attrs eq 'ARRAY';
	my %options = ( definition_context => Moose::Util::_caller_info(), @_ );
	push @{ $options{traits} }, 'Protected';
	caller->meta->add_attribute($_, %options) for @$attrs;
}

package MooseX::DeclareX::Plugin::protected::Role;

BEGIN {
	$MooseX::DeclareX::Plugin::protected::Role::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::protected::Role::VERSION   = '0.006';
}

use Moose::Role;

after add_namespace_customizations => sub 
{
	my ($self, $ctx, $package, $attribs) = @_;
	$ctx->add_scope_code_parts(
		"BEGIN { MooseX::DeclareX::Plugin::protected::Parser->import() }",
		"BEGIN { Moose::Util::MetaRole::apply_metaroles(for => __PACKAGE__, class_metaroles => { class => ['MooseX::Privacy::Meta::Class'] }) }",
	);
	return 1;
};

package MooseX::DeclareX::Plugin::protected::Parser;

BEGIN {
	$MooseX::DeclareX::Plugin::protected::Parser::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::protected::Parser::VERSION   = '0.006';
}

use Moose;
extends 'MooseX::DeclareX::MethodPrefix';

sub handle_has { 'MooseX::DeclareX::Plugin::protected::HAS' };

override prefix_keyword => sub { 'protected' };
override install_method => sub {
	my ($self, $method) = @_;
	my $wrapped = 'MooseX::Privacy::Meta::Method::Protected'->wrap(
		name          => $method->name,
		package_name  => $method->package_name,
		body          => $method,
	);
	Class::MOP::class_of( $method->package_name )
		->add_protected_method($method->name, $wrapped);
};

1;

