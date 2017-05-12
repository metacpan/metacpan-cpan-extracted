
use Test::More;

plan skip_all => 'Test irrelevant on non-Windows systems' if $^O !~ /^(MSWin32|cygwin)/i;

plan tests => 2;

use_ok('Module::Which::P5Path', qw(path_to_p5path p5path_to_path));

use Config;

my $archlib = $Config{installarchlib};
my $path = "\U$Config{installarchlib}\E/A/AA.pm";

is(path_to_p5path($path), '${installarchlib}/A/AA.pm', "path to p5-path works (case-insensitive)");


