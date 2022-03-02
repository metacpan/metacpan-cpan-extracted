########################################################################
# first sanity check: is the module usable.
########################################################################
use v5.24;

my $package = 'Parallel::Queue';

use Test::More;

use_ok $package;

my $version = $package->VERSION;

ok $version , "$package has version ($version)";

ok __PACKAGE__->can( 'runqueue' ), "Installed 'runqueue'";

done_testing;
__END__
