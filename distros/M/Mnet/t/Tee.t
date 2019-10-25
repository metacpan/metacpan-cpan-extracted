
# purpose: tests Mnet::Tee

# required modules
use warnings;
use strict;
use File::Temp;
use Test::More tests => 3;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# use current perl for tests
my $perl = $^X;

# check all Mnet::Tee function calls, creating an output Mnet::Tee::file
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
Test::More::is(`echo; echo SCRIPT; $perl -e '
    use warnings;
    use strict;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    use Mnet::Tee qw( \$stdout \$stderr );
    syswrite \$stdout, "Mnet::Tee::stdout\n";
    syswrite \$stderr, "Mnet::Tee::stderr\n";
    syswrite STDOUT, "stdout1\n";
    syswrite STDERR, "stderr1\n";
    die if Mnet::Tee::test_outputs() !~ /stdout1/;
    die if Mnet::Tee::test_outputs() !~ /stderr1/;
    Mnet::Tee::file("$file");
    syswrite STDOUT, "stdout2\n";
    syswrite STDERR, "stderr2\n";
    die if Mnet::Tee::test_outputs() !~ /stdout2/;
    die if Mnet::Tee::test_outputs() !~ /stderr2/;
    Mnet::Tee::test_pause();
    die if not Mnet::Tee::test_paused();
    syswrite STDOUT, "stdout3\n";
    syswrite STDERR, "stderr3\n";
    die if Mnet::Tee::test_outputs() =~ /stdout3/;
    die if Mnet::Tee::test_outputs() =~ /stderr3/;
    Mnet::Tee::test_unpause();
    syswrite STDOUT, "stdout4\n";
    syswrite STDERR, "stderr4\n";
    die if Mnet::Tee::test_outputs() !~ /stdout4/;
    die if Mnet::Tee::test_outputs() !~ /stderr4/;
' -- 2>&1; echo FILE; cat "$file"`, '
SCRIPT
Mnet::Tee::stdout
Mnet::Tee::stderr
stdout1
stderr1
stdout2
stderr2
stdout3
stderr3
stdout4
stderr4
FILE
stdout1
stderr1
stdout2
stderr2
stdout3
stderr3
stdout4
stderr4
', 'tee to file using all function calls');

# tee to a file using the cli --tee option
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
Test::More::is(`echo; echo SCRIPT; $perl -e '
    use warnings;
    use strict;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    use Mnet::Opts::Cli;
    use Mnet::Tee;
    Mnet::Opts::Cli->new;
    syswrite STDOUT, "stdout\n";
    syswrite STDERR, "stderr\n";
' -- --tee "$file" 2>&1; echo FILE; cat "$file"`, '
SCRIPT
stdout
stderr
FILE
stdout
stderr
', 'tee to file using --tee cli option');

# tee to a file with log --silent option
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
Test::More::is(`echo; echo SCRIPT; $perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    # use Mnet::Opts::Set::Debug;
    use Mnet::Tee;
    Mnet::Opts::Cli->new;
    syswrite STDOUT, "stdout\n";
    syswrite STDERR, "stderr\n";
' -- --silent --tee "$file" 2>&1; echo FILE; cat "$file" | grep -v 'tee ='`, '
SCRIPT
FILE
 -  - Mnet::Log -e started
inf - Mnet::Opts::Cli new parsed opt cli silent = 1
stdout
stderr
 -  - Mnet::Log finished with no errors
', 'tee to file with log --silent option');

# finished
exit;

