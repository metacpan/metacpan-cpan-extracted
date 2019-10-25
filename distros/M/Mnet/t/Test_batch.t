
# purpose: tests Mnet::Batch

# required modules
use warnings;
use strict;
use File::Temp;
use Test::More tests => 6;

# create multiple temp test/record/replay files
my ($fh1, $file1) = File::Temp::tempfile( UNLINK => 1 );
my ($fh2, $file2) = File::Temp::tempfile( UNLINK => 1 );

# use current perl for tests
my $perl = $^X;

# init script used to test with mnet batch module
my $script = '
    use warnings;
    use strict;
    use Mnet::Batch;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli::define({ getopt => "sample=i", record => 1 });
    my $cli = Mnet::Opts::Cli->new;
    $cli = Mnet::Batch::fork($cli);
    exit if not defined $cli;
    syswrite STDOUT, "sample = $cli->{sample}\n";
';

# record file 1 for batch test
Test::More::is(`$perl -e '
    $script
' -- --record $file1 --sample 1 2>&1`, 'sample = 1
', 'record file 1');

# record file 2 for batch test
Test::More::is(`echo; $perl -e '
    $script
' -- --record $file2 --sample 2 2>&1`, '
sample = 2
', 'record file 2');

# replay both tests passing in batch mode
Test::More::is(`echo; ( echo --replay $file1; echo --replay $file2 ) | $perl -e '
    $script
' -- --batch /dev/stdin --test 2>&1`, '
', 'batch replay passed');

# replay both tests failing in batch mode due to parent arg
Test::More::is(`echo; ( echo --replay $file1; echo --replay $file2 ) | $perl -e '
    $script
' -- --batch /dev/stdin --test --sample 4 2>&1 | sed "s/ pid .*/ pid .../"`,
'
WRN - Mnet::Batch fork reaped child pid ...
WRN - Mnet::Batch fork reaped child pid ...
', 'batch execution with new parent option');

# replay first failing in batch mode due to parent arg
#   we want to be sure that second child does not get error
Test::More::is(`echo; ( echo --replay $file1; echo --replay $file2 ) | $perl -e '
    $script
' -- --batch /dev/stdin --test --sample 1 2>&1 | sed "s/ pid .*/ pid .../"`,
'
WRN - Mnet::Batch fork reaped child pid ...
', 'batch execution with first child failing');

# replay child test failing in batch mode due to child arg
Test::More::is(`echo; ( echo --replay $file1 --sample 3 ) | $perl -e '
    $script
' -- --batch /dev/stdin --test 2>&1 | sed "s/ pid .*/ pid .../"`, '
WRN - Mnet::Batch fork reaped child pid ...
', 'batch replay child failed');

# finished
exit;

