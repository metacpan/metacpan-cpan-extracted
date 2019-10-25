
# purpose: tests Mnet::Log basic functionality, functions, and methods

# required modules
use warnings;
use strict;
use Test::More tests => 5;

# use current perl for tests
my $perl = $^X;

# check starting log entry without Mnet::Log::Test, with time, pid, and date
{
    chomp(my $out = `$perl -e '
        use warnings;
        use strict;
        use Mnet::Log qw( INFO );
        INFO("test");
    ' -- 2>&1 | head -n 1`);
    my ($time, $pid, $date) = ("hh:mm:ss", "pid", "day mon date hh:mm:ss yyyy");
    $time = $1 if $out =~ /^(\d\d:\d\d:\d\d)/;
    $pid = $1 if $out =~ /started, pid (\d+)/;
    $date = $1 if $out =~ /(\S\S\S \S\S\S  ?\d\d? \d\d:\d\d:\d\d \d\d\d\d)$/;
    Test::More::is(
        $out,
        "$time  -  - Mnet::Log -e started, pid $pid, $date",
        "timestamped started entry"
    );
}

# check finished log entry without Mnet::Log::Test, with time, pid, and date
{
    chomp(my $out = `$perl -e '
        use warnings;
        use strict;
        use Mnet::Log qw( DEBUG );
        DEBUG("test");
    ' -- 2>&1 | tail -n 1`);
    my ($time, $pid, $elapsed) = ("hh:mm:ss", "pid", "secs seconds elapsed");
    $time = $1 if $out =~ /^(\d\d:\d\d:\d\d)/;
    $pid = $1 if $out =~ /errors, pid (\d+)/;
    $elapsed = $1 if $out =~ /(\d+\.\d+ seconds elapsed)$/;
    Test::More::is(
        $out,
        "$time  -  - Mnet::Log finished with no errors, pid $pid, $elapsed",
        "timestamped finished entry"
    );
}

# check output from Mnet::Log functions
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log qw( DEBUG INFO WARN FATAL );
    use Mnet::Log::Test;
    DEBUG("debug");
    INFO("info");
    WARN("warn");
    FATAL("fatal");
' -- 2>&1`, ' -  - Mnet::Log -e started
inf - main info
WRN - main warn
DIE - main fatal
 -  - Mnet::Log finished with errors
', 'function calls');

# check output from Mnet::Log methods
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    Mnet::Log->new->debug("debug");
    Mnet::Log->new->info("info");
    Mnet::Log->new->warn("warn");
    Mnet::Log->new->fatal("fatal");
' -- 2>&1`, ' -  - Mnet::Log -e started
inf - main info
WRN - main warn
DIE - main fatal
 -  - Mnet::Log finished with errors
', 'method calls');

# check output from Mnet::Log with exit status set for error
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    Mnet::Log->new->debug("debug");
    exit 1;
' -- 2>&1`, ' -  - Mnet::Log -e started
 -  - Mnet::Log finished with exit error status
', 'exit error status');

# finished
exit;

