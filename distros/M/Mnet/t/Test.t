
# purpose: tests Mnet::Test module

# required modules
use warnings;
use strict;
use File::Temp;
use Test::More tests => 2;
use Mnet::T;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# record, no mnet cli
Mnet::T::test_perl({
    name    => 'record, no mnet cli',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Test;
        my $opts = { record => shift };
        syswrite STDOUT, "stdout1\nstdout2\n";
        syswrite STDERR, "stderr1\nstderr2\n";
        my $data = Mnet::Test::data($opts);
        $data->{key} = "value";
        Mnet::Test::done($opts);
    perl-eof
    args    => $file,
    post    => "cat $file",
    filter  => "sed 's/^ *//'",
    expect  => <<'    expect-eof',
        stdout1
        stdout2
        stderr1
        stderr2
        $Mnet::Test::data = {
        'Mnet::Test' => {
        'outputs' => 'stdout1
        stdout2
        stderr1
        stderr2
        '
        },
        'main' => {
        'key' => 'value'
        }
        };
    expect-eof
});

# test diff replay, no mnet cli
Mnet::T::test_perl({
    name    => 'test diff replay, no mnet cli',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Test;
        my $opts = { replay => shift, test => 1 };
        syswrite STDOUT, "stdout1\nstdout3\n";
        syswrite STDERR, "stderr1\nstderr3\n";
        my $data = Mnet::Test::data($opts);
        warn if $data->{key} ne "value";
        Mnet::Test::done($opts);
    perl-eof
    args    => $file,
    filter  => <<'    filter-eof',
        grep . | grep -v '^-----' | sed 's/ *//' | sed 's/replay .*/replay/'
    filter-eof
    expect  => <<'    expect-eof',
        stdout1
        stdout3
        stderr1
        stderr3
        diff --test --replay
        @@ -1,4 +1,4 @@
        stdout1
        -stdout3
        +stdout2
        stderr1
        -stderr3
        +stderr2
    expect-eof
});

# finished
exit;

