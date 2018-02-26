use 5.006;

use Test::More;
use FindBin::libs;

my $madness = 'Module::FromPerlVer';

require_ok $madness
or BAIL_OUT "$madness is not usable.";

# verify that the package is spelled properly,
# that a version is installed.

ok $madness->can( 'VERSION' ), "$madness can 'VERSION'";
ok $madness->VERSION, "$madness has a VERSION";

done_testing;
__END__
