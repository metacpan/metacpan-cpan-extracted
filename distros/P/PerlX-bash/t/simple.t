use Test::Most 0.25;

use PerlX::bash;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;
use TestUtilFuncs qw< throws_error >;


# one of the few things we can absolutely guarantee is installed on a tester's system is Perl itself
# therefore, we're going to mostly be spawning $^X (or else internal bash commands)

# error spawning should throw an exception
throws_error 'bmoogle', qr/command not found/, 'spawn of bad command fails';

# an error from the script is just stuck into the return value
# as a scalar, it should be the value returned
my $status = bash "$^X -e 'exit 33'";
is $status, 33, 'one-line spawn with exit code (scalar context)';

# as a boolean, it should be 0 == success, anything else == failure
my $success = (bash "$^X -e 'exit 0'") ? 'success' : 'failure';
my $failure = (bash "$^X -e 'exit 1'") ? 'success' : 'failure';
is $success, 'success', 'one-line spawn with successful exit (boolean context)';
is $failure, 'failure', 'one-line spawn with failed exit (boolean context)';


# now try multiple arguments: they should just get concatenated together with spaces and run

open(STDIN, '<', File::Spec->devnull);				# because otherwise, if our args get lost, `perl` will hang forever
$status = bash $^X, "-e 'exit 66'";
is $status, 66, "two args cat'ed with space (fore)";
$status = bash "$^X -e", "'exit 67'";
is $status, 67, "two args cat'ed with space (aft)";


# now let's make sure that we're really running bash
# `cd` is a nice builtin command to test
# unlike, say, `echo`, there's no corresponding external command
# if it fails, we know we're not running via `bash`
# and, if it succeeds, there's no harm done (and no output)
lives_ok { bash 'cd /' } "using bash to run commands";


done_testing;
