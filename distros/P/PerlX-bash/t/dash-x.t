use Test::Most 0.25;
use Test::Output;

use PerlX::bash;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;
use TestUtilFuncs qw< bash_debug_is >;


bash_debug_is { bash -x => $^X, -e => 'exit 0' } "+ $^X -e 'exit 0'\n", 'basic bash -x works';


done_testing;
