
# purpose: tests Mnet::Opts::Cli

# required modules
use warnings;
use strict;
use Test::More tests => 9;

# use current perl for tests
my $perl = $^X;

# check --version
#   extra sed was needed on openbsd
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli->new;
' -- --version 2>&1 | grep -e Mnet -e 'exec path' | head -n 2 | wc -l | sed 's/^ *//'`, '2
', 'display --version');

# check --help
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli->new;
' -- --help 2>&1 | grep -e Mnet -e '^ *--'`, 'Mnet options:
 --help [s]   display option help, *try --help help
 --version    display version and system information
', 'display --help');

# parse cli opt and check that ARGV doesn't change
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
    my \$cli = Mnet::Opts::Cli->new;
    print \$cli->{test_opt} ."\n";
    print \$cli->test_opt ."\n";
    print "\@ARGV\n";
' -- --test-opt test 2>&1`, 'test
test
--test-opt test
', 'parse cli opt without changing ARGV');

# parse cli opt and extras and check that ARGV doesn't change
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
    my (\$cli, \@extras) = Mnet::Opts::Cli->new;
    print \$cli->{test_opt} ."\n";
    print \$cli->test_opt ."\n";
    print "\@extras\n";
    print "\@ARGV\n";
' -- --test-opt test extra1 extra2 2>&1`, 'test
test
extra1 extra2
--test-opt test extra1 extra2
', 'parse cli opt and extras without changing ARGV');

# check for error when reading invalid extra args
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
    my \$cli = Mnet::Opts::Cli->new;
' -- --test-opt test extra1 extra2 2>&1`, 'invalid or missing args extra1 extra2
', 'invalid or missing args');

# check for error when reading bad cli opt
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    my \$cli = Mnet::Opts::Cli->new;
' -- --test-opt test 2>&1`, 'invalid or missing args --test-opt test
', 'invalid cli opt');

# check --test-reset option for undef default
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
    warn "test-opt" if defined Mnet::Opts::Cli->new->test_opt;
' -- --test-opt test --test-reset test-opt 2>&1`, '', 'undef --test-reset');

# check --test-reset option for defined default
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli::define({ getopt => "test-opt=s", default => "default" });
    warn "test-opt" if Mnet::Opts::Cli->new->test_opt ne "default";
' -- --test-opt test --test-reset test-opt 2>&1`,'','defined --test-reset');

# check logging of options
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "test-opt=s" });
    Mnet::Opts::Cli->new;
' -- --test-opt test 2>&1`, '--- - Mnet::Log -e started
inf - Mnet::Opts::Cli new parsed opt cli test-opt = "test"
--- - Mnet::Log finished with no errors
', 'invalid cli opt');

# finished
exit;

