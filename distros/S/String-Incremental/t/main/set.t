use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental;

sub new {
    my ($format, @orders) = @_;
    my $str = String::Incremental->new( format => $format, orders => \@orders );
    return $str;
}

subtest 'call' => sub {
    my $str = new( 'foobar' );
    ok $str->can( 'set' );
};

subtest 'ng' => sub {
    my $str = new( '%s-%=%=', 'foo', 'abc', 'xyz' );
    is "$str", 'foo-ax';

    dies_ok {
        $str->set();
    } 'no arg';

    for (qw(
        hoge
        foo-abc
        foo-ab
        foo-xx
    )) {
        dies_ok {
            $str->set( $_ );
        } 'does not match';
    }
};

subtest 'ok' => sub {
    my $str = new( '%s-%=%=', 'foo', 'abc', 'xyz' );
    is "$str", 'foo-ax';

    $str->set( 'foo-cz' );
    is "$str", 'foo-cz';

    dies_ok {
        $str++;
    } 'of cource, cannot increment';

    $str->set( 'foo-bz' );
    is "$str", 'foo-bz';

    $str++;
    is "$str", 'foo-cx';
};

subtest 'tying' => sub {
    tie my $str, 'String::Incremental', ( format => '%s-%=%=', orders => [ 'foo', 'abc', 'xyz' ] );
    ok tied $str, 'should be tied';
    isa_ok $str, 'String::Incremental';
    is "$str", 'foo-ax';

    subtest 'ng' => sub {
        dies_ok { $str = 'hoge' };
        dies_ok { $str = 'foo-abc' };
    };

    subtest 'ok' => sub {
        $str = 'foo-cz';
        is "$str", 'foo-cz';
        isa_ok $str, 'String::Incremental';
        dies_ok {
            $str++;
        } 'cannot increment';

        $str = 'foo-bz';
        is "$str", 'foo-bz';
        isa_ok $str, 'String::Incremental';
        lives_ok {
            $str++;
            is "$str", 'foo-cx';
        };
    };
};

done_testing;
