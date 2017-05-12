#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Starch;

subtest disabled => sub{
    my $starch = Starch->new(
        store => { class => '::Memory' },
    );

    my $state = $starch->state();
    $state->data->{foo} = 32;
    my $modified_first = $state->modified();
    $state->save();

    sleep 2;
    $state = $starch->state( $state->id() );
    $state->data();
    $state->save();

    $state = $starch->state( $state->id() );
    my $modified_second = $state->modified();

    is( $modified_second, $modified_first, 'state was not auto-saved' );
};

subtest enabled => sub{
    my $starch = Starch->new(
        plugins => ['::RenewExpiration'],
        store => { class => '::Memory' },
    );

    my $state = $starch->state();
    $state->data->{foo} = 32;
    my $modified_first = $state->modified();
    $state->save();

    sleep 2;
    $state = $starch->state( $state->id() );
    $state->data();
    $state->save();

    $state = $starch->state( $state->id() );
    my $modified_second = $state->modified();

    cmp_ok( $modified_second, '>', $modified_first, 'state was auto-saved' );
};

done_testing;
