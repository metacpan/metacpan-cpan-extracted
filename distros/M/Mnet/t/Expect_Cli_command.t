
# purpose: tests Mnet::Expect::Cli command method functionality

# required modules
#   Expect required in Mnet::Expect modules, best to find our here if missing
use warnings;
use strict;
use Expect;
use Test::More tests => 12;

# use current perl for tests
my $perl = $^X;

# init perl code used for command method tests
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
my $perl_command_setup = '
    use warnings;
    use strict;
    use Mnet::Expect::Cli;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    my $expect = Mnet::Expect::Cli->new({
        paging_key  => "\n",
        paging_re   => "MORE(\\r?\\n)",
        spawn       => $ENV{CLI},
        timeout     => 2,
    });
';

# check basic command method call
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test") // "<undef>";
' 2>&1; echo; rm \$CLI`, '
output
', 'command method command');

# check command method timeout
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo output; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test") // "<undef>";
' 2>&1; echo; rm \$CLI`, '
<undef>
', 'command method timeout');

# check command method timeout handling
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo output; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test", undef, [ "" => undef ]) // "<undef>";
' 2>&1; echo; rm \$CLI`, '
output
', 'command method timeout handling');

# check command method prompt response text
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo -n question; read INPUT
    echo output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test", undef, [ question => "-\\r" ]) // "<undef>";
' 2>&1; echo; rm \$CLI`, '
question-
output
', 'command method prompt response text');

# check command method prompt response undef
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo -n question; read INPUT
    echo output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test", undef, [ question => undef ]) // "<undef>";
' 2>&1; echo; rm \$CLI`, '
question
', 'command method prompt response undef');

# check command method prompt code response text
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo preamble
    echo -n question; read INPUT
    echo output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test", undef, [ question => sub {
        shift; return "-\\r" if shift =~ /preamble/;
    }]) // "<undef>";
' 2>&1; echo; rm \$CLI`, '
preamble
question-
output
', 'command method prompt code response text');

# check command method prompt code response undef
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo preamble
    echo -n question; read INPUT
    echo output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test", undef, [ question => sub {
        shift; return undef if shift =~ /preamble/;
    }]) // "<undef>";
' 2>&1; echo; rm \$CLI`, '
preamble
question
', 'command method prompt code response undef');

# check command method output with extra prompt
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo prompt%
    echo output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test") // "<undef>";
' 2>&1; echo; rm \$CLI`, '
prompt%
output
', 'command method output with extra prompt');

# check command method with multiple prompts
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo -n one; read INPUT
    echo -n two; read INPUT
    echo output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test", undef,
        [ one => "1\\r", two => "2\\r" ]) // "<undef>";
' 2>&1; echo; rm \$CLI`, '
one1
two2
output
', 'command method with multiple prompts');

# check basic command method call with output pagination
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo output
    echo MORE; read INPUT
    echo more output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test") // "<undef>";
' 2>&1; echo; rm \$CLI`, '
output
more output
', 'command method with output pagination');

# check command method cached output
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo output
    echo -n prompt%; read INPUT
    echo uncached output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test") // "<undef>";
    print "\\n";
    print \$expect->command("test") // "<undef>";
' 2>&1; echo; rm \$CLI`, '
output
output
', 'command method cached output');

# check command method cached output
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo output
    echo -n prompt%; read INPUT
    echo uncached output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_command_setup
    print \$expect->command("test") // "<undef>";
    print "\\n";
    \$expect->command_cache_clear;
    print \$expect->command("test") // "<undef>";
' 2>&1; echo; rm \$CLI`, '
output
uncached output
', 'command cache clear method');

# finished
exit;
