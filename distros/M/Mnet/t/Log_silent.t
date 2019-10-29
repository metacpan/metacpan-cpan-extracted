
# purpose: tests Mnet::Log silent

# required modules
use warnings;
use strict;
use Test::More tests => 5;

# use current perl for tests
my $perl = $^X;

# check functions with Mnet::Opts::Set::Silent pragma option
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log qw( DEBUG INFO WARN FATAL );
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    use Mnet::Opts::Set::Silent;
    DEBUG("debug");
    INFO("info");
    WARN("warn");
    FATAL("fatal");
' -- 2>&1`, '', 'functions with silent pragma option');

# check methods with Mnet::Opts::Set::Silent pragma option
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    use Mnet::Opts::Set::Silent;
    Mnet::Log->new->debug("debug");
    Mnet::Log->new->info("info");
    Mnet::Log->new->warn("warn");
    Mnet::Log->new->fatal("fatal");
' -- 2>&1`, '', 'methods with silent pragma option');

# check methods with Mnet::Log->new object silent option
Test::More::is(`echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    Mnet::Log->new({ silent => 1})->debug("TEST debug");
    Mnet::Log->new({ silent => 1})->info("TEST info");
    Mnet::Log->new({ silent => 1})->warn("TEST warn");
    Mnet::Log->new({ silent => 1})->fatal("TEST fatal");
' -- 2>&1 | grep -e '- Mnet::Log' -e 'Mnet ver' -e TEST | sed 's/=.*/= dev/'`, '
--- - Mnet::Log -e started
dbg - Mnet::Version Mnet version = dev
--- - Mnet::Log finished with errors
', 'silent object option');

# check functions with --silent cli option
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log qw( DEBUG INFO WARN FATAL );
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli->new;
    DEBUG("debug");
    INFO("info");
    WARN("warn");
    FATAL("fatal");
' -- --silent 2>&1`, '', 'silent cli option');

# check stdout and stderr with --silent cli option
#   only Mnet::Log entries are affected by silent
#   silence other script output using /dev/null redirect
Test::More::is(`echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    print STDOUT "stdout\n";
    print STDERR "stderr\n";
' -- --silent 2>&1`, '
stdout
stderr
', 'silent stdout and stderr');

# finished
exit;

