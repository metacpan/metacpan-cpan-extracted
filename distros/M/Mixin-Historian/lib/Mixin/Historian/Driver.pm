package Mixin::Historian::Driver 0.102001;
# ABSTRACT: base class for classes that act as Historian storage drivers

use strict;
use warnings;

#pod =head1 METHODS
#pod
#pod Classes extending Mixin::Historian::Driver are expected to provide the
#pod following methods:
#pod
#pod =head1 new
#pod
#pod This method gets the driver configuration from the call to
#pod L<Mixin::Historian>'s C<import> method and should return a new driver instance.
#pod
#pod =head1 add_history
#pod
#pod This method is passed an arrayref of the argument(s) to the generated and
#pod installed C<add_history> method.  It is is expected to store the history entry.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mixin::Historian::Driver - base class for classes that act as Historian storage drivers

=head1 VERSION

version 0.102001

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
