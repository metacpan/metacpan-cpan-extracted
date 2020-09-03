
# purpose: tests Mnet::Test with Mnet::Opts::Cli module

# required modules
#   Text::Diff required in Mnet::Test diffs, best to find our here if missing
use warnings;
use strict;
use File::Temp;
use Mnet::T;
use Test::More tests => 3;
use Text::Diff;

# create temp record/replay/test file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# init script used to test mnet cli opt and extra arg
my $perl = '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli::define({
        getopt      => "sample=i",
        default     => 1,
        record      => 1,
    });
    my ($cli, @extras) = Mnet::Opts::Cli->new;
    syswrite STDOUT, "sample = $cli->{sample}\n";
    syswrite STDOUT, "extras = @extras\n" if @extras;
';

# record with mnet cli opt and extra arg
Mnet::T::test_perl({
    name    => 'record with mnet cli opt and extra arg',
    perl    => $perl,
    args    => "--quiet --record $file --sample 2 extra",
    post    => "cat $file",
    filter  => "sed 's/^ *//'",
    expect  => <<'    expect-eof',
        $Mnet::Test::data = {
        'Mnet::Opts::Cli' => {
        'extras' => [
        'extra'
        ],
        'opts' => {
        'sample' => 2
        }
        },
        'Mnet::Test' => {
        'outputs' => 'inf - Mnet::Opts::Cli new parsed opt cli sample = 2
        inf - Mnet::Opts::Cli new parsed cli arg (extra) = "extra"
        sample = 2
        extras = extra
        '
        }
        };
    expect-eof
    debug   => '--debug --noquiet',
});

# replay with mnet cli opt and extra arg
Mnet::T::test_perl({
    name    => 'replay with mnet cli opt and extra arg',
    perl    => $perl,
    args    => "--replay $file --test",
    filter  => 'grep -v ^--- | grep . | sed "s/replay .*/replay/"',
    expect  => <<'    expect-eof',
        inf - Mnet::Opts::Cli new parsed opt cli sample = 2
        inf - Mnet::Opts::Cli new parsed cli arg (extra) = "extra"
        sample = 2
        extras = extra
        diff --test --replay
        Test output is identical.
    expect-eof
    debug   => '--debug',
});

# replay with overridden cli opt and extra arg
Mnet::T::test_perl({
    name    => 'replay with overridden cli opt and extra arg',
    perl    => $perl,
    args    => "--replay $file --test --sample 3 arg",
    filter  => 'grep -v ^--- | grep . | sed "s/replay .*/replay/"',
    expect  => <<'    expect-eof',
        inf - Mnet::Opts::Cli new parsed opt cli sample = 3
        inf - Mnet::Opts::Cli new parsed cli arg (extra) = "arg"
        sample = 3
        extras = arg
        diff --test --replay
        @@ -1,4 +1,4 @@
        -inf - Mnet::Opts::Cli new parsed opt cli sample = 2
        +inf - Mnet::Opts::Cli new parsed opt cli sample = 3
        -inf - Mnet::Opts::Cli new parsed cli arg (extra) = "extra"
        +inf - Mnet::Opts::Cli new parsed cli arg (extra) = "arg"
        -sample = 2
        +sample = 3
        -extras = extra
        +extras = arg
    expect-eof
    debug   => '--debug',
});

# finished
exit;

