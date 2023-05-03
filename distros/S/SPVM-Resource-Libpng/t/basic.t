use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Fn';
use SPVM 'Resource::Libpng';
use SPVM::Resource::Libpng;

use SPVM 'MyLibpng';

is(SPVM::MyLibpng->test, 1);

is($SPVM::Resource::Libpng::VERSION, SPVM::Fn->get_version_string('Resource::Libpng'));

done_testing;
