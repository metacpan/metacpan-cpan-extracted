
# purpose: tests Mnet::Expect::Cli::Ios functionality

# required modules
#   Expect required in Mnet::Expect modules, best to find our here if missing
use warnings;
use strict;
use File::Temp;
use Test::More tests => 8;

# use current perl for tests
my $perl = $^X;



#
# check enable method
#

# init perl code used for enable and method tests
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
my $perl_command_setup = '
    use warnings;
    use strict;
    use Mnet::Expect::Cli::Ios;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    my $expect = Mnet::Expect::Cli::Ios->new({
        enable_user => "test",
        spawn       => $ENV{CLI},
        timeout     => 2,
    });
';

# check enable when already in enable
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt# \"; read INPUT
    echo -n \"prompt# \"; read INPUT
    echo -n \"prompt# \"; read INPUT
' >\$CLI; chmod 700 \$CLI; $perl -e '
    $perl_command_setup
    print \$expect->enable("test") // "<undef>";
' 2>&1; rm \$CLI`, '1', 'enable when already in enable');

# check enable with no prompts
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt> \"; read INPUT
    echo -n \"prompt> \"; read INPUT
    echo -n \"prompt# \"; read INPUT
' >\$CLI; chmod 700 \$CLI; $perl -e '
    $perl_command_setup
    print \$expect->enable("test") // "<undef>";
' 2>&1; rm \$CLI`, '1', 'enable with no prompts');

# check enable with password prompt
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt> \"; read INPUT
    echo -n \"prompt> \"; read INPUT
    echo -n \"password: \"; read INPUT
    echo -n \"prompt# \"; read INPUT
' >\$CLI; chmod 700 \$CLI; $perl -e '
    $perl_command_setup
    print \$expect->enable("test") // "<undef>";
' 2>&1; rm \$CLI`, '1', 'enable with password prompt');

# check enable with username and password prompts
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt> \"; read INPUT
    echo -n \"prompt> \"; read INPUT
    echo -n \"username: \"; read INPUT
    echo -n \"password: \"; read INPUT
    echo -n \"prompt# \"; read INPUT
' >\$CLI; chmod 700 \$CLI; $perl -e '
    $perl_command_setup
    print \$expect->enable("test") // "<undef>";
' 2>&1; rm \$CLI`, '1', 'enable with username and password prompts');

# check enable failed
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt> \"; read INPUT
    echo -n \"prompt> \"; read INPUT
    echo -n \"password: \"; read INPUT
    echo -n \"password: \"; read INPUT
    echo -n \"password: \"; read INPUT
    echo -n \"% Bad enable passwords, too many failures!\"
    echo -n \"prompt> \"; read INPUT
' >\$CLI; chmod 700 \$CLI; $perl -e '
    $perl_command_setup
    print \$expect->enable("test") // "<undef>";
' 2>&1; rm \$CLI`, '0', 'enable failed');



#
# check record and replay of enable method
#

# create temp record/replay/test file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# init perl code used for command record and replay tests
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
my $perl_record_replay = '
    use warnings;
    use strict;
    use Mnet::Test;
    use Mnet::Expect::Cli::Ios;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    my $opts = Mnet::Opts::Cli->new();
    $opts->{spawn} = $ENV{CLI} if $ENV{CLI};
    my $expect = Mnet::Expect::Cli::Ios->new($opts);
';

# enable method --record
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt> \"; read INPUT
    echo -n \"prompt> \"; read INPUT
    echo -n \"prompt# \"; read INPUT
' >\$CLI; chmod 700 \$CLI; $perl -e '
    $perl_record_replay
    print \$expect->enable("test") // "<undef>";
' -- --record $file 2>&1; rm \$CLI`, '1', 'enable method --record');

# enable method --replay
Test::More::is(`$perl -e '
    $perl_record_replay
    print \$expect->enable("test") // "<undef>";
' -- --replay $file 2>&1`, '1', 'enable method --replay');



#
# check close method and changing prompt
#

# check close method and changing prompt
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n \"prompt# \"; read INPUT
    echo -n \"prompt# \"; read INPUT
    echo -n \"prompt> \"; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Expect::Cli::Ios;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    my \$expect = Mnet::Expect::Cli::Ios->new({
        spawn       => \$ENV{CLI},
        timeout     => 2,
    });
    \$expect->close;
' 2>&1 | grep '_command_expect matched'; rm \$CLI`, '
dbg - Mnet::Expect::Cli _command_expect matched prompt_re
dbg - Mnet::Expect::Cli _command_expect matched prompts null for timeout
', 'close and changing prompt');



# finished
exit;
