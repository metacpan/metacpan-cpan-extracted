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
    my $ch = new( order => 'abcd', __i => 3 );
    is $ch->as_string(), 'd';

    is $ch->decrement(), 'c';
    is $ch->as_string(), 'c';

    is $ch->decrement(), 'b';
    is $ch->as_string(), 'b';
};

subtest 'overload' => sub {
    my $ch = new( order => 'abcd', __i => 3 );
    is "$ch", 'd';

    # ref: http://search.cpan.org/~rjbs/perl-5.20.0/lib/overload.pm
    #   No distinction is made between prefix and postfix forms
    #   of the increment and decrement operators:
    #   these differ only in the point at which Perl calls
    #   the associated subroutine when evaluating an expression.

    is sprintf('%s', $ch--), 'c';
    is "$ch", 'c';

    is sprintf('%s', --$ch), 'b';
    is "$ch", 'b';
};

subtest 'underflow' => sub {
    my $ch = new( order => 'ab', __i => 1 );

    lives_ok {
        $ch--;
    } 'b -> a';

    dies_ok {
        $ch--;
    } 'underflow';

    is "$ch", 'a', 'counter "__i" should not be decreased when die';
};

subtest '2-chars' => sub {
    my $ch1 = new( order => 'abc', __i => 2 );
    my $ch2 = new( order => 'xyz', upper => $ch1, __i => 1 );
    ok ! $ch1->has_upper();
    ok $ch2->has_upper();

    is "${ch1}${ch2}", 'cy';
    $ch2--;
    is "${ch1}${ch2}", 'cx';
    $ch2--;
    is "${ch1}${ch2}", 'bz';

    $ch1--; $ch2--; $ch2--;
    is "${ch1}${ch2}", 'ax';

    dies_ok {
        $ch2--;
    } 'should not be albe to decrement';

    is "${ch1}${ch2}", 'ax', 'value should be the one before failing decrement';
};

subtest '3-chars' => sub {
    my $ch1 = new( order => 'abc', __i => 2 );
    my $ch2 = new( order => 'xyz', upper => $ch1, __i => 2 );
    my $ch3 = new( order => '13', upper => $ch2 );

    is "${ch1}${ch2}${ch3}", 'cz1';

    $ch3--;
    is "${ch1}${ch2}${ch3}", 'cy3';

    $ch2--; $ch3--;
    is "${ch1}${ch2}${ch3}", 'cx1';

    $ch3--;
    is "${ch1}${ch2}${ch3}", 'bz3';

    $ch2--; $ch2--; $ch3--;
    is "${ch1}${ch2}${ch3}", 'bx1';

    $ch2--;
    is "${ch1}${ch2}${ch3}", 'az1';

    $ch2--; $ch2--;
    is "${ch1}${ch2}${ch3}", 'ax1';

    dies_ok {
        $ch3--;
    } 'should not be albe to decrement';

    is "${ch1}${ch2}${ch3}", 'ax1', 'value should be the one before failing decrement';

    dies_ok {
        $ch2--;
    } 'should not be albe to decrement';

    is "${ch1}${ch2}${ch3}", 'ax1', 'value should be the one before failing decrement';
};

done_testing;
