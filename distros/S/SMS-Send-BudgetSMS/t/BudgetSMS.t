#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use SMS::Send::BudgetSMS;

subtest 'new() tests' => sub {
    plan tests => 5;

    ok(SMS::Send::BudgetSMS->can('new'), 'method new() available');

    my $driver = SMS::Send::BudgetSMS->new(
        _login    => 'test',
        _password => 'test',
        _userid   => 'test',
    );

    is(ref($driver), 'SMS::Send::BudgetSMS',
        'new() returns an instance of SMS::Send::BudgetSMS');

    eval {
        my $driver = SMS::Send::BudgetSMS->new(
            _login    => 'test',
            _password => 'test',
        );
    };
    like($@, qr/userid/, 'Userid required');


    eval {
        my $driver = SMS::Send::BudgetSMS->new(
            _login    => 'test',
            _userid => 'test',
        );
    };
    like($@, qr/_password/, 'Password required');

    eval {
        my $driver = SMS::Send::BudgetSMS->new(
            _password => 'test',
            _userid    => 'test',
        );
    };
    like($@, qr/_login/, 'Login required');

};

subtest 'send_sms() tests' => sub {
    plan tests => 3;

    ok(SMS::Send::BudgetSMS->can('send_sms'), 'method send_sms() available');

    eval {
        my $driver = SMS::Send::BudgetSMS->new(
            _login    => 'test',
            _password => 'test',
            _userid   => 'test',
        )->send_sms( to => 1 );
    };
    like($@, qr/to and text are required/, 'Missing parameters');

    eval {
        my $driver = SMS::Send::BudgetSMS->new(
            _login    => 'test',
            _password => 'test',
            _userid   => 'test',
        )->send_sms( text => 1 );
    };
    like($@, qr/to and text are required/, 'Missing parameters');

};
