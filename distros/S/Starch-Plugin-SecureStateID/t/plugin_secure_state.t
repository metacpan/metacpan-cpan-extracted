#!/usr/bin/env perl
#use strictures 2;

use Test::More;
use Starch;

eval "use Math::Random::Secure;";
plan skip_all => "Math::Random::Secure is not installed."
    if $@;

my $secure_rand_called = 0;
{
    no warnings 'redefine';
    my $original_random = \&Math::Random::Secure::rand;
    *Math::Random::Secure::rand = sub (;$) {
        $secure_rand_called++;
        return $original_random->();
    };
}

subtest default_options => sub {
    my $starch = Starch->new(
        plugins => ['::SecureStateID'],
        store   => { class => '::Memory' },
    );

    my $state = $starch->state();
    is length $state->id, 64, 'SHA-256 used for state id';
    is $secure_rand_called, 1, 'Math::Random::Secure::rand was used';
};

subtest sha512_used => sub {
    my $starch = Starch->new(
        plugins             => ['::SecureStateID'],
        store               => { class => '::Memory' },
        secure_state_id_sha => 512,
    );

    my $state = $starch->state();
    is length $state->id, 128, 'SHA-512 used for state id';
    is $secure_rand_called, 2, 'Math::Random::Secure::rand was used';
};

done_testing;
