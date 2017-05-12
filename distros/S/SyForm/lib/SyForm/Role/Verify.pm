package SyForm::Role::Verify;
BEGIN {
  $SyForm::Role::Verify::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Main verification logic (role for form holding config)
$SyForm::Role::Verify::VERSION = '0.102';
use Moo::Role;
use Module::Runtime qw( use_module );

has verify_without_errors => (
  is => 'lazy',
);

sub _build_verify_without_errors {
  my ( $self ) = @_;
  return 0;
}

has syccess => (
  is => 'lazy',
);

sub _build_syccess {
  my ( $self ) = @_;
  return {};
}

has syccess_class => (
  is => 'lazy',
);

sub _build_syccess_class {
  my ( $self ) = @_;
  return 'Syccess';
}

has loaded_syccess_class => (
  is => 'lazy',
);

sub _build_loaded_syccess_class {
  my ( $self ) = @_;
  return use_module($self->syccess_class);
}

1;

__END__

=pod

=head1 NAME

SyForm::Role::Verify - Main verification logic (role for form holding config)

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
