use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::FormatParser;

sub new {
    my $fp = String::Incremental::FormatParser->new( @_ );
    return $fp;
}

subtest 'args' => sub {
    dies_ok {
        new();
    } 'nothing';

    subtest 'format (1st arg)' => sub {
        lives_ok {
            new( 'foobar' );
        } 'no conversion';

        lives_ok {
            new( 'foo-%2=.%s', 'abc', 'xyz', sub { 'hoge' } );
        } 'num of conversions and num of values/orders are same';

        dies_ok {
            new( 'foo-%2=.%s' );
        } 'num of conversions and num of values/orders are different';
    };
};

subtest 'properties' => sub {
    my $fp = new(
        '%dfoo%2=%04s%%bar',
        '123',
        'abc',
        'hoge',
    );
    is $fp->format, '%dfoo%s%s%04s%%bar';
    isa_ok $fp->items->[0], 'String::Incremental::String';
    isa_ok $fp->items->[1], 'String::Incremental::Char';
    isa_ok $fp->items->[2], 'String::Incremental::Char';
    isa_ok $fp->items->[3], 'String::Incremental::String';
    isa_ok $fp->items->[4], 'String::Incremental::String';
};

done_testing;
