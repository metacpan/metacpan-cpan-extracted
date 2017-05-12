package MooseX::DeclareX::Plugin::private;

BEGIN {
	$MooseX::DeclareX::Plugin::private::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::private::VERSION   = '0.006';
}

use Moose;
with 'MooseX::DeclareX::Plugin';

use MooseX::Declare ();
use Moose::Util ();
use MooseX::Privacy ();
use MooseX::Privacy::Meta::Method::Private ();

sub plugin_setup
{
	my ($class, $kw) = @_;
	
	Moose::Util::apply_all_roles(
		$kw,
		'MooseX::DeclareX::Plugin::private::Role',
	)
		if $kw->can('add_namespace_customizations');
}

sub HAS
{
	my $attrs = shift;
	Moose->throw_error('Usage: private has \'name\' => ( key => value, ... )')
		if @_ % 2 == 1;
	$attrs = [$attrs] unless ref $attrs eq 'ARRAY';
	my %options = ( definition_context => +{ Moose::Util::_caller_info() }, @_ );
	push @{ $options{traits} }, 'Private';
	caller->meta->add_attribute($_, %options) for @$attrs;
}

package MooseX::DeclareX::Plugin::private::Role;

BEGIN {
	$MooseX::DeclareX::Plugin::private::Role::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::private::Role::VERSION   = '0.006';
}

use Moose::Role;

after add_namespace_customizations => sub 
{
	my ($self, $ctx, $package, $attribs) = @_;
	$ctx->add_scope_code_parts(
		"BEGIN { MooseX::DeclareX::Plugin::private::Parser->import() }",
		"BEGIN { Moose::Util::MetaRole::apply_metaroles(for => __PACKAGE__, class_metaroles => { class => ['MooseX::Privacy::Meta::Class'] }) }",
	);
	return 1;
};

package MooseX::DeclareX::Plugin::private::Parser;

BEGIN {
	$MooseX::DeclareX::Plugin::private::Parser::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::private::Parser::VERSION   = '0.006';
}

use Moose;
extends 'MooseX::DeclareX::MethodPrefix';

sub handle_has { 'MooseX::DeclareX::Plugin::private::HAS' };

override prefix_keyword => sub { 'private' };
override install_method => sub {
	my ($self, $method) = @_;
	my $wrapped = 'MooseX::Privacy::Meta::Method::Private'->wrap(
		name          => $method->name,
		package_name  => $method->package_name,
		body          => $method,
	);
	Class::MOP::class_of( $method->package_name )
		->add_private_method($method->name, $wrapped);
};

1;

