#!perl -w
use strict;
use Test::More;
use Smart::Args;
use t::lib::Foo;
{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn .= "@_";
    };

    is add(x => 10, y => 20), 30;
    is $warn, '';

    $warn = '';
    is add(x => 1, y => 2, qux => 30), 3;
    like $warn, qr/unknown arguments: qux/;

    $warn = '';
    is add(bbb => 3, aaa => 4, x => 1, y => 2), 3;
    like $warn, qr/unknown arguments: aaa, bbb/;
}

{
    local $SIG{__WARN__} = sub { die @_ };
    eval {
        add( x => 10, y => 20, qux => 2 );
    };
    like $@, qr/unknown arguments: qux/;
}

done_testing;

