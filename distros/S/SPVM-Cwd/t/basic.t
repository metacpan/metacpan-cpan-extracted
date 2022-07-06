use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Cwd';

use Cwd 'getcwd';

# getcwd
{
  my $cur_dir = getcwd;
  is(SPVM::TestCase::Cwd->getcwd_value, $cur_dir);
}

done_testing;
