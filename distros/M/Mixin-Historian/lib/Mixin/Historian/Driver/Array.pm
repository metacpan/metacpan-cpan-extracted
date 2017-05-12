use strict;
use warnings;
package Mixin::Historian::Driver::Array;
{
  $Mixin::Historian::Driver::Array::VERSION = '0.102000';
}
use base 'Mixin::Historian::Driver';
# ABSTRACT: a driver that stores history in an in-memory array (for testing)


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

=head1 NAME

Mixin::Historian::Driver::Array - a driver that stores history in an in-memory array (for testing)

=head1 VERSION

version 0.102000

=head1 DESCRIPTION

This driver, meant primarily for testing, logs history events as hashrefs in an
in-memory arrayref stored in the driver.

The events may accessed by the driver's C<entries> method, and are returned as
a list of hashrefs in the form:

  {
    time   => $epoch_seconds,
    record => $hashref_passed_to_add_history,
  }

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
