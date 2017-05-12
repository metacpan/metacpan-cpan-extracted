# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PHP-Serialization-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('PHP::Serialization::XS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $class = 'PHP::Serialization::XS';

is($class->decode('s:1:"h"'), "h");
is($class->decode('i:123'), 123);
is($class->decode('b:1'), 1);
is($class->decode('d:2.5'), 2.5);
is_deeply($class->decode('a:1:{i:0;s:2:"xx"}'), [ 'xx' ]);
is_deeply($class->decode('a:2:{i:0;s:2:"xx";i:1;s:2:"yy"}'), [ 'xx', 'yy' ]);
is_deeply($class->decode('a:2:{i:0;s:2:"xx";i:5;s:2:"yy"}'), { 0 => 'xx', 5 => 'yy' });
{
my $got = $class->decode('O:1:"A":1:{s:1:"B";s:2:"yy"}');
my $exp = bless({ B => "yy" }, "A");
isa_ok($got, "A");
is_deeply($exp, $got);
}

{
my $got = $class->decode('O:1:"A":1:{s:1:"B";s:2:"yy"}', "Long::Prefix");
my $exp = bless({ B => "yy" }, "A");
isa_ok($got, "Long::Prefix::A");
is_deeply($exp, $got);
}

