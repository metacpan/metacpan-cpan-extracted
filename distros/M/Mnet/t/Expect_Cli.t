
# purpose: tests Mnet::Expect::Cli functionality

# required modules
#   Expect required in Mnet::Expect modules, best to find our here if missing
use warnings;
use strict;
use Expect;
use Test::More tests => 9;

# use current perl for tests
my $perl = $^X;

# init perl code used for new login tests
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
my $perl_new_login = "chmod 700 \$CLI; echo; $perl -e '" . '
    use warnings;
    use strict;
    use Mnet::Expect::Cli;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    my $opts = { spawn => $ENV{CLI}, timeout => 2, failed_re => "fail" };
    $opts->{username} = "user" if "@ARGV" =~ /user/;
    $opts->{password} = "pass" if "@ARGV" =~ /pass/;
    $opts->{prompt_re} = undef if "@ARGV" =~ /no_prompt_re/;
    my $expect = Mnet::Expect::Cli->new($opts) or die "expect undef";
    syswrite STDOUT, "prompt = ".$expect->prompt_re."\n" if $expect->prompt_re;
    $expect->close;
' . "'";

# check new login with username, no password, prompt%
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"username: \"; read INPUT
    echo -n \"prompt% \"; read INPUT
    echo -n \"prompt% \"; read INPUT
' >\$CLI; $perl_new_login -- user 2>&1; rm \$CLI`, '
prompt = (^|\r|\n)prompt% \r?$
', 'new login with username, no password, prompt%');

# new login with passcode, no username, prompt#
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"passcode: \"; read INPUT
    echo -n \"prompt# \"; read INPUT
    echo -n \"prompt# \"; read INPUT
' >\$CLI; $perl_new_login -- pass 2>&1; rm \$CLI`, '
prompt = (^|\r|\n)prompt# \r?$
', 'new login with passcode, no username, prompt#');

# new login with no username, no password and prompt:
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt: \"; read INPUT
    echo -n \"prompt: \"; read INPUT
' >\$CLI; $perl_new_login 2>&1; rm \$CLI`, '
prompt = (^|\r|\n)prompt: \r?$
', 'new login with no username, no password, prompt:');

# new login failed before username prompt
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"fail\"; read INPUT
' >\$CLI; $perl_new_login user pass 2>&1; rm \$CLI`, '
DIE - Mnet::Expect::Cli login failed_re matched "fail"
', 'new login failed before username prompt');

# new login failed after login prompt
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"login: \"; read INPUT
    echo -n \"fail\"; read INPUT
' >\$CLI; $perl_new_login user pass 2>&1; rm \$CLI`, '
DIE - Mnet::Expect::Cli login failed_re matched "fail"
', 'new login failed after login prompt');

# new login failed after password prompt
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"username: \"; read INPUT
    echo -n \"password: \"; read INPUT
    echo -n \"fail\"; read INPUT
' >\$CLI; $perl_new_login user pass 2>&1; rm \$CLI`, '
DIE - Mnet::Expect::Cli login failed_re matched "fail"
', 'new login failed after password prompt');

