use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental;

sub new {
    my $str = String::Incremental->new( @_ );
    return $str;
}

subtest 'args' => sub {
    dies_ok {
        new();
    } 'nothing';

    lives_ok {
        new( format => 'foobar' );
    } 'no conversion';

    lives_ok {
        new(
            format => 'foo-%2=.%s',
            orders => [ 'abc', 'xyz', sub { 'hoge' } ],
        );
    } 'num of conversions and num of values/orders are same';

    dies_ok {
        new( format => 'foo-%2=.%s' );
    } 'num of conversions and num of values/orders are different';
};

subtest 'properties' => sub {
    my $str = new(
        format => '%dfoo%2=%04s%%bar',
        orders => [
            '123',
            'abc',
            'hoge',
        ],
    );
    is $str->format, '%dfoo%s%s%04s%%bar';
    is scalar( @{$str->items} ), 5;
    isa_ok $str->items->[0], 'String::Incremental::String';
    isa_ok $str->items->[1], 'String::Incremental::Char';
    isa_ok $str->items->[2], 'String::Incremental::Char';
    isa_ok $str->items->[3], 'String::Incremental::String';
    isa_ok $str->items->[4], 'String::Incremental::String';
    is scalar( @{$str->chars} ), 2;
    for ( @{$str->chars} ) {
        isa_ok $_, 'String::Incremental::Char';
    }
};

done_testing;
