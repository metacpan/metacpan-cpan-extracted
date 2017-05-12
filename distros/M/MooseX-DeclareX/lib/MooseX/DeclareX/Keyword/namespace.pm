package MooseX::DeclareX::Keyword::namespace;

BEGIN {
	$MooseX::DeclareX::Keyword::namespace::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Keyword::namespace::VERSION   = '0.009';
}

require MooseX::Declare;

use Moose;
extends 'MooseX::Declare::Syntax::Keyword::Namespace';
with qw(
	MooseX::DeclareX::Plugin
	MooseX::DeclareX::Registry
);

has allowed_option_names => (
	is        => 'ro',
	isa       => 'ArrayRef',
	default   => sub { [] },
);

sub preferred_identifier { 'namespace' }

sub add_optional_customizations {}

1;
