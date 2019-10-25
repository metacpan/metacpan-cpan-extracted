
# purpose: tests Mnet::Test with Mnet::Opts::Cli --test-reset option

# required modules
use warnings;
use strict;
use File::Temp;
use Test::More tests => 4;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# use current perl for tests
my $perl = $^X;

# init script used to test --test-reset option
my $script = '
    use warnings;
    use strict;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli::define({
        getopt      => "test-opt=i",
        default     => 1,
        record      => 1,
    });
    my ($cli, @extras) = Mnet::Opts::Cli->new;
    syswrite STDOUT, "test-opt = $cli->{test_opt}\n";
    syswrite STDOUT, "extras = @extras\n" if @extras;
';

# save record file with test-opt and extra cli opts
Test::More::is(`$perl -e '$script' -- --record $file --test-opt 2 extra 2>&1`,
'test-opt = 2
extras = extra
', 'record with test-opt and extra cli arg');

# replay file with test-opt and extra cli opts
Test::More::is(`$perl -e '$script' -- --replay $file 2>&1`,
'test-opt = 2
extras = extra
', 'replay with test-opt and extra arg');

# replay file with --test-reset test-opt
Test::More::is(
`$perl -e '$script' -- --replay $file --test-reset test-opt 2>&1`,
'test-opt = 1
extras = extra
', 'replay with reset of cli test-opt');

# replay file with --test-reset extra cli args
Test::More::is(`$perl -e '$script' -- --replay $file --test-reset 2>&1`,
'test-opt = 2
', 'replay with reset of extra cli args');

# finished
exit;

