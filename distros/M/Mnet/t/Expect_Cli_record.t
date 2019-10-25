
# purpose: tests Mnet::Expect::Cli record and replay functionality

# required modules
#   Expect required in Mnet::Expect modules, best to find our here if missing
use warnings;
use strict;
use Expect;
use File::Temp;
use Test::More tests => 4;

# create temp record/replay/test file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# use current perl for tests
my $perl = $^X;

# init perl code used for command record and replay tests
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
my $perl_record_replay = '
    use warnings;
    use strict;
    use Mnet::Test;
    use Mnet::Expect::Cli;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    my $opts = Mnet::Opts::Cli->new();
    $opts->{spawn} = $ENV{CLI} if $ENV{CLI};
    my $expect = Mnet::Expect::Cli->new($opts);
';

# command method record
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo output
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_record_replay
    print \$expect->command("test") // "<undef>";
' -- --record $file 2>&1; echo; rm \$CLI`, '
output
', 'command method --record');

# command method replay
Test::More::is(`echo; $perl -e '
    $perl_record_replay
    print \$expect->command("test") // "<undef>";
' -- --replay $file 2>&1; echo`, '
output
', 'command method --replay');

# command method record with cache clear
Test::More::is(`export CLI=\$(mktemp); echo '
    echo -n prompt%; read INPUT
    echo -n prompt%; read INPUT
    echo output one
    echo -n prompt%; read INPUT
    echo output two
    echo -n prompt%; read INPUT
' >\$CLI; chmod 700 \$CLI; echo; $perl -e '
    $perl_record_replay
    print \$expect->command("test") // "<undef>";
    print "\\n";
    \$expect->command_cache_clear;
    print \$expect->command("test") // "<undef>";
' -- --record $file 2>&1; echo; rm \$CLI`, '
output one
output two
', 'command method --record with cache clear');

# command method replay with cache clear
Test::More::is(`echo; $perl -e '
    $perl_record_replay
    print \$expect->command("test") // "<undef>";
    print "\\n";
    \$expect->command_cache_clear;
    print \$expect->command("test") // "<undef>";
' -- --replay $file 2>&1; echo`, '
output one
output two
', 'command method --replay with cache clear');

# finished
exit;