# new login with no user, password, or prompt
Test::More::is(`export CLI=\$(mktemp); echo '
' >\$CLI; $perl_new_login no_prompt_re 2>&1; rm \$CLI`, '
', 'new login with no user, password, or prompt');

# check log_login set to info
#   note that prompt$ log txt lines in output have a space at the end
Test::More::is(`
    export CLI=\$(mktemp); echo '
        echo -n \"prompt\$ \"; read INPUT
        echo -n \"prompt\$ \"; read INPUT
        echo -n \"prompt\$ \"; read INPUT
    ' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
        use warnings;
        use strict;
        use Mnet::Expect::Cli;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        my \$opts = { spawn => \$ENV{CLI}, timeout => 2, log_login => "info" };
        my \$expect = Mnet::Expect::Cli->new(\$opts) or die "expect undef";
        \$expect->command("test");
        \$expect->close;
    ' -- 2>&1 | grep -e 'Mnet::Log fin' -e '^inf' -e 'log txt: test';`, '
inf - Mnet::Expect log txt: prompt$'.' '.'
inf - Mnet::Expect log txt: prompt$'.' '.'
dbg - Mnet::Expect log txt: test
 -  - Mnet::Log finished with no errors
', 'check log_login info');

#? temporary code below, to help track down error in some cpan tests
#   only used in test call below, delete this $perl_new_login redef when done
$perl_new_login = "chmod 700 \$CLI; echo; $perl -e '" . '
    use warnings;
    use strict;
    use Mnet::Expect::Cli;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Set::Quiet;
    use Mnet::Log;
    my ($cli, @args) = Mnet::Opts::Cli->new;
    my $opts = { spawn => $ENV{CLI}, timeout => 2, failed_re => "fail" };
    $opts->{username} = "user" if "@ARGV" =~ /user/;
    $opts->{password} = "pass" if "@ARGV" =~ /pass/;
    $opts->{prompt_re} = undef if "@ARGV" =~ /no_prompt_re/;
    my $expect = Mnet::Expect::Cli->new($opts) or die "expect undef";
    syswrite STDOUT, "prompt = ".$expect->prompt_re."\n" if $expect->prompt_re;
    $expect->close;
    my $expected = "(^|\\\r|\\\n)prompt>\\\r?\\$";
    warn "mismatch, $expected" if $expect->prompt_re ne $expected;
' . "' -- --debug-error /dev/stdout";

# new login prompt match with spurrious prompt text in banner
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt:\"'"'"'\\n'"'"'\"prompt>\"; read INPUT
    echo -n \"prompt>\"; read INPUT
    echo -n \"prompt>\"; read INPUT
    echo -n \"prompt>\"; read INPUT
    echo -n \"prompt>\"; read INPUT
' >\$CLI; $perl_new_login 2>&1; rm \$CLI`, '
prompt = (^|\r|\n)prompt>\r?$
', 'new login with extra prompt, no trailing spaces prompt>');

# new login can skip pre-login banner text that matches failed_re
#   example: failed_re /refused/, banner "unauthorized access refused"
#   fix is no default failed_re, perldoc says set failed_re or timeout on fails
#   refer to to-do not in git commit 65d08eb Mnet::Expect::Cli for ideas
#Test::More::is(`export CLI=\$(mktemp); echo '
#    echo \"banner start\"; echo \"not failed\"; echo \"banner end\"
#    echo -n \"username: \"; read INPUT
#    echo -n \"password: \"; read INPUT
#    echo -n \"prompt% \"; read INPUT
#    echo -n \"prompt% \"; read INPUT
#' >\$CLI; $perl_new_login user pass 2>&1; rm \$CLI`, '
#prompt = (^|\r|\n)prompt% \r?$
#', 'new login skipped pre-login banner fail text');

# new login can skip post-login banner text that matches failed_re
#   example: failed_re /refused/, banner "unauthorized access refused"
#   fix is no default failed_re, timeouts on fails, perldoc says set failed_re
#   refer to to-do not in git commit 65d08eb Mnet::Expect::Cli for ideas
#Test::More::is(`export CLI=\$(mktemp); echo '
#    echo -n \"username: \"; read INPUT
#    echo -n \"password: \"; read INPUT
#    echo \"banner start\"; echo \"not failed\"; echo \"banner end\"
#    echo -n \"prompt% \"; read INPUT
#    echo -n \"prompt% \"; read INPUT
#' >\$CLI; $perl_new_login user pass 2>&1; rm \$CLI`, '
#prompt = (^|\r|\n)prompt% \r?$
#', 'new login skipped post-login banner fail text');

# new login autodetects that username is not needed
#   workaround as per perldoc says to set username only if needed
#   refer to to-do not in git commit 65d08eb Mnet::Expect::Cli for ideas
#Test::More::is(`export CLI=\$(mktemp); echo '
#    echo -n \"password: \"; read INPUT
#    echo -n \"prompt% \"; read INPUT
#    echo -n \"prompt% \"; read INPUT
#' >\$CLI; $perl_new_login user pass 2>&1; rm \$CLI`, '
#prompt = (^|\r|\n)prompt% \r?$
#', 'new login username not needed');

# new login autodetects that username and password not both not needed
#   workaround as per perldoc says to set username and passwords only if needed
#   refer to to-do not in git commit 65d08eb Mnet::Expect::Cli for ideas
#Test::More::is(`export CLI=\$(mktemp); echo '
#    echo -n \"password: \"; read INPUT
#    echo -n \"prompt% \"; read INPUT
#    echo -n \"prompt% \"; read INPUT
#' >\$CLI; $perl_new_login user pass 2>&1; rm \$CLI`, '
#prompt = (^|\r|\n)prompt% \r?$
#', 'new login username and passowrd not needed');

# finished
exit;

