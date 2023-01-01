package Mixin::Historian::Driver::Array 0.102001;
use base 'Mixin::Historian::Driver';
# ABSTRACT: a driver that stores history in an in-memory array (for testing)

use strict;
use warnings;

#pod =head1 DESCRIPTION
#pod
#pod This driver, meant primarily for testing, logs history events as hashrefs in an
#pod in-memory arrayref stored in the driver.
#pod
#pod The events may accessed by the driver's C<entries> method, and are returned as
#pod a list of hashrefs in the form:
#pod
#pod   {
#pod     time   => $epoch_seconds,
#pod     record => $hashref_passed_to_add_history,
#pod   }
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  return bless {
    array => [],
  } => $class;
}

sub _array {
  $_[0]{array};
}

sub entries {
  my ($self) = @_;
  return @{ $self->_array };
}

sub add_history {
  my ($self, $arg) = @_;

  my $record = $arg->{args}[0];

  push @{ $self->_array }, {
    time   => time,
    record => $record,
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mixin::Historian::Driver::Array - a driver that stores history in an in-memory array (for testing)

=head1 VERSION

version 0.102001

=head1 DESCRIPTION

This driver, meant primarily for testing, logs history events as hashrefs in an
in-memory arrayref stored in the driver.

The events may accessed by the driver's C<entries> method, and are returned as
a list of hashrefs in the form:

  {
    time   => $epoch_seconds,
    record => $hashref_passed_to_add_history,
  }

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
