package Cheese;
use strict;
use warnings;

our ($foo, $quux);

sub handle_bar {
	print "GOT HERE\n";
	eval 'use ReEntrancyTest';
	print "GOT HERE TOO. \$\@ is `$@'\n";
}

use Pod::Constants -debug => 1, -trim => 1, foo => \$foo, bar => \&handle_bar, quux => \$quux;

=head1 foo

detcepxe

=head1 bar

=head2 quux

Blah.

=cut

1;
