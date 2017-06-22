#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

package BankAccount {
    use Moxie;

    extends 'Moxie::Object';

    has '$!balance' => sub { 0 };

    my sub _balance : private('$!balance');

    sub BUILDARGS : init_args( balance => '$!balance' );

    sub balance : ro('$!balance');

    sub deposit ($self, $amount) { _balance += $amount }

    sub withdraw ($self, $amount) {
        (_balance >= $amount)
            || die "Account overdrawn";
        _balance -= $amount;
    }
}

package CheckingAccount {
    use Moxie;

    extends 'BankAccount';

    has '$!overdraft_account';

    my sub _overdraft_account : prototype() private('$!overdraft_account');

    sub BUILDARGS : init_args( overdraft_account => '$!overdraft_account' );

    sub overdraft_account : ro('$!overdraft_account');

    sub withdraw ($self, $amount) {

        my $overdraft_amount = $amount - $self->balance;

        if ( _overdraft_account && $overdraft_amount > 0 ) {
            _overdraft_account->withdraw( $overdraft_amount );
            $self->deposit( $overdraft_amount );
        }

        $self->next::method( $amount );
    }
}

subtest '... testing the BankAccount class' => sub {
    my $savings = BankAccount->new( balance => 250 );
    isa_ok($savings, 'BankAccount' );

    is $savings->balance, 250, '... got the savings balance we expected';

    $savings->withdraw( 50 );
    is $savings->balance, 200, '... got the savings balance we expected';

    $savings->deposit( 150 );
    is $savings->balance, 350, '... got the savings balance we expected';

    subtest '... testing the CheckingAccount class' => sub {

        my $checking = CheckingAccount->new(
            overdraft_account => $savings,
        );
        isa_ok($checking, 'CheckingAccount');
        isa_ok($checking, 'BankAccount');

        is $checking->balance, 0, '... got the checking balance we expected';

        $checking->deposit( 100 );
        is $checking->balance, 100, '... got the checking balance we expected';
        is $checking->overdraft_account, $savings, '... got the right overdraft account';

        $checking->withdraw( 50 );
        is $checking->balance, 50, '... got the checking balance we expected';
        is $savings->balance, 350, '... got the savings balance we expected';

        $checking->withdraw( 200 );
        is $checking->balance, 0, '... got the checking balance we expected';
        is $savings->balance, 200, '... got the savings balance we expected';
    };
};

subtest '... testing some meta-information' => sub {

    is_deeply(
        mro::get_linear_isa('BankAccount'),
        [ 'BankAccount', 'Moxie::Object', 'UNIVERSAL::Object' ],
        '... got the expected linear isa'
    );

    is_deeply(
        mro::get_linear_isa('CheckingAccount'),
        [ 'CheckingAccount', 'BankAccount', 'Moxie::Object', 'UNIVERSAL::Object' ],
        '... got the expected linear isa'
    );

};

done_testing;


