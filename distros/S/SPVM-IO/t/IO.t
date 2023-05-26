use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build" };

use SPVM 'Fn';
use SPVM::IO;
use SPVM 'IO';

# Version
{
  is($SPVM::IO::VERSION, SPVM::Fn->get_version_string('IO'));
}

done_testing;
