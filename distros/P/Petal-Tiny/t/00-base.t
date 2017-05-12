# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;
BEGIN { use_ok('Petal::Tiny') };
use warnings;
use strict;

my $file = -e './data/00.xml' ? './data/00.xml' : './t/data/00.xml';
my $t1 = Petal::Tiny->new ($file);
ok ($t1);
ok ($t1->process());

my $data = join '', <DATA>;
my $t2 = Petal::Tiny->new ($data);
ok ($t2);
ok ($t2->process());

Test::More::done_testing();
__DATA__
<xml>
  This is a test
  <foo bar="buz" baz="booze">with some tag in there</foo>
</xml>
