
# purpose: tests Mnet::Log debug

# required modules
use warnings;
use strict;
use Test::More tests => 4;

# use current perl for tests
my $perl = $^X;

# check that debug is disabled by default
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log qw( DEBUG );
    use Mnet::Log::Test;
    Mnet::Log->new->debug("debug method");
    DEBUG("debug function");
' -- 2>&1`, '--- - Mnet::Log -e started
--- - Mnet::Log finished with no errors
', 'debug default disabled');

# check Mnet::Log->new debug object option
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log qw( DEBUG );
    use Mnet::Log::Test;
    Mnet::Log->new({ debug => 1 })->debug("debug method");
    DEBUG("debug function");
' -- 2>&1 | grep '^dbg - main'`, 'dbg - main debug method
', 'debug object option');

# check Mnet::Opts::Set::Debug pragma option
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log qw( DEBUG );
    use Mnet::Log::Test;
    use Mnet::Opts::Set::Debug;
    Mnet::Log->new->debug("debug method");
    DEBUG("debug function");
' -- 2>&1 | grep '^dbg - main'`, 'dbg - main debug method
dbg - main debug function
', 'debug pragma option');

# check --debug cli option
Test::More::is(`$perl -e '
    use warnings;
    use strict;
    use Mnet::Log qw( DEBUG );
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    Mnet::Opts::Cli->new;
    Mnet::Log->new->debug("debug method");
    DEBUG("debug function");
' -- --debug 2>&1 | grep '^dbg - main'`, 'dbg - main debug method
dbg - main debug function
', 'debug cli option');

# finished
exit;

