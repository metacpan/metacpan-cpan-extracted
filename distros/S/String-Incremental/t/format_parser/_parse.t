use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::FormatParser;

sub f {
    return String::Incremental::FormatParser::_parse( @_ );
}

subtest 'args' => sub {
    dies_ok {
        f();
    } 'missing';

    lives_ok {
        f( 'foobar' );
    } 'no conversion';

    lives_ok {
        f( 'foo-%2=.%s', 'abc', 'xyz', sub { 'hoge' } );
    } 'num of conversions and num of values/orders are same';

    dies_ok {
        f( 'foo-%2=.%s' );
    } 'num of conversions and num of values/orders are different';
};

subtest 'return' => sub {
    {
        my $p = f( 'foobar' );
        is_deeply $p, {
            format => 'foobar',
            items  => [],
        };
    }

    {
        my $p = f(
            #+1   +1     +1   +1   +1    +1
            '%sfoo%dbar%04sbaz%%%4.2fhoge%c',
            'aaa',
            '123',
            'bb',
            1.234,
            46,
        );
        is 0+@{$p->{items}}, 6;
        isa_ok $p->{items}[0], 'String::Incremental::String';
        isa_ok $p->{items}[1], 'String::Incremental::String';
        isa_ok $p->{items}[2], 'String::Incremental::String';
        isa_ok $p->{items}[3], 'String::Incremental::String';
        isa_ok $p->{items}[4], 'String::Incremental::String';
        isa_ok $p->{items}[5], 'String::Incremental::String';
    }

    {
        my $p = f(
            #+1    +3    +2
            '%=foo%3=bar%2=baz',
            '123',
            'abc',
            'xyz',
        );
        is 0+@{$p->{items}}, 6;
        isa_ok $p->{items}[0], 'String::Incremental::Char';
        isa_ok $p->{items}[1], 'String::Incremental::Char';
        isa_ok $p->{items}[2], 'String::Incremental::Char';
        isa_ok $p->{items}[3], 'String::Incremental::Char';
        isa_ok $p->{items}[4], 'String::Incremental::Char';
        isa_ok $p->{items}[5], 'String::Incremental::Char';

        ok !  $p->{items}[0]->has_upper();
        isa_ok $p->{items}[1]->upper, 'String::Incremental::Char';
        isa_ok $p->{items}[2]->upper, 'String::Incremental::Char';
        isa_ok $p->{items}[3]->upper, 'String::Incremental::Char';
        isa_ok $p->{items}[4]->upper, 'String::Incremental::Char';
        isa_ok $p->{items}[5]->upper, 'String::Incremental::Char';
    }

    {
        my $p = f(
            #+1    +2  +1+1
            '%dfoo%2=%04s%%bar',
            '123',
            'abc',
            'hoge',
        );
        is 0+@{$p->{items}}, 5;
        isa_ok $p->{items}[0], 'String::Incremental::String';
        isa_ok $p->{items}[1], 'String::Incremental::Char';
        isa_ok $p->{items}[2], 'String::Incremental::Char';
        isa_ok $p->{items}[3], 'String::Incremental::String';
        isa_ok $p->{items}[4], 'String::Incremental::String';

        ok ! $p->{items}[1]->has_upper();
        isa_ok $p->{items}[2]->upper, 'String::Incremental::Char';
    }
};

done_testing;
