use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

my $ref = tie my %db, 'RocksDB', $name, { create_if_missing => 1 };
ok tied %db;
isa_ok $ref, 'RocksDB';
$db{foo} = 'bar';
is $db{foo}, 'bar';
ok exists $db{foo};
$db{"nu\0ll"} = "bar\0baz";
is $db{"nu\0ll"}, "bar\0baz", 'contains null';
ok exists $db{"nu\0ll"};
is scalar %db, 2;
is_deeply [keys %db], ['foo', "nu\0ll"];

my ($key, $value) = each %db;
is $key, 'foo';
is $value, 'bar';
($key, $value) = each %db;
is $key, "nu\0ll";
is $value, "bar\0baz";
($key, $value) = each %db;
ok !defined $key;
ok !defined $value;

delete $db{foo};
delete $db{"nu\0ll"};
is $db{foo}, undef;
ok !exists $db{foo};
is $db{"nu\0ll"}, undef;
ok !exists $db{"nu\0ll"};
%db = ();

done_testing;

END {
    RocksDB->destroy_db($name);
}
