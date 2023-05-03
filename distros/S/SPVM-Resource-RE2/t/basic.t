use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Fn';
use SPVM 'Resource::RE2';
use SPVM::Resource::RE2;

use SPVM 'TestCase::Resource::RE2';

ok(SPVM::TestCase::Resource::RE2->test);

is($SPVM::Resource::RE2::VERSION, SPVM::Fn->get_version_string('Resource::RE2'));

done_testing;
