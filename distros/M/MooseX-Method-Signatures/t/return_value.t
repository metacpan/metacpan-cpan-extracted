use strict;
use warnings;
use Test::More tests => 5;
use Test::Fatal;

use MooseX::Method::Signatures;

my $o = bless {} => 'Foo';

{
    my $meth = method (Str $foo, Int $bar) returns (ArrayRef[Str]) {
        return [($foo) x $bar];
    };
    isa_ok($meth, 'Moose::Meta::Method');

    ok(exception {
        $o->${\$meth->body}('foo')
    });

    is(exception {
        my $ret = $o->${\$meth->body}('foo', 3);
        is_deeply($ret, [('foo') x 3]);
    }, undef);
}

{
    my $meth = method (Str $foo) returns (Int) {
        return 42.5;
    };

    ok(exception {
        my $x = $o->${\$meth->body}('foo');
    });
}
