use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental qw( incremental_string );

lives_ok {
    incremental_string( 'foobar' );
};

my $str = incremental_string( 'foo-%=%2=', 'abc', [0, 1, 2] );
isa_ok $str, 'String::Incremental';
is "$str", 'foo-a00';
is $str->format, 'foo-%s%s%s';
is @{$str->items}, 3;
is @{$str->chars}, 3;

done_testing;
