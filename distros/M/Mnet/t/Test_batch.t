
# purpose: tests Mnet::Batch

# required modules
use warnings;
use strict;
use File::Temp;
use Mnet::T;
use Test::More tests => 5;

# create multiple temp test/record/replay files
my ($fh1, $file1) = File::Temp::tempfile( UNLINK => 1 );
my ($fh2, $file2) = File::Temp::tempfile( UNLINK => 1 );

# init perl used for tests
my $perl = '
    use warnings;
    use strict;
    use Mnet::Batch;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli::define({ getopt => "sample=i", record => 1 });
    my $cli = Mnet::Opts::Cli->new;
    $cli = Mnet::Batch::fork($cli);
    exit if not defined $cli;
    syswrite STDOUT, "sample = $cli->{sample}\n";
';

# record file 1
Mnet::T::test_perl({
    name    => 'record file 1',
    perl    => $perl,
    args    => "--record $file1 --sample 1",
    filter  => 'grep -v ^--- | grep -v ^inf',
    expect  => 'sample = 1',
    debug   => '--debug --noquiet',
});

# record file 2
Mnet::T::test_perl({
    name    => 'record file 2',
    perl    => $perl,
    args    => "--record $file2 --sample 2",
    filter  => 'grep -v ^--- | grep -v ^inf',
    expect  => 'sample = 2',
    debug   => '--debug --noquiet',
});

# batch test replay failures
Mnet::T::test_perl({
    name    => 'batch test replay',
    pre     => '
        export BATCH=$(mktemp); echo "
            --replay '.$file1.'
            --replay '.$file2.'
        " >$BATCH
    ',
    perl    => $perl,
    args    => '--batch $BATCH --test',
    filter  => 'grep -v ^---',
    expect  => '',
    debug   => '--debug --noquiet',
});

# batch test replay child option failure
Mnet::T::test_perl({
    name    => 'batch test replay child option failure',
    pre     => '
        export BATCH=$(mktemp); echo "
            --replay '.$file1.' --sample 3
        " >$BATCH
    ',
    perl    => $perl,
    args    => '--batch $BATCH --test',
    filter  => 'grep -v ^--- | sed "s/ pid .*/ pid .../"',
    expect  => <<'    expect-eof',
        WRN - Mnet::Batch fork reaped child pid ...
    expect-eof
    debug   => '--debug --noquiet',
});

# batch test replay parent option failure
Mnet::T::test_perl({
    name    => 'batch test replay parent option failure',
    pre     => '
        export BATCH=$(mktemp); echo "
            --replay '.$file1.'
            --replay '.$file2.'
        " >$BATCH
    ',
    perl    => $perl,
    args    => '--batch $BATCH --test --sample 1',
    filter  => 'grep -v ^--- | sed "s/ pid .*/ pid .../"',
    expect  => <<'    expect-eof',
        inf - Mnet::Opts::Cli new parsed opt cli sample = 1
        WRN - Mnet::Batch fork reaped child pid ...
    expect-eof
    debug   => '--debug --noquiet',
});

# finished
exit;

