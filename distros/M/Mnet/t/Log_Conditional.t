
# purpose: tests Mnet::Log::Conditional

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 6;

# function calls without Mnet::Log
Mnet::T::test_perl({
    name    => 'function calls without Mnet::Log',
    perl    => <<'    perl-eof',
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
    perl-eof
    expect  => <<'    expect-eof',
        WRN - main warn
        DIE - main fatal
    expect-eof
});

# function calls with Mnet::Log
Mnet::T::test_perl({
    name    => 'function calls with Mnet::Log',
    perl    => <<'    perl-eof',
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
    perl-eof
    filter  => 'grep -v "^dbg - Mnet::Version"',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        dbg - main debug
        inf - main info
        --- - main notice
        WRN - main warn
        DIE - main fatal
        --- - Mnet::Log finished, errors
    expect-eof
});

# method calls without Mnet::Log
Mnet::T::test_perl({
    name    => 'method calls without Mnet::Log',
    perl    => <<'    perl-eof',
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
    perl-eof
    expect  => <<'    expect-eof',
        WRN - main warn
        DIE - main fatal
    expect-eof
});

# method calls with Mnet::Log
Mnet::T::test_perl({
    name    => 'method calls with Mnet::Log',
    perl    => <<'    perl-eof',
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
    perl-eof
    filter  => 'grep -v "^dbg - Mnet::Version"',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        dbg - main debug
        inf - main info
        --- - main notice
        WRN - main warn
        DIE - main fatal
        --- - Mnet::Log finished, errors
    expect-eof
});

# eval with fatal
Mnet::T::test_perl({
    name    => 'eval with fatal',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log::Conditional qw( FATAL );
        use Mnet::Log::Test;
        eval { FATAL "fatal eval" };
        print $@;
    perl-eof
    expect  => 'DIE - main fatal eval',
});

# eval with warn
Mnet::T::test_perl({
    name    => 'eval with warn',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log::Conditional qw( WARN );
        use Mnet::Log::Test;
        eval { WARN "warn eval" };
        print $@;
    perl-eof
    expect  => 'WRN - main warn eval',
});

# finished
exit;

