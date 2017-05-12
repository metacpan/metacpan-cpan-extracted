use strict;
use warnings;
use Test::More;

BEGIN {
    eval { 
	    require Moose;
		1;
	} or do {
        plan skip_all => "Moose is not available";
    };
}

{

    package Foo;
    use Moose;
    use MooX::LazierAttributes;
    attributes( 
        foo => [ ro, { one => 'two' } ],
        boo => [ rw, sub { 'Hey' } ],
    );
}

{

    package Foo::Bar;
    use Moose;
    use MooX::LazierAttributes;

    extends 'Foo';

    attributes( 
        '+foo' => [ { three => 'four' } ],
    );
}

my $o1 = Foo->new;
is_deeply( $o1->foo, { one => 'two' }, 'is deeply hashref { one => "two" }');
is($o1->boo, 'Hey', "expected Hey");
ok($o1->boo('set boo'), 'boo is rw so try a set');
is($o1->boo, 'set boo', 'boo can be set');

my $o2 = Foo::Bar->new;
is_deeply( $o2->foo, { three => 'four' }, 'is deeply hashref { three => "four" }');
is($o2->boo, 'Hey', "expected Hey");
ok($o2->boo('set boo'), 'boo is rw so try a set');
is($o2->boo, 'set boo', 'boo can be set');

done_testing;
