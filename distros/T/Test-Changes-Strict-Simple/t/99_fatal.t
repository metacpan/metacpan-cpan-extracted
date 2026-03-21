use strict;
use warnings;

use Test::More;
#use Test::Builder::Tester;

use Test::Exception;

use Test::Changes::Strict::Simple;

# use FindBin;
# use lib "$FindBin::Bin/lib";

# use File::Temp qw(tempdir);
# use Local::Test::Helper qw(:all);

throws_ok { changes_strict_ok(module_version => undef) } qr/\bmodule_version is undef\b/;

# -------------------------------------------------------------------------------------------------

done_testing;

