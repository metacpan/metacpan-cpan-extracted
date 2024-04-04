package Stancer::Card::Test::Functional;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use List::Util qw(shuffle);
use Stancer::Card;
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub get_data : Tests(11) {
    # 404
    throws_ok(
        sub { Stancer::Card->new('card_' . random_string(24))->populate() },
        'Stancer::Exceptions::Http::NotFound',
        'Should throw a NotFound (404) error',
    );

    my $card = Stancer::Card->new('card_9bKZ9cr0Ji0qSPs5c1uMQG5z');

    is($card->brand, 'visa', 'Should have a brand');
    is($card->country, 'US', 'Should have a country');
    is($card->exp_month, 2, 'Should have an expiration month');
    is($card->exp_year, 2030, 'Should have an expiration year');
    is($card->funding, 'credit', 'Should have a funding type');
    is($card->last4, '3055', 'Should have last 4 digits');
    is($card->nature, 'personnal', 'Should have a nature');
    is($card->network, 'visa', 'Should have a network');

    isa_ok($card->created, 'DateTime', '$card->created');
    is($card->created->epoch, 1_579_024_205, 'Dates should correspond');
}

sub crud : Tests(19) {
    my $card_id;

    my @dateparts = localtime;

    my $month = random_integer(1, 12);
    my $year = random_integer(20, 30) + $dateparts[5] + 1901;

    my $cvc = sprintf '%d', random_integer(100, 999);
    my $name = random_string(20);
    my $number = valid_card_number_provider();

    my $last4 = substr $number, -4;

    { # 2 tests
        note 'Basic test';

        my $card = Stancer::Card->new();

        $card->number($number);
        $card->exp_month($month);
        $card->exp_year($year);
        $card->cvc($cvc);

        isa_ok($card->send(), 'Stancer::Card', '$card->send()');

        like($card->id, qr/^card_/sm, 'Card should have an id');

        $card_id = $card->id;
    }

    { # 2 tests
        note 'Duplicate';

        my $card = Stancer::Card->new();

        $card->number($number);
        $card->exp_month($month);
        $card->exp_year($year);
        $card->cvc($cvc);

        throws_ok { $card->send() } 'Stancer::Exceptions::Http::Conflict', 'Should annonce a conflict';
        is(
            $EVAL_ERROR->message,
            'Card already exists, you may want to update it instead creating a new one (' . $card_id . q/)/,
            'Should indicate the error',
        );
    }

    { # 3 tests
        note 'Update data';

        my $card = Stancer::Card->new($card_id);

        is($card->name, undef, 'Should not have a name');

        $card->name($name);

        isa_ok($card->send(), 'Stancer::Card', '$card->send()');

        is($card->name, $name, 'Should have a name');
    }

    { # 8 tests
        note 'Read data';

        my $card = Stancer::Card->new($card_id);

        is($card->cvc, undef, 'Should not have a cvc');
        is($card->exp_month, $month, 'Should have a month');
        is($card->exp_year, $year, 'Should have a year');
        is($card->name, $name, 'Should have a name');
        is($card->number, undef, 'Should not have a number');

        # Can't validate value
        ok($card->funding, 'Should have a funding type');
        ok($card->nature, 'Should have a nature');
        ok($card->network, 'Should have a network');
    }

    { # 2 tests
        note 'Delete';

        my $card = Stancer::Card->new($card_id);

        isa_ok($card->del(), 'Stancer::Card', '$card->del()');

        is($card->id, undef, 'Should not have an ID anymore');
    }

    { # 2 tests
        note 'No more data';

        my $card = Stancer::Card->new($card_id);

        throws_ok { $card->name } 'Stancer::Exceptions::Http::NotFound', 'Should not be available';
        is($EVAL_ERROR->message, 'No such card ' . $card_id, 'Should indicate the error');
    }
}

1;
