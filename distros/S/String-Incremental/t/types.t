use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::Types qw( is_Char is_CharOrderStr is_CharOrderArrayRef );

subtest 'Char' => sub {
    my @ok = qw(
        a
        1
        %
        $
    );
    my @ng = (
        '',
        ' ',
        'ab',
        '123',
    );
    for ( @ok ) {
        my $memo = sprintf '"%s" should be-a Char', $_;
        ok is_Char( $_ ), $memo;
    }
    for ( @ng ) {
        my $memo = sprintf '"%s" should not be-a Char', $_;
        ok ! is_Char( $_ ), $memo;
    }
};

subtest 'CharOrderStr' => sub {
    my @ok = qw(
        a
        123
        abc123$@%
    );
    my @ng = qw(
        abca
        123abc$a789
    );
    for ( @ok ) {
        my $memo = sprintf '"%s" should be-a CharOrderStr', $_;
        ok is_CharOrderStr( $_ ), $memo;
    }
    for ( @ng ) {
        my $memo = sprintf '"%s" should not be-a CharOrderStr', $_;
        ok ! is_CharOrderStr( $_ ), $memo;
    }
};

subtest 'CharOrderArrayRef' => sub {
    my @ok = (
        ['a'],
        [1, 2, 3],
        ['a', 'b', 'c', '1', '2', '3', '$', '#', '@', '%'],
    );
    my @ng = (
        ['a', 'b', 'c', 'a'],
        ['1', '2', '3', 'a', 'b', 'c', '$', 'a', '7', '8', '9'],
    );
    for ( @ok ) {
        my $dump = qq{[@{[join ',', map "'$_'", @$_]}]};
        my $memo = sprintf '%s should be-a CharOrderArrayRef', $dump;
        ok is_CharOrderArrayRef( $_ ), $memo;
    }
    for ( @ng ) {
        my $dump = qq{[@{[join ',', map "'$_'", @$_]}]};
        my $memo = sprintf '%s should not be-a CharOrderArrayRef', $dump;
        ok ! is_CharOrderArrayRef( $_ ), $memo;
    }
};

done_testing;
