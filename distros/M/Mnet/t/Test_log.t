
# purpose: tests Mnet::Test with Mnet::Log module

# required modules
#   Text::Diff required in Mnet::Test diffs, best to find our here if missing
use warnings;
use strict;
use File::Temp;
use Test::More tests => 2;
use Text::Diff;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# use current perl for tests
my $perl = $^X;

# save record file using Mnet::Log
Test::More::is(`( $perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Opts::Set::Silent;
    use Mnet::Test;
    my \$file = shift;
    my \$log = Mnet::Log->new({ record => \$file });
    \$log->debug("debug");
    \$log->info("info1");
    \$log->info("info2");
    \$log->warn("warn1");
    \$log->warn("warn2");
    Mnet::Test::done({ record => \$file });
' -- $file; cat $file | sed "s/^ *//" ) 2>&1`,
"\$Mnet::Test::data = {
'Mnet::Test' => {
'outputs' => 'inf - main info1
inf - main info2
WRN - main warn1
WRN - main warn2
'
}
};
", 'record with mnet log');

# replay file using Mnet::Log and exit status
Test::More::is(`( echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Test;
    my \$file = shift;
    my \$log = Mnet::Log->new({ replay => \$file, test => 1 });
    \$log->debug("debug");
    \$log->info("info1");
    \$log->info("info3");
    \$log->warn("warn1");
    \$log->warn("warn3");
    Mnet::Test::done({ replay => \$file, test => 1 });
' -- $file || echo ERROR ) 2>&1 | sed "s/replay .*/replay/"`, '
--- - Mnet::Log -e started
inf - main info1
inf - main info3
WRN - main warn1
WRN - main warn3

-------------------------------------------------------------------------------
diff --test --replay
-------------------------------------------------------------------------------

@@ -1,4 +1,4 @@
 inf - main info1
-inf - main info3
+inf - main info2
 WRN - main warn1
-WRN - main warn3
+WRN - main warn2

--- - Mnet::Log finished with errors
ERROR
', 'replay test fail with mnet log and exit status');

# finished
exit;

