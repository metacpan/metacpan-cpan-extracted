use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Mozilla::CA';

use SPVM 'Mozilla::CA';
use SPVM::Mozilla::CA;
use SPVM 'Fn';

ok(SPVM::TestCase::Mozilla::CA->test);

# Version
{
  my $version_string = SPVM::Fn->get_version_string("Mozilla::CA");
  is($SPVM::Mozilla::CA::VERSION, $version_string);
}

done_testing;
