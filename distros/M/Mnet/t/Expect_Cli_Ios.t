
# purpose: tests Mnet::Expect::Cli::Ios functionality

# required modules
use warnings;
use strict;
use File::Temp;
use Mnet::T;
use Test::More tests => 9;

# init perl code for these tests
my $perl = <<'perl-eof';
    use warnings;
    use strict;
    use Mnet::Expect::Cli::Ios;
    use Mnet::Log qw( DEBUG INFO );
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Set::Quiet;
    use Mnet::Test;
    Mnet::Opts::Cli::define({ getopt => "config" });
    Mnet::Opts::Cli::define({ getopt => "enable:s" });
    Mnet::Opts::Cli::define({ getopt => "enable-user:s" });
    my $opts = Mnet::Opts::Cli->new;
    $opts->{spawn} = $ENV{EXPECT};
    $opts->{timeout} = 2;
    DEBUG("spawn script: $_") foreach (split/\n/, `cat $ENV{EXPECT} 2>&1`);
    my $expect = Mnet::Expect::Cli::Ios->new($opts) or die "expect undef";
    if ($opts->{record} or $opts->{replay}) {
        my $output = $expect->command("test");
        INFO("output = $_") foreach split(/\n/, $output);
    } elsif ($opts->{config}) {
        $expect->command("configure terminal");
        $expect->command("interface Loopback0");
        $expect->command("exit");
        $expect->command("exit");
    }
    $expect->close;
perl-eof

# prompt truncate
Mnet::T::test_perl({
    name    => 'prompt truncate',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt> "; read INPUT
            printf "prompt> "; read INPUT
            printf "prompt> "; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--noquiet --debug',
    filter  => 'grep -e "Cli prompt_re set" -e "Log fin"',
    expect  => <<'    expect-eof',
        dbg - Mnet::Expect::Cli prompt_re set = (^|\r|\n)promp\S+> \r?$
        dbg - Mnet::Expect::Cli prompt_re set = (^|\r|\n)promp\S+(>|#) \r?$
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# enable when already in enable
Mnet::T::test_perl({
    name    => 'enable when already in enable',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt# "; read INPUT
            printf "prompt# "; read INPUT
            printf "prompt# "; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--noquiet --debug --enable',
    filter  => 'grep -e "Ios enable" -e "Log fin"',
    expect  => <<'    expect-eof',
        dbg - Mnet::Expect::Cli::Ios enable starting
        dbg - Mnet::Expect::Cli::Ios enable finished, returning true
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# enable with no prompts
Mnet::T::test_perl({
    name    => 'enable with no prompts',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt> "; read INPUT
            printf "prompt> "; read INPUT
            printf "prompt# "; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--noquiet --debug --enable',
    filter  => 'grep -e "Ios enable" -e "Log fin"',
    expect  => <<'    expect-eof',
        dbg - Mnet::Expect::Cli::Ios enable starting
        dbg - Mnet::Expect::Cli::Ios enable finished, returning true
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# enable with password prompt
Mnet::T::test_perl({
    name    => 'enable with password prompt',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt> ";   read INPUT
            printf "prompt> ";   read INPUT
            printf "password: "; read INPUT
            printf "prompt# ";   read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--noquiet --debug --enable pass',
    filter  => 'grep -e "Ios enable" -e "Log fin"',
    expect  => <<'    expect-eof',
        dbg - Mnet::Expect::Cli::Ios enable starting
        dbg - Mnet::Expect::Cli::Ios enable sending enable password
        dbg - Mnet::Expect::Cli::Ios enable finished, returning true
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# enable with username and password prompts
Mnet::T::test_perl({
    name    => 'enable with username and password prompts',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt> ";   read INPUT
            printf "prompt> ";   read INPUT
            printf "username: "; read INPUT
            printf "password: "; read INPUT
            printf "prompt# ";   read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--noquiet --debug --enable pass --enable-user test',
    filter  => 'grep -e "Ios enable" -e "Log fin"',
    expect  => <<'    expect-eof',
        dbg - Mnet::Expect::Cli::Ios enable starting
        dbg - Mnet::Expect::Cli::Ios enable sending enable_user
        dbg - Mnet::Expect::Cli::Ios enable sending enable password
        dbg - Mnet::Expect::Cli::Ios enable finished, returning true
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# enable failed
Mnet::T::test_perl({
    name    => 'enable failed',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt> ";   read INPUT
            printf "prompt> ";   read INPUT
            printf "password: "; read INPUT
            printf "password: "; read INPUT
            printf "password: "; read INPUT
            printf "%% Bad enable passwords, too many failures!"
            printf "prompt> ";   read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--noquiet --debug --enable',
    filter  => 'grep -e "Ios enable" -e "Log fin"',
    expect  => <<'    expect-eof',
        dbg - Mnet::Expect::Cli::Ios enable starting
        dbg - Mnet::Expect::Cli::Ios enable sending enable password
        dbg - Mnet::Expect::Cli::Ios enable sending enable password
        dbg - Mnet::Expect::Cli::Ios enable sending enable password
        dbg - Mnet::Expect::Cli::Ios enable finished, returning false
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# close with changing prompt
Mnet::T::test_perl({
    name    => 'close with changing prompt',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt# "; read INPUT
            printf "prompt# "; read INPUT
            printf "prompt> "; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--debug --noquiet',
    post    => 'rm $EXPECT',
    filter  => 'grep -e "Ios close" -e "_command_expect matched" -e "Log fin"',
    expect  => <<'    expect-eof',
        dbg - Mnet::Expect::Cli::Ios close starting
        dbg - Mnet::Expect::Cli _command_expect matched prompt_re
        dbg - Mnet::Expect::Cli _command_expect matched prompts (null=timeout)
        dbg - Mnet::Expect::Cli::Ios close finished
        --- - Mnet::Log finished, no errors
    expect-eof
});

# create temp directory for record and replay tests, below
#   portable temp dir, as per  http://cpanwiki.grango.org/wiki/CPANAuthorNotes
my ($temp_dir) = File::Temp::newdir(
    "tmp.XXXX", CLEANUP => 1, EXLOCK => 0, TMPDIR => 1
);

# enable mode --record
Mnet::T::test_perl({
    name    => 'enable method --record',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt> "; read INPUT
            printf "prompt> "; read INPUT
            printf "prompt# "; read INPUT
            echo "output";
            printf "prompt# "; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => "--noquiet --record $temp_dir/file.test --enable",
    post    => 'rm $EXPECT',
    filter  => 'grep -e ^inf -e "Mnet::Log finished"',
    expect  => <<'    expect-eof',
        inf - main output = output
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# enable mode --replay
Mnet::T::test_perl({
    name    => 'enable method --replay',
    pre     => 'export EXPECT="dummy_spawn_not_needed"',
    perl    => $perl,
    args    => "--noquiet --replay $temp_dir/file.test --enable",
    filter  => 'grep -e ^inf -e "Mnet::Log finished"',
    expect  => <<'    expect-eof',
        inf - main output = output
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# finished
exit;

