package SyForm::FieldRole::Verify;
BEGIN {
  $SyForm::FieldRole::Verify::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: SyForm::Verify configuration of the field
$SyForm::FieldRole::Verify::VERSION = '0.102';
use Moo::Role;

has verify => (
  is => 'ro',
  predicate => 1,
);

has required => (
  is => 'ro',
  predicate => 1,
);

has delete_on_invalid_result => (
  is => 'lazy',
);

sub _build_delete_on_invalid_result {
  my ( $self ) = @_;
  return 1;
}

1;

__END__

=pod

=head1 NAME

SyForm::FieldRole::Verify - SyForm::Verify configuration of the field

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
