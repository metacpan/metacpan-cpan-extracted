package SyForm::ViewField;
BEGIN {
  $SyForm::ViewField::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: View fields inside a SyForm::View
$SyForm::ViewField::VERSION = '0.102';
use Moo;

with qw(
  MooX::Traits
  SyForm::ViewFieldRole::Verify
  SyForm::ViewFieldRole::HTML
  SyForm::ViewFieldRole::Bootstrap
);

has field => (
  is => 'ro',
  predicate => 1,
);

has view => (
  is => 'ro',
  required => 1,
  handles => [qw(
    viewfields
    fields
    syform
    results
    values
  )],
);

has name => (
  is => 'ro',
  required => 1,
);

has has_name => (
  is => 'lazy',
);
sub _build_has_name { 'has_'.($_[0]->name) }

has label => (
  is => 'ro',
  predicate => 1,
);

has value => (
  is => 'ro',
  predicate => 1,
);

has result => (
  is => 'ro',
  predicate => 1,
);

sub val {
  my ( $self ) = @_;
  return $self->result if $self->has_result;
  return $self->value if $self->has_value;
  return;
}

sub has_val {
  my ( $self ) = @_;
  return 1 if $self->has_result;
  return 1 if $self->has_value;
  return 0;
}

1;

__END__

=pod

=head1 NAME

SyForm::ViewField - View fields inside a SyForm::View

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
