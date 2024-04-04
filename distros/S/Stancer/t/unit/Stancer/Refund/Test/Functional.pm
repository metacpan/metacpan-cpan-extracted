package Stancer::Refund::Test::Functional;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Card;
use Stancer::Customer;
use Stancer::Payment;
use Stancer::Payment::Status;
use Stancer::Refund::Status;
use List::Util qw(shuffle);
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub refund : Tests(38) {
    { # 11 tests
        note 'Full refund';

        my $payment = Stancer::Payment->new;
        my $card = Stancer::Card->new;
        my $customer = Stancer::Customer->new;

        my $amount = random_integer(50, 100_000);
        my $currency = currencies_provider();

        my $month = floor(rand(12) + 1);
        my @parts = localtime;
        my $year = floor(rand(15) + $parts[5] + 1901);

        $card->number(valid_card_number_provider());
        $card->exp_month($month);
        $card->exp_year($year);
        $card->cvc(random_integer(100, 999));

        $customer->name('John Doe');
        $customer->email('john.doe@example.com');

        $payment->card($card);
        $payment->customer($customer);
        $payment->amount($amount);
        $payment->currency($currency);
        $payment->description(sprintf 'Refund test, %.2f %s', $amount / 100, $currency);

        $payment->send(); # Create payment to refund

        is($payment->status, Stancer::Payment::Status::TO_CAPTURE, 'Payment is waiting to be captured');

        throws_ok {
            $payment->refund(random_integer(50, $amount))
        } 'Stancer::Exceptions::Http::Conflict', 'Partial refunds are impossible on not captured payment';

        is(
            $EVAL_ERROR->message,
            'Payment cannot be partially refunded before it has been captured',
            'Check exception message',
        );

        isa_ok($payment->refund(), 'Stancer::Payment', '$payment->refund()');
        is($payment->status, Stancer::Payment::Status::CANCELED, 'Payment is now canceled');

        my $refunds = $payment->refunds();

        is(ref $refunds, 'ARRAY', 'Should return an array');
        ok(scalar @{$refunds} == 1, 'Should have one refund');

        is($refunds->[0]->amount, $amount, 'Should have refunded all amount');
        is($refunds->[0]->currency, lc $currency, 'Should have refunded with same currency');
        is($refunds->[0]->payment, $payment, 'Should have same instance of orignal payment');
        is(
            $refunds->[0]->status,
            Stancer::Refund::Status::PAYMENT_CANCELED,
            'Should indicate that the source payment has been canceled',
        );
    }

    { # 27 tests
        note 'Multiple refunds';

        my $payment = Stancer::Payment->new;
        my $card = Stancer::Card->new;
        my $customer = Stancer::Customer->new;

        my $amount = random_integer(150, 100_000);
        my $currency = currencies_provider();

        my $month = floor(rand(12) + 1);
        my @parts = localtime;
        my $year = floor(rand(15) + $parts[5] + 1901);

        $card->number('4000000000000077');
        $card->exp_month($month);
        $card->exp_year($year);
        $card->cvc(random_integer(100, 999));

        $customer->name('John Doe');
        $customer->email('john.doe@example.com');

        $payment->card($card);
        $payment->customer($customer);
        $payment->amount($amount);
        $payment->currency($currency);
        $payment->description(sprintf 'Refund test, %.2f %s', $amount / 100, $currency);

        $payment->send(); # Create payment to refund

        my $amount_1 = random_integer(50, $amount / 3);
        my $amount_2 = random_integer(50, $amount / 4);
        my $amount_3 = $amount - $amount_1 - $amount_2;

        my $refunds;

        # First refund

        isa_ok($payment->refund($amount_1), 'Stancer::Payment', '$payment->refund($amount)');

        $refunds = $payment->refunds();

        is(ref $refunds, 'ARRAY', 'Should return an array');
        ok(scalar @{$refunds} == 1, 'Should have one refund');

        is($refunds->[0]->amount, $amount_1, 'Should have refunded all amount (1st call)');
        is($refunds->[0]->currency, lc $currency, 'Should have refunded with same currency (1st call)');
        is($refunds->[0]->payment, $payment, 'Should have same instance of orignal payment (1st call)');

        # Second refund

        isa_ok($payment->refund($amount_2), 'Stancer::Payment', '$payment->refund($amount)');

        $refunds = $payment->refunds();

        is(ref $refunds, 'ARRAY', 'Should return an array');
        ok(scalar @{$refunds} == 2, 'Should have one refund');

        is($refunds->[0]->amount, $amount_1, 'Should have refunded all amount (2nd call, 1st refund)');
        is($refunds->[0]->currency, lc $currency, 'Should have refunded with same currency (2nd call, 1st refund)');
        is($refunds->[0]->payment, $payment, 'Should have same instance of orignal payment (2nd call, 1st refund)');

        is($refunds->[1]->amount, $amount_2, 'Should have refunded all amount (2nd call, 2nd refund)');
        is($refunds->[1]->currency, lc $currency, 'Should have refunded with same currency (2nd call, 2nd refund)');
        is($refunds->[1]->payment, $payment, 'Should have same instance of orignal payment (2nd call, 2nd refund)');

        # Full refund

        isa_ok($payment->refund(), 'Stancer::Payment', '$payment->refund()');

        $refunds = $payment->refunds();

        is(ref $refunds, 'ARRAY', 'Should return an array');
        ok(scalar @{$refunds} == 3, 'Should have one refund');

        is($refunds->[0]->amount, $amount_1, 'Should have refunded all amount (3rd call, 1st refund)');
        is($refunds->[0]->currency, lc $currency, 'Should have refunded with same currency (3rd call, 1st refund)');
        is($refunds->[0]->payment, $payment, 'Should have same instance of orignal payment (3rd call, 1st refund)');

        is($refunds->[1]->amount, $amount_2, 'Should have refunded all amount (3rd call, 2nd refund)');
        is($refunds->[1]->currency, lc $currency, 'Should have refunded with same currency (3rd call, 2nd refund)');
        is($refunds->[1]->payment, $payment, 'Should have same instance of orignal payment (3rd call, 2nd refund)');

        is($refunds->[2]->amount, $amount_3, 'Should have refunded all amount (3rd call, 3rd refund)');
        is($refunds->[2]->currency, lc $currency, 'Should have refunded with same currency (3rd call, 3rd refund)');
        is($refunds->[2]->payment, $payment, 'Should have same instance of orignal payment (3rd call, 3rd refund)');
    }
}

1;
