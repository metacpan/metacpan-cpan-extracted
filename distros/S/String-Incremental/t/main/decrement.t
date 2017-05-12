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
    ok $str->can( 'decrement' );
};

subtest 'basic' => sub {
    my $str = new(
        '%2=',
        'abc',
    );
    $str->items->[0]->__i( 2 );
    $str->items->[1]->__i( 2 );
    is $str->as_string(), 'cc';

    $str->decrement();
    is $str->as_string(), 'cb';

    $str->decrement();
    is $str->as_string(), 'ca';

    $str->decrement();
    is $str->as_string(), 'bc';

    $str->decrement()  for 1..5;
    is $str->as_string(), 'aa';
};

subtest 'overload' => sub {
    my $str = new(
        '%2=',
        'abc',
    );
    $str->items->[0]->__i( 2 );
    $str->items->[1]->__i( 2 );
    is "$str", 'cc';

    subtest 'prefix/postfix' => sub {
        # ref: http://search.cpan.org/~rjbs/perl-5.20.0/lib/overload.pm
        #   No distinction is made between prefix and postfix forms
        #   of the increment and decrement operators:
        #   these differ only in the point at which Perl calls
        #   the associated subroutine when evaluating an expression.

        is sprintf('%s', $str--), 'cb';
        is "$str", 'cb';

        is sprintf('%s', --$str), 'ca';
        is "$str", 'ca';
    };
};

subtest 'underflow' => sub {
    my $str = new(
        '%2=',
        'abc',
    );
    $str->items->[0]->__i( 2 );
    $str->items->[1]->__i( 2 );
    is "$str", 'cc';

    lives_ok {
        $str--;
    } 'cc -> cb';

    $str--  for 1..7;
    is "$str", 'aa';

    dies_ok {
        $str--;
    } 'underflow';

    is "$str", 'aa', 'positional state should not be increased when die';
};

subtest 'tying' => sub {
    tie my $str, 'String::Incremental', ( format => '%2=', orders => [ 'abc' ] );
    ok tied $str, 'should be tied';

    $str->items->[0]->__i( 2 );
    $str->items->[1]->__i( 2 );
    is "$str", 'cc';

    lives_ok {
        $str->decrement();
        is "$str", 'cb';
    };

    lives_ok {
        $str--;
        is "$str", 'ca';
    };
};

done_testing;
