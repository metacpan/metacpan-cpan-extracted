package Stancer::Dispute::Test::Functional;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use DateTime;
use Stancer::Card;
use Stancer::Customer;
use Stancer::Dispute;
use Stancer::Payment;
use List::Util qw(shuffle);
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub list : Tests(4) {
    { # 4 tests
        note 'Basic tests';

        my @currencies = shuffle(qw(usd eur gbp));
        my @dateparts = localtime;

        my $amount = random_integer(50, 9999);
        my $description = sprintf 'Automatic test for disputes list, %.02f %s', $amount / 100, uc $currencies[0];

        my $card = Stancer::Card->new();

        $card->number('4000000000000259'); # Immediately creates a dispute after payment succeed
        $card->exp_month(random_integer(1, 12));
        $card->exp_year(random_integer(10) + $dateparts[5] + 1901);
        $card->cvc(sprintf '%d', random_integer(100, 999));

        my $payment = Stancer::Payment->new;

        $payment->amount($amount);
        $payment->currency($currencies[0]);
        $payment->description($description);
        $payment->card($card);
        $payment->customer(Stancer::Customer->new(name => 'John Doe', email => 'john.doe+' . random_string(5) . '@example.com'));

        $payment->send();

        my $disputes = Stancer::Dispute->list(created => $payment->created->epoch);

        isa_ok($disputes, 'Stancer::Core::Iterator::Dispute', 'Stancer::Dispute->list(created => $payment->created->epoch)');

        my $counter = 0;

        while (my $dispute = $disputes->next) {
            isa_ok($dispute->payment, 'Stancer::Payment', '$dispute->payment');
            is($dispute->payment->id, $payment->id, 'Should be the same payment'); # but not the same instance

            $counter++;
        }

        is($counter, 1, 'Should have find only one dispute');
    }
}

1;
