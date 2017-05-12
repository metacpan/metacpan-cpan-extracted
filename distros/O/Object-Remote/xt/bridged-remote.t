use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;

use lib "$FindBin::Bin/lib";

use TestClass;
use Object::Remote;

is exception {
  my $bridge = TestBridge->new::on('-');
  is $bridge->result, 23;
}, undef, 'no error during bridge access';

done_testing;
