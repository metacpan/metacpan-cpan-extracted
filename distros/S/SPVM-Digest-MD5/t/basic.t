use lib 't/lib';
use blib 'perl_impl';
use SPVM 'Digest::MD5';
use Digest::MD5;
use SPVMImpl;
Digest::MD5::is_spvm();
die unless $INC{'Digest/MD5.pm'} =~ /\bblib\b/;

use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Digest::MD5';

ok(SPVM::TestCase::Digest::MD5->test);

done_testing;
