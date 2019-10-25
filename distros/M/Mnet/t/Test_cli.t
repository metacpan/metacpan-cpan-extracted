
# purpose: tests Mnet::Test with Mnet::Opts::Cli module

# required modules
#   Text::Diff required in Mnet::Test diffs, best to find our here if missing
use warnings;
use strict;
use File::Temp;
use Test::More tests => 3;
use Text::Diff;

# create temp record/replay/test file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# use current perl for tests
my $perl = $^X;

# init script used to test mnet cli opt and extra arg
my $script = '
    use warnings;
    use strict;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
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

# save record file using Mnet::Opts::Cli
Test::More::is(`( $perl -e '
    $script
' -- --record $file --sample 2 extra; cat $file | sed "s/^ *//" ) 2>&1`,
"sample = 2
extras = extra
\$Mnet::Test::data = {
'Mnet::Opts::Cli' => {
'extras' => [
'extra'
],
'opts' => {
'sample' => 2
}
},
'Mnet::Test' => {
'outputs' => 'sample = 2
extras = extra
'
}
};
", 'record with mnet cli opt and extra arg');

# replay file using Mnet::Opts::Cli
Test::More::is(`$perl -e '
    $script
' -- --replay $file --test 2>&1 | sed "s/replay .*/replay/"`,
"sample = 2
extras = extra

-------------------------------------------------------------------------------
diff --test --replay
-------------------------------------------------------------------------------

Test output is identical.

", 'replay with mnet cli opt and extra arg');


# replay file using Mnet::Opts::Cli
Test::More::is(`$perl -e '
    $script
' -- --replay $file --test --sample 3 arg 2>&1 | sed "s/replay .*/replay/"`,
"sample = 3
extras = arg

-------------------------------------------------------------------------------
diff --test --replay
-------------------------------------------------------------------------------

@@ -1,2 +1,2 @@
-sample = 3
+sample = 2
-extras = arg
+extras = extra

", 'replay with overridden cli opt and extra arg');

# finished
exit;

