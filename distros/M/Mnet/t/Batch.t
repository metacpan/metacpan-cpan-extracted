
# purpose: tests Mnet::Batch

# required modules
use warnings;
use strict;
use File::Temp;
use Test::More tests => 3;

# use current perl for tests
my $perl = $^X;

# batch without mnet cli
Test::More::is(`( echo child1; echo child2 child3 ) | $perl -e '
    use warnings;
    use strict;
    use Mnet::Batch;
    my \$line = Mnet::Batch::fork({ batch => "/dev/stdin" });
    exit if not defined \$line;
    syswrite STDOUT, "line = \$line\n";
' -- parent 2>&1`, 'line = child1
line = child2 child3
', 'batch without mnet cli');

# batch with mnet cli and extras
Test::More::is(`( echo --opt1 1 --opt2 1; echo --opt1 2 ) | $perl -e '
    use warnings;
    use strict;
    use Mnet::Batch;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt1=i", recordable  => 1 });
    Mnet::Opts::Cli::define({ getopt => "opt2=i", recordable  => 1 });
    my \$cli = Mnet::Opts::Cli->new;
    \$cli = Mnet::Batch::fork(\$cli);
    exit if not \$cli;
    syswrite STDOUT, "opt1 = \$cli->{opt1}, opt2 = \$cli->{opt2}\n";
' -- --batch /dev/stdin --opt1 3 --opt2 3 2>&1`, 'opt1 = 1, opt2 = 1
opt1 = 2, opt2 = 3
', 'batch with mnet cli');

# batch with mnet cli and extras
Test::More::is(`( echo --opt 1 child; echo --opt 2 ) | $perl -e '
    use warnings;
    use strict;
    use Mnet::Batch;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "opt=i", recordable  => 1 });
    my (\$cli, \@extras) = Mnet::Opts::Cli->new;
    (\$cli, \@extras) = Mnet::Batch::fork(\$cli);
    exit if not defined \$cli;
    syswrite STDOUT, "opt = \$cli->{opt}\n" if \$cli->{opt};
    syswrite STDOUT, "extras = \@extras\n" if \@extras;
' -- --batch /dev/stdin parent 2>&1`, 'opt = 1
extras = parent child
opt = 2
extras = parent
', 'batch with mnet cli and extras');

# finished
exit;

