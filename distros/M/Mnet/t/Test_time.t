
# purpose: tests Mnet::Test::time function

# required modules
use warnings;
use strict;
use File::Temp;
use Test::More tests => 6;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# use current perl for tests
my $perl = $^X;

# check for real time using no cli opts
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Test;
    warn "fail1" if time + 1 < Mnet::Test::time();
    warn "fail2" if time + 1 < Mnet::Test::time(2);
    warn "fail2" if time + 1 < Mnet::Test::time({});
    warn "fail4" if time + 1 < Mnet::Test::time({}, 4);
' -- 2>&1`, '', 'real time no cli opts');

# check for test time using no cli opts
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Test;
    warn "fail1" if "1" ne Mnet::Test::time({ record => "" });
    warn "fail3" if "3" ne Mnet::Test::time({ record => "file" }, 2);
    warn "fail3" if "6" ne Mnet::Test::time({ replay => "file" }, 3);
    warn "fail4" if "10" ne Mnet::Test::time({ test => 1 }, 4);
' -- 2>&1`, '', 'test time no cli opts');

# check for real time using cli opts
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli->new;
    warn "fail1" if time + 1 < Mnet::Test::time();
    warn "fail2" if time + 1 < Mnet::Test::time(2);
' -- 2>&1`, '', 'real time with cli opts');

# check for test time with --record cli opt
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli->new;
    warn "fail1" if "1" ne Mnet::Test::time();
    warn "fail2" if "3" ne Mnet::Test::time(2);
    warn "fail3" if time + 1 < Mnet::Test::time({});
' -- --record $file 2>&1`, '', 'test time --record cli opts');

# check for test time with --replay cli opt
Test::More::is(`echo '\$Mnet::Test::data = {}' | $perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli->new;
    warn "fail1" if "1" ne Mnet::Test::time();
    warn "fail2" if "3" ne Mnet::Test::time(2);
    warn "fail3" if time + 1 < Mnet::Test::time({});
' -- --replay /dev/stdin 2>&1`, '', 'test time --replay cli opts');

# check for test time with --test cli opt
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli->new;
    warn "fail1" if "1" ne Mnet::Test::time();
    warn "fail2" if "3" ne Mnet::Test::time(2);
    warn "fail3" if time + 1 < Mnet::Test::time({});
' -- --test 2>&1`, '', 'test time --test cli opts');

# finished
exit;

