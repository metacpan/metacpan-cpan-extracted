package MooseX::DeclareX::RegistryUsing;

BEGIN {
	$MooseX::DeclareX::RegistryUsing::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::RegistryUsing::VERSION   = '0.009';
}

use Moose::Role;
use MooseX::Declare::Context::WithOptions::Patch::Extensible 0.001;

around allowed_option_names => sub
{
	my $orig    = shift;
	my $self    = shift;
	
	my $allowed = $self->$orig(@_);
	push @$allowed, sort keys %MooseX::DeclareX::Registry::context_allow_options;
	return $allowed;
};

1;

