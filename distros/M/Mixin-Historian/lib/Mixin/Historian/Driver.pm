use strict;
use warnings;
package Mixin::Historian::Driver;
{
  $Mixin::Historian::Driver::VERSION = '0.102000';
}
# ABSTRACT: base class for classes that act as Historian storage drivers


1;

__END__

=pod

=head1 NAME

Mixin::Historian::Driver - base class for classes that act as Historian storage drivers

=head1 VERSION

version 0.102000

=head1 METHODS

Classes extending Mixin::Historian::Driver are expected to provide the
following methods:

=head1 new

This method gets the driver configuration from the call to
L<Mixin::Historian>'s C<import> method and should return a new driver instance.

=head1 add_history

This method is passed an arrayref of the argument(s) to the generated and
installed C<add_history> method.  It is is expected to store the history entry.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
