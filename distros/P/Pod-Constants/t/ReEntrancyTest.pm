package ReEntrancyTest;
use strict;
use warnings;

our $wohoo;
use Pod::Constants -debug => 1, -trim => 1, foobar => \$wohoo;

=head1 foobar

Re-entrancy works!

=cut

1;
