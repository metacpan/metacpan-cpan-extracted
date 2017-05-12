########################################################################
# first sanity check: is the module usable.
########################################################################

use v5.10;
use strict;

my $package = 'Parallel::Queue';

use Test::More qw( tests 3 );

use_ok $package;

my $version = $package->VERSION;

ok $version , "$package has version ($version)";

ok __PACKAGE__->can( 'runqueue' ), "Installed 'runqueue'";

__END__
