
# purpose: tests Mnet::Log basic functionality, functions, and methods

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 4;

# timestamped started and finished entries
Mnet::T::test_perl({
    name    => 'timestamped started and finished entries',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
    perl-eof
    filter  => <<'    filter-eof',
        sed 's/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/??:??:??/' | \
        sed 's/pid [0-9][0-9]*/pid ?/' | \
        sed 's/[0-9][0-9]*\.[0-9][0-9]* secs elapsed/? seconds/' | \
        sed 's/... ... .. ..:..:.. [0-9][0-9][0-9][0-9]$/??? ??? ?? ??:??:??/'
    filter-eof
    expect  => <<'    expect-eof',
        ??:??:?? --- - Mnet::Log - started, pid ?, ??? ??? ?? ??:??:??
        ??:??:?? --- - Mnet::Log finished, no errors, pid ?, ? seconds
    expect-eof
    debug   => '--debug',
});

# function calls
Mnet::T::test_perl({
    name    => 'function calls',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log qw( DEBUG INFO WARN FATAL );
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
        DEBUG("debug");
        INFO("info");
        WARN("warn");
        FATAL("fatal");
    perl-eof
    args    => '--debug',
    filter  => <<'    filter-eof',
        grep -e ^--- -e '^dbg - main debug' -e ^inf -e ^WRN -e ^DIE | \
        grep -v Mnet::Opts::Cli
    filter-eof
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        dbg - main debug
        inf - main info
        WRN - main warn
        DIE - main fatal
        --- - Mnet::Log finished, errors
    expect-eof
});

# method calls
Mnet::T::test_perl({
    name    => 'method calls',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
        Mnet::Log->new->debug("debug");
        Mnet::Log->new->info("info");
        Mnet::Log->new->warn("warn");
        Mnet::Log->new->fatal("fatal");
    perl-eof
    args    => '--debug',
    filter  => <<'    filter-eof',
        grep -e ^--- -e '^dbg - main debug' -e ^inf -e ^WRN -e ^DIE | \
        grep -v Mnet::Opts::Cli
    filter-eof
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        dbg - main debug
        inf - main info
        WRN - main warn
        DIE - main fatal
        --- - Mnet::Log finished, errors
    expect-eof
});

# exit error status
Mnet::T::test_perl({
    name    => 'exit error status',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
        exit 1;
    perl-eof
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        --- - Mnet::Log finished, exit error status
    expect-eof
    debug   => '--debug',
});

# finished
exit;

