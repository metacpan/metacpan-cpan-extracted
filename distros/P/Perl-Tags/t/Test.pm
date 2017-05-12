package Test;

use strict; use warnings;
use Data::Dumper;

my ($foo, $bar);

=head1 SYNOPSIS

    sub example {
        # this sub should not be parsed!
    }

=cut

sub wibble {
    # blah
}

# TODO: test this line

1;
