
# purpose: tests Mnet::Report::Table weith Mnet::Batch

# required modules
use warnings;
use strict;
use Test::More tests => 2;

# use current perl for tests
my $perl = $^X;

# check batch fork error
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
Test::More::is(`echo; echo "batch" | $perl -e '
    use warnings;
    use strict;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    use Mnet::Batch;
    use Mnet::Report::Table;
    my \$cli = Mnet::Batch::fork({});
    exit if not \$cli;
    Mnet::Report::Table->new({ table => "test" });
' 2>&1 -- --nosilent | sed 's/ at -e line .*//' `, '
new Mnet::Report::Table must be created before Mnet::Batch::fork
', 'batch fork error');

# check batch csv output
#   for debug uncomment the use Mnet::Opts::Set::Debug line below
Test::More::is(`echo; ( echo 1; echo 2 ) | $perl -e '
    use warnings;
    use strict;
    # use Mnet::Log; use Mnet::Opts::Set::Debug;
    use Mnet::Batch;
    use Mnet::Report::Table;
    use Mnet::Test;
    our \$table = Mnet::Report::Table->new({
        table   => "test",
        columns => [ data => "string", error => "error" ],
        output  => "csv:/dev/stdout",
    });
    my \$line = Mnet::Batch::fork({ batch => "/dev/stdin" });
    exit if not defined \$line;
    \$table->row({ data => "child" });
' 2>&1`, '
"data","error"
"child",""
"child",""
', 'batch csv output');

# finished
exit;
