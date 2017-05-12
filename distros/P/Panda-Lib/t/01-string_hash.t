use 5.012;
use warnings;
use Panda::Lib;
use Test::More tests => 2;

my $ret = Panda::Lib::string_hash("hello world");
is($ret, 4305416711574135400);

$ret = Panda::Lib::string_hash32("hello world");
is($ret, 1045060183);
