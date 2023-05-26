package SyForm::ResultsRole::Verify;
BEGIN {
  $SyForm::ResultsRole::Verify::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Trait for SyForm fields of SyForm::Results and SyForm::Values attributes
$SyForm::ResultsRole::Verify::VERSION = '0.103';
use Moo::Role;

requires qw(
  success
);

has syccess_result => (
  is => 'ro',
  required => 1,
);

has error_count => (
  is => 'lazy',
);

sub _build_error_count {
  my ( $self ) = @_;
  $self->syccess_result->error_count;
}

1;

__END__

=pod

=head1 NAME

SyForm::ResultsRole::Verify - Trait for SyForm fields of SyForm::Results and SyForm::Values attributes

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
