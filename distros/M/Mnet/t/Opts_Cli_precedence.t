
# purpose: tests Mnet::Opts::Cli precendence of options

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 4;

# default option value
Mnet::T::test_perl({
    name    => 'default option value',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
        warn "quiet" if defined $cli->quiet;
    perl-eof
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        --- - Mnet::Log finished, no errors
    expect-eof
});

# Mnet::Opts::Set pragma
#   check that pragma setting overrides default
Mnet::T::test_perl({
    name    => 'Mnet::Opts::Set pragma',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        use Mnet::Opts::Set::Quiet;
        my $cli = Mnet::Opts::Cli->new;
        warn "quiet" if not $cli->quiet;
    perl-eof
    expect  => '',
});

# options enviroment variable
#   check that optional options env var overrides pragma setting
#   sed/grep used to filter pid/timestamps, can't use Mnet::Test with env var
Mnet::T::test_perl({
    name    => 'options enviroment variable',
    pre     => 'export Mnet="--noquiet"',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Opts::Cli;
        use Mnet::Opts::Set::Quiet;
        my $cli = Mnet::Opts::Cli->new("Mnet");
        warn "quiet" if $cli->quiet;
    perl-eof
    filter  => 'grep Mnet::Opts::Cli | sed "s/.*inf - Mnet/inf - Mnet/"',
    expect  => 'inf - Mnet::Opts::Cli new parsed opt env quiet = 0',
});

# command line
#   check that Mnet env var overrides pragma setting
#   can't use Mnet::Test with env var
Mnet::T::test_perl({
    name    => 'command line',
    pre     => 'export Mnet="--noquiet"',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Opts::Cli;
        use Mnet::Opts::Set::Quiet;
        my $cli = Mnet::Opts::Cli->new;
        warn "quiet" if not $cli->quiet;
    perl-eof
    args    => '--quiet',
    expect  => '',
});

# finished
exit;

