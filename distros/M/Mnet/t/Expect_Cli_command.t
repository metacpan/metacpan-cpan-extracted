
# purpose: tests Mnet::Expect::Cli command method functionality

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 7;

# init perl code for these tests
my $perl = <<'perl-eof';
    use warnings;
    use strict;
    use Mnet::Expect::Cli;
    use Mnet::Log qw( DEBUG INFO );
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    my $opts = Mnet::Opts::Cli->new;
    DEBUG("spawn script: $_") foreach (split/\n/, `cat $ENV{EXPECT} 2>&1`);
    my $expect = Mnet::Expect::Cli->new({
        paging_key  => "\n",
        paging_re   => "MORE(\\r?\\n)",
        spawn       => $ENV{EXPECT},
        timeout     => 2,
    });
perl-eof

# command method call
Mnet::T::test_perl({
    name    => 'command method call',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            echo -n prompt%;   read INPUT
            echo -n prompt%;   read INPUT
            echo output
            echo -n prompt%;   read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test") . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "output",
    debug   => '--debug',
});

# command method with prompt_re
Mnet::T::test_perl({
    name    => 'command method with prompt_re',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            echo -n prompt%;   read INPUT
            echo -n prompt%;   read INPUT
            echo output
            echo -n prompt%;   read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        $expect->prompt_re("^prompt\%\$");
        print $expect->command("test") . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "output",
    debug   => '--debug',
});

# command method timeout
Mnet::T::test_perl({
    name    => 'command method timeout',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            echo -n prompt%; read INPUT
            echo -n prompt%; read INPUT
            echo output;     read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test") // "<undef>";
        print "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "<undef>",
    debug   => '--debug',
});

# command method timeout handling
Mnet::T::test_perl({
    name    => 'command method timeout handling',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            echo -n prompt%; read INPUT
            echo -n prompt%; read INPUT
            echo output;     read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test", undef, [ "" => undef ]) . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "output",
    debug   => '--debug',
});

# command method with output pagination
Mnet::T::test_perl({
    name    => 'command method with output pagination',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            echo -n prompt%; read INPUT
            echo -n prompt%; read INPUT
            echo output
            echo MORE;       read INPUT
            echo more output
            echo -n prompt%; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test") . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "output\nmore output",
    debug   => '--debug',
});

# command method cached output
Mnet::T::test_perl({
    name    => 'command method cached output',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            echo -n prompt%; read INPUT
            echo -n prompt%; read INPUT
            echo output
            echo -n prompt%; read INPUT
            echo uncached output
            echo -n prompt%; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test") . "\n";
        print $expect->command("test") . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "output\noutput",
    debug   => '--debug',
});

# command cache clear method
Mnet::T::test_perl({
    name    => 'command cache clear method',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            echo -n prompt%; read INPUT
            echo -n prompt%; read INPUT
            echo output
            echo -n prompt%; read INPUT
            echo uncached output
            echo -n prompt%; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test") . "\n";
        $expect->command_cache_clear;
        print $expect->command("test") . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "output\nuncached output",
    debug   => '--debug',
});

# finished
exit;
