package Padre::Plugin::Moose::Role::CanGenerateCode;

use Moose::Role;

our $VERSION = '0.21';

sub generate_code {
	my $self    = shift;
	my $options = shift;
	my $type    = $options->{type};

	return $self->generate_moose_code($options)          if $type eq 'Moose';
	return $self->generate_mouse_code($options)          if $type eq 'Mouse';
	return $self->generate_moosex_declare_code($options) if $type eq 'MooseX::Declare';
}

requires 'generate_moose_code';
requires 'generate_mouse_code';
requires 'generate_moosex_declare_code';

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Role::CanGenerateCode - Something that can generate Moose, Mouse or MooseX::Declare code

=cut
