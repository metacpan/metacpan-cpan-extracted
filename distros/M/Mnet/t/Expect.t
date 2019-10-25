
# purpose: tests Mnet::Expect functionality

# required modules
#   Expect required in Mnet::Expect modules, best to find our here if missing
use warnings;
use strict;
use Expect;
use Test::More tests => 5;

# use current perl for tests
my $perl = $^X;

# check Mnet::Expect spawn error
Test::More::is(`echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Expect;
    use Mnet::Log;
    use Mnet::Log::Test;
    my \$expect = Mnet::Expect->new({ spawn => "uydfhkksl" });
' -- 2>&1 | sed 's/spawn error.*/spawn error/'`, '
 -  - Mnet::Log -e started
DIE - Mnet::Expect spawn error
 -  - Mnet::Log finished with errors
', 'spawn error');

# check Mnet::Expect successful spawn and close
#   some cpan testers needed to grep out expect 'log hex' entries  to pass
#       meybe the session close took effect before last eol received?
Test::More::is(`echo; $perl -e '
    use warnings;
    use strict;
    use Mnet::Expect;
    use Mnet::Log;
    use Mnet::Log::Test;
    my \$expect = Mnet::Expect->new({
        debug   => 1,
        spawn   => "echo x-test"
    });
    die "expect undef" if not defined \$expect;
    \$expect->expect->expect(1, "-re", ".-test");
    \$expect->close;
' -- 2>&1 | grep -e 'Mnet::Log' -e 'log txt' -e 'confirmed'`, '
 -  - Mnet::Log -e started
dbg - Mnet::Expect log txt: x-test
dbg - Mnet::Expect close finished, hard_close confirmed
 -  - Mnet::Log finished with no errors
', 'spawn and close');

# declare script to use for log_expect tests, below
my $perl_expect_test = 'echo; perl -e \'
    use warnings;
    use strict;
    use Mnet::Expect;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli::define({ getopt => "log-expect=s" });
    my $log_expect = Mnet::Opts::Cli->new->log_expect;
    my $expect = Mnet::Expect->new({
        debug       => 1,
        log_expect  => $log_expect,
        spawn       => "echo x-test",
    });
    die "expect undef" if not defined \$expect;
    $expect->expect->expect(1, "-re", ".-test");
    $expect->close;
\' --';

# test log_expect debug
Test::More::is(`$perl_expect_test --log-expect debug 2>&1 \\
    | grep -e 'Mnet::Log' -e 'log txt' -e 'confirmed'`, '
 -  - Mnet::Log -e started
dbg - Mnet::Expect log txt: x-test
dbg - Mnet::Expect close finished, hard_close confirmed
 -  - Mnet::Log finished with no errors
', 'log_expect debug');

# check log_expect info
Test::More::is(`$perl_expect_test --log-expect info 2>&1 \\
    | grep -e 'Mnet::Log' -e '^inf'`, '
 -  - Mnet::Log -e started
inf - Mnet::Opts::Cli new parsed opt cli log-expect = "info"
inf - Mnet::Expect log txt: x-test
 -  - Mnet::Log finished with no errors
', 'log_expect info');

# check log_expect invalid
#   notice level logging is reserved for internal use
Test::More::is(`$perl_expect_test --log-expect notice 2>&1 \\
    | grep ERR | sed 's/invalid.*/invalid/'`, '
ERR - Carp perl die, log_expect invalid
', 'log_expect invalid');


# finished
exit;

