
# purpose: tests Mnet::Log::Conditional

# required modules
use warnings;
use strict;
use Test::More tests => 6;

# use current perl for tests
my $perl = $^X;

# check output from Mnet::Log::Conditional functions without Mnet::Log loaded
Test::More::is(`echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Log::Conditional qw( DEBUG INFO NOTICE WARN FATAL );
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    DEBUG("debug");
    INFO("info");
    NOTICE("notice");
    WARN("warn");
    FATAL("fatal");
' -- 2>&1`, '
WRN - main warn
DIE - main fatal
', 'function calls without Mnet::Log');

# check output from Mnet::Log::Conditional functions with Mnet::Log loaded
Test::More::is(`echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Conditional qw( DEBUG INFO NOTICE WARN FATAL );
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    DEBUG("debug");
    INFO("info");
    NOTICE("notice");
    WARN("warn");
    FATAL("fatal");
' -- 2>&1 | grep -v "^dbg - Mnet::Version"`, '
--- - Mnet::Log -e started
dbg - main debug
inf - main info
--- - main notice
WRN - main warn
DIE - main fatal
--- - Mnet::Log finished with errors
', 'function calls with Mnet::Log');

# check output from Mnet::Log::Conditional methods without Mnet::Log loaded
Test::More::is(`echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Log::Conditional;
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    Mnet::Log::Conditional->new->debug("debug");
    Mnet::Log::Conditional->new->info("info");
    Mnet::Log::Conditional->new->notice("notice");
    Mnet::Log::Conditional->new->warn("warn");
    Mnet::Log::Conditional->new->fatal("fatal");
' -- 2>&1`, '
WRN - main warn
DIE - main fatal
', 'method calls without Mnet::Log');

# check output from Mnet::Log::Conditional methods with Mnet::Log loaded
Test::More::is(`echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Conditional;
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    Mnet::Log::Conditional->new->debug("debug");
    Mnet::Log::Conditional->new->info("info");
    Mnet::Log::Conditional->new->notice("notice");
    Mnet::Log::Conditional->new->warn("warn");
    Mnet::Log::Conditional->new->fatal("fatal");
' -- 2>&1 | grep -v "^dbg - Mnet::Version"`, '
--- - Mnet::Log -e started
dbg - main debug
inf - main info
--- - main notice
WRN - main warn
DIE - main fatal
--- - Mnet::Log finished with errors
', 'method calls with Mnet::Log');

# check output from fatal in eval
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log::Conditional qw( DEBUG INFO WARN FATAL );
    use Mnet::Log::Test;
    eval { FATAL "fatal eval" };
    die if "\$@" ne "DIE - main fatal eval\n";
' -- 2>&1`, '', 'eval with fatal');

# check output from warn in eval
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log::Conditional qw( DEBUG INFO WARN FATAL );
    use Mnet::Log::Test;
    eval { WARN "warn eval" };
    die if "\$@";
' -- 2>&1`, 'WRN - main warn eval
', 'eval with warn');

# finished
exit;

