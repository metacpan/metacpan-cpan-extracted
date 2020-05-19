
# purpose: tests Mnet::Test with Mnet::Log module

# required modules
#   Text::Diff required in Mnet::Test diffs, best to find our here if missing
use warnings;
use strict;
use File::Temp;
use Mnet::T;
use Test::More tests => 2;
use Text::Diff;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# record with mnet log
Mnet::T::test_perl({
    name    => 'record with mnet log',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Silent;
        use Mnet::Test;
        my $file = shift;
        my $log = Mnet::Log->new({ record => $file });
        $log->debug("debug");
        $log->info("info1");
        $log->info("info2");
        $log->warn("warn1");
        $log->warn("warn2");
        Mnet::Test::done({ record => $file });
    perl-eof
    args    => $file,
    post    => "cat $file",
    filter  => 'sed "s/^ *//"',
    expect  => <<'    expect-eof',
        $Mnet::Test::data = {
        'Mnet::Test' => {
        'outputs' => 'inf - main info1
        inf - main info2
        WRN - main warn1
        WRN - main warn2
        '
        }
        };
    expect-eof
});

# replay test fail with mnet log and exit status
Mnet::T::test_perl({
    name    => 'replay test fail with mnet log and exit status',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Test;
        my $file = shift;
        my $log = Mnet::Log->new({ replay => $file, test => 1 });
        $log->debug("debug");
        $log->info("info1");
        $log->info("info3");
        $log->warn("warn1");
        $log->warn("warn3");
        Mnet::Test::done({ replay => $file, test => 1 });
    perl-eof
    args    => $file,
    filter  => <<'    filter-eof',
        grep -v ^---- | grep . | sed "s/^ *//" | sed "s/replay .*/replay/"
    filter-eof
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf - main info1
        inf - main info3
        WRN - main warn1
        WRN - main warn3
        diff --test --replay
        @@ -1,4 +1,4 @@
        inf - main info1
        -inf - main info3
        +inf - main info2
        WRN - main warn1
        -WRN - main warn3
        +WRN - main warn2
        --- - Mnet::Log finished, errors
    expect-eof
});

# finished
exit;

