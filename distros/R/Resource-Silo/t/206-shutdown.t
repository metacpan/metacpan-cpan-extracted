#!/usr/bin/env perl

=head1 DESCRIPTION

Ensure that all resources are free correctly before program terminates.

=cut

use strict;
use warnings;
use Test::More tests => 5;

my $counter = 0;
END {
    # This end block MUST come before we use Resource::Silo
    # because otherwise it will be executed before
    # Resource::Silo's own END block which we're testing here.
    is $counter, 0, 'rec count at zero';
};

{
    package My::Res;
    sub new {
        $counter++;
        return bless {}, shift;
    };
    sub DESTROY {
        $counter--;
    };
}

use Resource::Silo;
resource foo => sub { My::Res->new };

is $counter, 0, 'nothing is initialized';
is ref silo->foo, 'My::Res', 'created a resource';
is $counter, 1, 'counter increased';

END {
    is $counter, 1, 'counter still nonzero';
};
# see END block above

