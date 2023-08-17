
# purpose: tests Mnet::Expect::Cli functionality

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 8;

# init perl code for these tests
my $perl = <<'perl-eof';
    use warnings;
    use strict;
    use Mnet::Expect::Cli;
    use Mnet::Log qw( DEBUG );
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Set::Quiet;
    Mnet::Opts::Cli::define({ getopt => "username=s" });
    Mnet::Opts::Cli::define({ getopt => "password=s" });
    Mnet::Opts::Cli::define({ getopt => "prompt-re-undef" });
    Mnet::Opts::Cli::define({ getopt => "log-login=s" });
    my $opts = Mnet::Opts::Cli->new;
    $opts->{spawn} = $ENV{EXPECT};
    $opts->{failed_re} = "fail";
    $opts->{timeout} = 2;
    $opts->{prompt_re} = undef if $opts->{prompt_re_undef};
    DEBUG("spawn script: $_") foreach (split/\n/, `cat $ENV{EXPECT} 2>&1`);
    my $expect = Mnet::Expect::Cli->new($opts) or die "expect undef";
    my $prompt = $expect->prompt_re;
    syswrite STDOUT, "prompt = $prompt\n" if $prompt;
    $expect->command("test") if $opts->{log_login};
    $expect->close;
perl-eof

# new login with username, no password, prompt%
Mnet::T::test_perl({
    name    => 'new login with username, no password, prompt%',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "username: "; read INPUT
            printf "prompt%% ";   read INPUT
            printf "prompt%% ";   read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--username user',
    post    => 'rm $EXPECT',
    expect  => 'prompt = (^|\r|\n)prompt% \r?$'."\n",
    debug   => '--debug --noquiet',
});

# new login with passcode, no username, prompt#
Mnet::T::test_perl({
    name    => 'new login with passcode, no username, prompt#',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "passcode: "; read INPUT
            printf "prompt# ";   read INPUT
            printf "prompt# ";   read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--password pass',
    post    => 'rm $EXPECT',
    expect  => 'prompt = (^|\r|\n)prompt# \r?$'."\n",
    debug   => '--debug --noquiet',
});

# new login with no username, no password and prompt:
Mnet::T::test_perl({
    name    => 'new login with no username, no password and prompt:',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt: "; read INPUT
            printf "prompt: "; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    post    => 'rm $EXPECT',
    expect  => 'prompt = (^|\r|\n)prompt: \r?$'."\n",
    debug   => '--debug --noquiet',
});

# new login failed before username prompt
Mnet::T::test_perl({
    name    => 'new login failed before username prompt',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "fail"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--username user --password pass',
    post    => 'rm $EXPECT',
    expect  => 'DIE - Mnet::Expect::Cli login failed_re matched "fail"'."\n",
    debug   => '--debug --noquiet',
});

# new login failed after login prompt
Mnet::T::test_perl({
    name    => 'new login failed after login prompt',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "login: "; read INPUT
            printf "fail";    read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--username user --password pass',
    post    => 'rm $EXPECT',
    expect  => 'DIE - Mnet::Expect::Cli login failed_re matched "fail"'."\n",
    debug   => '--debug --noquiet',
});

# new login failed after password prompt
Mnet::T::test_perl({
    name    => 'new login failed after password prompt',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "username: "; read INPUT
            printf "password: "; read INPUT
            printf "fail";       read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--username user --password pass',
    post    => 'rm $EXPECT',
    expect  => 'DIE - Mnet::Expect::Cli login failed_re matched "fail"'."\n",
    debug   => '--debug --noquiet',
});

# new login with no user, password, or prompt
Mnet::T::test_perl({
    name    => 'new login with no user, password, or prompt',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--prompt-re-undef',
    post    => 'rm $EXPECT',
    expect  => "\n",
    debug   => '--debug --noquiet',
});

# check log_login info
#   note that prompt$ log txt lines in output have a space at the end
Mnet::T::test_perl({
    name    => 'check log_login info',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt\$ "; read INPUT
            printf "prompt\$ "; read INPUT
            printf "prompt\$ "; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl,
    args    => '--noquiet --debug --log-login info',
    post    => 'rm $EXPECT',
    filter  => <<'    filter-eof',
        grep -e "Mnet::Log fin" -e ^inf -e "log txt: test" \
        | grep -v Mnet::Opts::Cli
    filter-eof
    expect  => '
        inf - Mnet::Expect log txt: prompt$'.' '.'
        inf - Mnet::Expect log txt: prompt$'.' '.'
        dbg - Mnet::Expect log txt: test
        --- - Mnet::Log finished, no errors
    ',
    debug   => '--debug --noquiet',
});

