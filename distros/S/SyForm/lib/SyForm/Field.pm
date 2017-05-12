package SyForm::Field;
BEGIN {
  $SyForm::Field::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Role for fields in SyForm
$SyForm::Field::VERSION = '0.102';
use Moo;

with qw(
  MooX::Traits
  SyForm::FieldRole::Process
);

has syform => (
  is => 'ro',
  weak_ref => 1,
  required => 1,
);

has name => (
  is => 'ro',
  required => 1,
);

has has_name => (
  is => 'lazy',
);
sub _build_has_name { return 'has_'.($_[0]->name) }

has label => (
  is => 'lazy',
);

sub _build_label {
  my ( $self ) = @_;
  my $name = $self->name;
  $name =~ s/_/ /g;
  return join(' ', map { ucfirst($_) } split(/\s+/,$name) );
}

1;

__END__

=pod

=head1 NAME

SyForm::Field - Role for fields in SyForm

=head1 VERSION

version 0.102

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
