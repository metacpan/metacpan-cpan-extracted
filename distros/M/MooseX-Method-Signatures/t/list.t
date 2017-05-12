use strict;
use warnings;
use Test::More tests => 25;
use Test::Fatal;
use MooseX::Method::Signatures;

my $o = bless {} => 'Foo';

{
    my %meths = (
        rest_list => method ($foo, $bar, @rest) {
            return join q{,}, @rest;
        },
        rest_named => method ($foo, $bar, %rest) {
            return join q{,}, map { $_ => $rest{$_} } sort keys %rest;
        },
    );

    for my $meth_name (keys %meths) {
        my $meth = $meths{$meth_name};
        like(exception { $o->${\$meth->body}() }, qr/^Validation failed/, "$meth_name dies without args");
        like(exception { $o->${\$meth->body}('foo') }, qr/^Validation failed/, "$meth_name dies with one arg");

        is(exception {
            is($o->${\$meth->body}('foo', 'bar'), q{}, "$meth_name - empty \@rest list");
        }, undef, '...and validates');

        is(exception {
            is($o->${\$meth->body}('foo', 'bar', 1 .. 6), q{1,2,3,4,5,6},
            "$meth_name - non-empty \@rest list");
        }, undef, '...and validates');
    }
}

{
    my $meth = method (Str $foo, Int $bar, Int @rest) {
        return join q{,}, @rest;
    };

    is(exception {
        is($o->${\$meth->body}('foo', 42), q{}, 'empty @rest list passed through');
    }, undef, '...and validates');

    is(exception {
        is($o->${\$meth->body}('foo', 42, 23, 13), q{23,13}, 'non-empty int @rest list passed through');
    }, undef, '...and validates');

    like(exception {
        $o->${\$meth->body}('foo', 42, 'moo', 13, 'non-empty str @rest list passed through');
    }, qr/^Validation failed/, "...and doesn't validate");
}

{
    my $meth = method (ArrayRef[Int] @foo) {
        return join q{,}, map { @{ $_ } } @foo;
    };

    is(exception {
        is($o->${\$meth->body}([42, 23], [12], [18]), '42,23,12,18', 'int lists passed through');
    }, undef, '...and validates');

    like(exception {
        $o->${\$meth->body}([42, 23], 12, [18]);
    }, qr/Validation failed/, "int doesn't validate against int list");
}

{
    my $meth = method (Str $foo, Int @) {};
    is(exception { $meth->($o, 'foo') }, undef, 'empty unnamed list validates');
    is(exception { $meth->($o, 'foo', 42) }, undef, '1 element of unnamed list validates');
    is(exception { $meth->($o, 'foo', 42, 23) }, undef, '2 elements of unnamed list validates');
}

{
    eval 'my $meth = method (:$foo, :@bar) { }';
    like $@, qr/arrays or hashes cannot be named/i,
        'arrays or hashes cannot be named';

    eval 'my $meth = method ($foo, @bar, :$baz) { }';
    like $@, qr/named parameters cannot be combined with slurpy positionals/i,
        'named parameters cannot be combined with slurpy positionals';
}