# new login with spurious prompt, no trailing spaces prompt>
#? try enabling prompt-detect test after everything else works
#Mnet::T::test_perl({
#    name    => 'new login with spurious prompt, no trailing spaces prompt>',
#    pre     => <<'    pre-eof',
#        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
#            echo "prompt:"
#            printf "prompt>"; read INPUT
#            printf "prompt>"; read INPUT
#            printf "prompt>"; read INPUT
#        ' >$EXPECT
#    pre-eof
#    perl    => $perl,
#    args    => '',
#    post    => 'rm $EXPECT',
#    expect  => 'prompt = (^|\r|\n)prompt>\r?$',
#    debug   => '--debug --noquiet',
#});

# new login skipped pre-login banner failed_re text
#   example: failed_re /refused/, banner "unauthorized access refused"
#   this would be an enhancement, current code can't handle this situation
#   fix is no default failed_re, perldoc says set failed_re or timeout on fails
#   refer to to-do noted in git commit 65d08eb Mnet::Expect::Cli for ideas
#Mnet::T::test_perl({
#    name    => 'new login skipped pre-login banner failed_re text',
#    pre     => <<'    pre-eof',
#        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
#            echo "banner start"; echo "not failed"; echo "banner end"
#            printf "username: "; read INPUT
#            printf "password: "; read INPUT
#            printf "prompt%% ";   read INPUT
#            printf "prompt%% ";   read INPUT
#        ' >$EXPECT
#    pre-eof
#    perl    => $perl,
#    args    => '--username user --password pass',
#    post    => 'rm $EXPECT',
#    expect  => 'prompt = (^|\r|\n)prompt% \r?$',
#    debug   => '--debug --noquiet',
#});

# new login skipped post-login banner failed_re text (enhancement)
#   example: failed_re /refused/, banner "unauthorized access refused"
#   this would be an enhancement, current code can't handle this situation
#   fix is no default failed_re, timeouts on fails, perldoc says set failed_re
#   refer to to-do not in git commit 65d08eb Mnet::Expect::Cli for ideas
#Mnet::T::test_perl({
#    name    => 'new login skipped post-login banner failed_re text',
#    pre     => <<'    pre-eof',
#        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
#            printf "username: "; read INPUT
#            printf "password: "; read INPUT
#            echo "banner start"; echo "not failed"; echo "banner end"
#            printf "prompt%% ";   read INPUT
#            printf "prompt%% ";   read INPUT
#        ' >$EXPECT
#    pre-eof
#    perl    => $perl,
#    args    => '--username user --password pass',
#    post    => 'rm $EXPECT',
#    expect  => 'prompt = (^|\r|\n)prompt% \r?$',
#    debug   => '--debug --noquiet',
#});

# new login autodetects that username is not needed
#   this would be an enhancement, current code can't handle this situation
#   workaround as per perldoc says to set username only if it will be needed
#   refer to to-do not in git commit 65d08eb Mnet::Expect::Cli for ideas
#Mnet::T::test_perl({
#    name    => 'new login autodetects that username is not needed',
#    pre     => <<'    pre-eof',
#        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
#            printf "password: "; read INPUT
#            printf "prompt%% ";   read INPUT
#            printf "prompt%% ";   read INPUT
#        ' >$EXPECT
#    pre-eof
#    perl    => $perl,
#    args    => '--username user --password pass',
#    post    => 'rm $EXPECT',
#    expect  => 'prompt = (^|\r|\n)prompt% \r?$',
#    debug   => '--debug --noquiet',
#});

# new login autodetects that username and password not needed
#   this would be an enhancement, current code can't handle this situation
#   workaround as per perldoc says to set username and passwords only if needed
#   refer to to-do not in git commit 65d08eb Mnet::Expect::Cli for ideas
#Mnet::T::test_perl({
#    name    => 'new login autodetects that username and password not needed',
#    pre     => <<'    pre-eof',
#        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
#            printf "prompt%% ";   read INPUT
#            printf "prompt%% ";   read INPUT
#        ' >$EXPECT
#    pre-eof
#    perl    => $perl,
#    args    => '--username user --password pass',
#    post    => 'rm $EXPECT',
#    expect  => 'prompt = (^|\r|\n)prompt% \r?$',
#    debug   => '--debug --noquiet',
#});

# finished
exit;

