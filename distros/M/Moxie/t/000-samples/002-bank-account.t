#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

package BankAccount {
    use Moxie;

    extends 'Moxie::Object';

    has name => ( required => 'A `name` is required' );

    has _balance => sub { 0 };

    my sub _balance : private;

    sub BUILDARGS : init(
        name     => name,
        balance? => _balance,
    );

    sub name    : ro;
    sub balance : ro(_balance);

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

    has _overdraft_account => ();

    my sub _overdraft_account : private;

    sub BUILDARGS : init(
        name               => super(name),
        balance?           => super(balance),
        overdraft_account? => _overdraft_account,
    );

    sub overdraft_account         : ro(_overdraft_account);
    sub has_overdraft_account     : predicate(_overdraft_account);
    sub available_overdraft_funds : handles(_overdraft_account->balance);

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
    my $savings = BankAccount->new(
        name    => 'S. Little',
        balance => 250,
    );
    isa_ok($savings, 'BankAccount' );

    is $savings->name, 'S. Little', '... got the name we expected';
    is $savings->balance, 250, '... got the savings balance we expected';

    $savings->withdraw( 50 );
    is $savings->balance, 200, '... got the savings balance we expected';

    $savings->deposit( 150 );
    is $savings->balance, 350, '... got the savings balance we expected';

    subtest '... testing the CheckingAccount class' => sub {

        my $checking = CheckingAccount->new(
            name              => 'S. Little',
            overdraft_account => $savings,
        );
        isa_ok($checking, 'CheckingAccount');
        isa_ok($checking, 'BankAccount');

        ok $checking->has_overdraft_account, '... we have an overdraft account';

        is $checking->available_overdraft_funds, $savings->balance, '... we have the expected overdraft balance';

        is $checking->name, 'S. Little', '... got the name we expected';
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

    subtest '... testing the CheckingAccount class (with balance)' => sub {

        my $checking = CheckingAccount->new(
            name              => 'S. Little',
            balance           => 300,
            overdraft_account => $savings,
        );
        isa_ok($checking, 'CheckingAccount');
        isa_ok($checking, 'BankAccount');

        ok $checking->has_overdraft_account, '... we have an overdraft account';

        is $checking->available_overdraft_funds, $savings->balance, '... we have the expected overdraft balance';

        is $checking->name, 'S. Little', '... got the name we expected';
        is $checking->balance, 300, '... got the checking balance we expected';

        $checking->deposit( 100 );
        is $checking->balance, 400, '... got the checking balance we expected';
        is $checking->overdraft_account, $savings, '... got the right overdraft account';

        $checking->withdraw( 50 );
        is $checking->balance, 350, '... got the checking balance we expected';
        is $savings->balance, 200, '... got the savings balance we expected';

        $checking->withdraw( 400 );
        is $checking->balance, 0, '... got the checking balance we expected';
        is $savings->balance, 150, '... got the savings balance we expected';
    };

    subtest '... testing the CheckingAccount class' => sub {

        my $checking = CheckingAccount->new( name => 'S. Little' );
        isa_ok($checking, 'CheckingAccount');
        isa_ok($checking, 'BankAccount');

        ok !$checking->has_overdraft_account, '... we have an overdraft account';

        is $checking->name, 'S. Little', '... got the name we expected';
        is $checking->balance, 0, '... got the checking balance we expected';
    };
};

subtest '... testing some error conditions' => sub {

    like(
        exception { BankAccount->new },
        qr/Constructor for \(BankAccount\) expected between 2 and 4 arguments\, got \(0\)/,
        '... the balance argument is required'
    );

    like(
        exception { BankAccount->new( foo => 10 ) },
        qr/Constructor for \(BankAccount\) missing \(`.*`\) parameters\, got \(`foo`\)\, expected \(`balance\?`\, `name`\)/,
        '... the balance argument is required and unknown arguments are rejected'
    );


    like(
        exception { CheckingAccount->new },
        qr/Constructor for \(CheckingAccount\) expected between 2 and 6 arguments\, got \(0\)/,
        '... the balance argument is required'
    );

    like(
        exception { CheckingAccount->new( balance => 10 ) },
        qr/Constructor for \(CheckingAccount\) missing \(`name`\) parameters\, got \(`balance`\)\, expected \(`balance\?`\, `name`\, `overdraft_account\?`\)/,
        '... the balance argument is required'
    );

};

done_testing;


