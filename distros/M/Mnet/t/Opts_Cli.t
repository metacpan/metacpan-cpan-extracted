
# purpose: tests Mnet::Opts::Cli

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 9;

# display --version
Mnet::T::test_perl({
    name    => 'display --version',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli->new;
    perl-eof
    args    => '--version',
    filter  => 'grep "Mnet version" | wc -l | sed "s/^ *//"',
    expect  => '1',
});

# display --help
Mnet::T::test_perl({
    name    => 'display --help',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli->new;
    perl-eof
    args    => '--help',
    filter  => 'grep -e "--" | sed "s/^ *//"',
    expect  => <<'    expect-eof',
        --help [s]   display option help, *try --help help
        --version    display version and system information
    expect-eof
});

# parse cli opt without changing ARGV
Mnet::T::test_perl({
    name    => 'parse cli opt without changing ARGV',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
        my $cli = Mnet::Opts::Cli->new;
        print $cli->{test_opt} ."\n";
        print $cli->test_opt ."\n";
        print "@ARGV\n";
    perl-eof
    args    => '--test-opt test',
    expect  => "test\ntest\n--test-opt test",
});

# parse cli opt and extras without changing ARGV
Mnet::T::test_perl({
    name    => 'parse cli opt and extras without changing ARGV',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
        my ($cli, @extras) = Mnet::Opts::Cli->new;
        print $cli->{test_opt} ."\n";
        print $cli->test_opt ."\n";
        print "@extras\n";
        print "@ARGV\n";
    perl-eof
    args    => '--test-opt test extra1 extra2',
    expect  => "test\ntest\nextra1 extra2\n--test-opt test extra1 extra2",
});

# invalid or missing args
Mnet::T::test_perl({
    name    => 'invalid or missing args',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
        my $cli = Mnet::Opts::Cli->new;
    perl-eof
    args    => '--test-opt test extra1 extra2',
    expect  => 'invalid or missing args extra1 extra2',
});

# invalid cli opt
Mnet::T::test_perl({
    name    => 'invalid cli opt',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        my $cli = Mnet::Opts::Cli->new;
    perl-eof
    args    => '--test-opt test',
    expect  => 'invalid or missing args --test-opt test',
});

# undef --test-reset
Mnet::T::test_perl({
    name    => 'undef --test-reset',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        use Mnet::Test;
        Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
        warn "test-opt" if defined Mnet::Opts::Cli->new->test_opt;
    perl-eof
    args    => '--test-opt test --test-reset test-opt',
    expect  => '',
});

# defined --test-reset
Mnet::T::test_perl({
    name    => 'defined --test-reset',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Opts::Cli;
        use Mnet::Test;
        Mnet::Opts::Cli::define({ getopt => "test-opt=s", default => "def" });
        warn "test-opt" if Mnet::Opts::Cli->new->test_opt ne "def";
    perl-eof
    args    => '--test-opt test --test-reset test-opt',
    expect  => '',
});

# cli option logging
Mnet::T::test_perl({
    name    => 'cli option logging',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
        Mnet::Opts::Cli->new;
    perl-eof
    args    => '--test-opt test',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf - Mnet::Opts::Cli new parsed opt cli test-opt = "test"
        --- - Mnet::Log finished, no errors
    expect-eof
});

# finished
exit;

