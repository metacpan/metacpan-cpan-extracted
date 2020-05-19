
# purpose: tests Mnet::Log quiet

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 6;

# functions with quiet pragma option
Mnet::T::test_perl({
    name    => 'functions with quiet pragma option',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log qw( DEBUG INFO WARN FATAL );
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        use Mnet::Opts::Set::Quiet;
        DEBUG("debug");
        INFO("info");
        WARN("warn");
        FATAL("fatal");
    perl-eof
    expect  => <<'    expect-eof',
        WRN - main warn
        DIE - main fatal
    expect-eof
});

# methods with quiet pragma option
Mnet::T::test_perl({
    name    => 'methods with quiet pragma option',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        use Mnet::Opts::Set::Quiet;
        Mnet::Log->new->debug("debug");
        Mnet::Log->new->info("info");
        Mnet::Log->new->warn("warn");
        Mnet::Log->new->fatal("fatal");
    perl-eof
    expect  => <<'    expect-eof',
        WRN - main warn
        DIE - main fatal
    expect-eof
});

# quiet log object option
Mnet::T::test_perl({
    name    => 'quiet log object option',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        Mnet::Log->new({ quiet => 1})->debug("TEST debug");
        Mnet::Log->new({ quiet => 1})->info("TEST info");
        Mnet::Log->new({ quiet => 1})->warn("TEST warn");
        Mnet::Log->new({ quiet => 1})->fatal("TEST fatal");
    perl-eof
    filter  => 'grep -v Mnet::Version',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        WRN - main TEST warn
        DIE - main TEST fatal
        --- - Mnet::Log finished, errors
    expect-eof
});

# quiet cli option
Mnet::T::test_perl({
    name    => 'quiet cli option',
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
    args    => '--quiet',
    expect  => <<'    expect-eof',
        WRN - main warn
        DIE - main fatal
    expect-eof
});

# quiet perl warnings and die
#   error output from quiet overrides any conflicting silent setting
Mnet::T::test_perl({
    name    => 'quiet perl warnings and die',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Quiet;
        use Mnet::Opts::Set::Silent;
        eval { warn "warn eval\n" };
        warn "warn command\n";
        die "die command\n";
    perl-eof
    filter  => 'grep -v ^err',
    expect  => <<'    expect-eof',
        ERR - main perl warn, warn eval
        ERR - main perl warn, warn command
        ERR - main perl die, die command
    expect-eof
});

# stdout/stederr with quiet pragma
Mnet::T::test_perl({
    name    => 'stdout/stederr with quiet pragma',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Quiet;
        print STDOUT "stdout\n";
        print STDERR "stderr\n";
    perl-eof
    expect  => <<'    expect-eof',
        stdout
        stderr
    expect-eof
});

# finished
exit;

