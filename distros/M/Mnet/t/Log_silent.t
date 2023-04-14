
# purpose: tests Mnet::Log silent

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 6;

# functions with silent pragma option
Mnet::T::test_perl({
    name    => 'functions with silent pragma option',
    perl    => <<'    perl-eof',
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
    perl-eof
    expect  => '',
});

# methods with silent pragma option
Mnet::T::test_perl({
    name    => 'functions with silent pragma option',
    perl    => <<'    perl-eof',
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
    perl-eof
    expect  => '',
});

# silent log object option
Mnet::T::test_perl({
    name    => 'silent log object option',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        Mnet::Log->new({ silent => 1})->debug("TEST debug");
        Mnet::Log->new({ silent => 1})->info("TEST info");
        Mnet::Log->new({ silent => 1})->warn("TEST warn");
        Mnet::Log->new({ silent => 1})->fatal("TEST fatal");
    perl-eof
    filter  => 'grep -v Mnet::Version',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        --- - Mnet::Log finished, errors
    expect-eof
});

# slent cli option
Mnet::T::test_perl({
    name    => 'silent cli option',
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
    args    => '--silent',
    expect  => '',
});

# stdout/stderr with silent pragma
Mnet::T::test_perl({
    name    => 'stdout/stderr with silent pragma',
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

# --quiet overriding silent pragma
Mnet::T::test_perl({
    name    => '--quiet overriding silent pragma',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log qw( DEBUG INFO WARN FATAL );
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        use Mnet::Opts::Set::Debug;
        use Mnet::Opts::Set::Silent;
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

# finished
exit;

