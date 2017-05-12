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

{
    no strict 'refs';
    *{'String::Incremental::f'} = sub {
        return shift->re( @_ );
    };
}

subtest 'call' => sub {
    my $str = new( 'foobar' );
    ok $str->can( 're' );
    ok $str->can( 'f' );  # alias defined above
};

subtest 'args' => sub {
    my $str = new( 'foobar' );

    lives_ok {
        $str->f();
    } 'nothing';
};

subtest 'return' => sub {
    subtest 'fixed' => sub {
        my ($re, @ok, @ng);

        $re = new( 'foobar' )->f();
        isa_ok $re, 'Regexp';

        @ok = qw( foobar );
        @ng = qw( xxx foo bar );

        for ( @ok ) {
            my $memo = sprintf '"%s" should match with %s', $_, $re;
            like $_, $re, $memo;
        }
        for ( @ng ) {
            my $memo = sprintf '"%s" should not match with %s', $_, $re;
            unlike $_, $re, $memo;
        }
    };

    subtest 'string: fixed' => sub {
        my ($re, @ok, @ng);

        $re = new( '%s%04d', 'foo', '12' )->f();
        isa_ok $re, 'Regexp';

        @ok = qw( foo0012 );
        @ng = qw( foo12 foo 12 0012 );

        for ( @ok ) {
            my $memo = sprintf '"%s" should match with %s', $_, $re;
            like $_, $re, $memo;
        }
        for ( @ng ) {
            my $memo = sprintf '"%s" should not match with %s', $_, $re;
            unlike $_, $re, $memo;
        }

    };

    # subtest 'string: sub' => sub {
    # };

    subtest 'char' => sub {
        my ($re, @ok, @ng);

        subtest '1-char' => sub {
            $re = new( '%=', 'aux' )->f();
            isa_ok $re, 'Regexp';

            @ok = qw( a u x );
            @ng = qw( b o z au aux );

            for ( @ok ) {
                my $memo = sprintf '"%s" should match with %s', $_, $re;
                like $_, $re, $memo;
            }
            for ( @ng ) {
                my $memo = sprintf '"%s" should not match with %s', $_, $re;
                unlike $_, $re, $memo;
            }
        };

        subtest 'complex' => sub {
            $re = new(
                '%=%2=%=',
                'abcd',
                '13579',
                '({#/',
            )->f();
            isa_ok $re, 'Regexp';

            @ok = (
                'a11(',
                'b35#',
                'c97/',
                'd99{',
            );
            @ng = (
                'x11(',
                'a23/',
                'd99-',
            );

            for ( @ok ) {
                my $memo = sprintf '"%s" should match with %s', $_, $re;
                like $_, $re, $memo;
            }
            for ( @ng ) {
                my $memo = sprintf '"%s" should not match with %s', $_, $re;
                unlike $_, $re, $memo;
            }
        };
    };

    subtest 'mixed' => sub {
        my ($re, @ok, @ng);

        $re = new(
            '%d-foo-%2=-%04s-%%-bar',
            '123',
            'abc',
            'hoge',
        )->f();
        isa_ok $re, 'Regexp';

        @ok = qw(
            123-foo-aa-hoge-%-bar
            123-foo-ab-hoge-%-bar
            123-foo-cc-hoge-%-bar
        );
        @ng = qw(
            123-bar-aa-hoge-%-bar
            123-foo-aa-fuga-%-bar
            123-foo-ad-hoge-%-bar
            123-foo-1a-hoge-%-bar
        );

        for ( @ok ) {
            my $memo = sprintf '"%s" should match with %s', $_, $re;
            like $_, $re, $memo;
        }
        for ( @ng ) {
            my $memo = sprintf '"%s" should not match with %s', $_, $re;
            unlike $_, $re, $memo;
        }
    };
};

subtest 'capture' => sub {
    subtest 'string: fixed' => sub {
        my ($re, ($match, @cap));

        $re = new( '%s%04d', 'foo', '12' )->f();

        # ok
        ($match, @cap) = 'foo0012' =~ $re;
        ok defined $match;
        is_deeply \@cap, [];

        # ng
        ($match, @cap) = 'foo12' =~ $re;
        ok ! defined $match;
        is_deeply \@cap, [];
    };

    subtest 'char' => sub {
        my ($re, ($match, @cap));

        $re = new(
            '%=-%2=-%=',
            'abcd',
            '13579',
            '({#/',
        )->f();

        # ok
        ($match, @cap) = 'b-35-#' =~ $re;
        ok defined $match;
        is_deeply \@cap, ['b', '3', '5', '#'];

        # ng
        ($match, @cap) = 'a-2-3-/' =~ $re;
        ok ! defined $match;
        is_deeply \@cap, [];
    };

    subtest 'mixed' => sub {
        my ($re, ($match, @cap));

        $re = new(
            '%d-foo-%2=-%04s-%%-bar',
            '123',
            'abc',
            'hoge',
        )->f();

        # ok
        ($match, @cap) = '123-foo-ab-hoge-%-bar' =~ $re;
        ok defined $match;
        is_deeply \@cap, [qw( a b )];

        # ng
        ($match, @cap) = '123-foo-ad-hoge-%-bar' =~ $re;
        ok ! defined $match;
        is_deeply \@cap, [];
    };
};
done_testing;
