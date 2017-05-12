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
    ok $str->can( 'increment' );
};


subtest 'basic' => sub {
    my $str = new(
        '%2=',
        'abc',
    );
    is $str->as_string(), 'aa';

    $str->increment();
    is $str->as_string(), 'ab';

    $str->increment();
    is $str->as_string(), 'ac';

    $str->increment();
    is $str->as_string(), 'ba';

    $str->increment()  for 1..5;
    is $str->as_string(), 'cc';
};

subtest 'overload' => sub {
    my $str = new(
        '%2=',
        'abc',
    );
    is "$str", 'aa';

    subtest 'prefix/postfix' => sub {
        # ref: http://search.cpan.org/~rjbs/perl-5.20.0/lib/overload.pm
        #   No distinction is made between prefix and postfix forms
        #   of the increment and decrement operators:
        #   these differ only in the point at which Perl calls
        #   the associated subroutine when evaluating an expression.

        is sprintf('%s', $str++), 'ab';
        is "$str", 'ab';

        is sprintf('%s', ++$str), 'ac';
        is "$str", 'ac';
    };
};

subtest 'overflow' => sub {
    my $str = new(
        '%2=',
        'abc',
    );
    is "$str", 'aa';

    lives_ok {
        $str++;
    } 'aa -> ab';

    $str++  for 1..7;
    is "$str", 'cc';

    dies_ok {
        $str++;
    } 'overflow';

    is "$str", 'cc', 'positional state should not be increased when die';
};

subtest 'tying' => sub {
    tie my $str, 'String::Incremental', ( format => '%2=', orders => [ 'abc' ] );
    ok tied $str, 'should be tied';
    is "$str", 'aa';

    lives_ok {
        $str->increment();
        is "$str", 'ab';
    };

    lives_ok {
        $str++;
        is "$str", 'ac';
    };
};

done_testing;
