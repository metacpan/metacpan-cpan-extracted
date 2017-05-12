use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::Char;

sub new {
    my $ch = String::Incremental::Char->new( @_ );
    return $ch;
}

subtest 'basic' => sub {
    my $ch = new( order => 'abcd' );
    is $ch->as_string(), 'a';

    is $ch->increment(), 'b';
    is $ch->as_string(), 'b';

    is $ch->increment(), 'c';
    is $ch->as_string(), 'c';
};

subtest 'overload' => sub {
    my $ch = new( order => 'abcd' );
    is "$ch", 'a';

    # ref: http://search.cpan.org/~rjbs/perl-5.20.0/lib/overload.pm
    #   No distinction is made between prefix and postfix forms
    #   of the increment and decrement operators:
    #   these differ only in the point at which Perl calls
    #   the associated subroutine when evaluating an expression.

    is sprintf('%s', $ch++), 'b';
    is "$ch", 'b';

    is sprintf('%s', ++$ch), 'c';
    is "$ch", 'c';
};

subtest 'overflow' => sub {
    my $ch = new( order => 'ab' );

    lives_ok {
        $ch++;
    } 'a -> b';

    dies_ok {
        $ch++;
    } 'overflow';

    is "$ch", 'b', 'counter "__i" should not be increased when die';
};

subtest '2-chars' => sub {
    my $ch1 = new( order => 'abc' );
    my $ch2 = new( order => 'xyz', upper => $ch1, __i => 1 );
    ok ! $ch1->has_upper();
    ok $ch2->has_upper();

    is "${ch1}${ch2}", 'ay';
    $ch2++;
    is "${ch1}${ch2}", 'az';
    $ch2++;
    is "${ch1}${ch2}", 'bx';

    $ch1++; $ch2++; $ch2++;
    is "${ch1}${ch2}", 'cz';

    dies_ok {
        $ch2++;
    } 'should not be albe to increment';

    is "${ch1}${ch2}", 'cz', 'value should be the one before failing increment';
};

subtest '3-chars' => sub {
    my $ch1 = new( order => 'abc' );
    my $ch2 = new( order => 'xyz', upper => $ch1 );
    my $ch3 = new( order => '13', upper => $ch2 );

    is "${ch1}${ch2}${ch3}", 'ax1';

    $ch3++;
    is "${ch1}${ch2}${ch3}", 'ax3';

    $ch3++;
    is "${ch1}${ch2}${ch3}", 'ay1';

    $ch2++; $ch2++;
    is "${ch1}${ch2}${ch3}", 'bx1';

    $ch2++; $ch2++; $ch3++;
    is "${ch1}${ch2}${ch3}", 'bz3';

    $ch3++;
    is "${ch1}${ch2}${ch3}", 'cx1';

    $ch2++; $ch2++; $ch3++;
    is "${ch1}${ch2}${ch3}", 'cz3';

    dies_ok {
        $ch3++;
    } 'should not be albe to increment';

    is "${ch1}${ch2}${ch3}", 'cz3', 'value should be the one before failing increment';

    dies_ok {
        $ch2++;
    } 'should not be albe to increment';

    is "${ch1}${ch2}${ch3}", 'cz3', 'value should be the one before failing increment';
};

done_testing;
