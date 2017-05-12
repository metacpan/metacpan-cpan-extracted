#!/usr/bin/perl

=pod

=encoding utf-8

=head1 PURPOSE

Weird edge-cases like undefined classes.

=head1 AUTHOR

Torbjørn Lindahl.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Torbjørn Lindahl.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warnings;

use t::lib::TestUtils;

sub test_org_object {

    my %args = @_;

    my $org = 'Organization'->new(%args);

    plan tests => 7;

    ok( ! $org->has_boss, 'Lazy boss' );
    ok( ! $org->has_headquarters, 'Lazy headquarters' );

    isa_ok( $org->boss, 'Person' );
    isa_ok( $org->headquarters, 'Place' );

    is( $org->boss->name, $args{boss_name}, 'boss name' );
    is( $org->boss->title, $args{boss_title}, 'boss title' );
    is( $org->headquarters->name, $args{hq_name}, 'HQ name' );

};

subtest 'empty attr values' => sub {
    test_org_object(
        name       => '',
        boss_name  => '',
        boss_title => '',
        boss_class => 'Pontiff',
        hq_name    => '',
    );
};

subtest 'undef boss class' => sub {
    
    my $org;
    is(exception {
        $org = Organization->new(
            name       => 'Catholic Church',
            boss_name  => 'Francis',
            boss_title => 'Pope',
            boss_class => '',
            hq_name    => 'Rome',
        )
    }, undef, 'org created with empty boss class');
    
    like(exception { $org->boss },
      qr/\ACan't call method "new"/);
};

subtest 'empty boss class' => sub {

    my $org;
    is(exception {
        $org = Organization->new(
            name       => 'Catholic Church',
            boss_name  => 'Francis',
            boss_title => 'Pope',
            boss_class => '',
            hq_name    => 'Rome',
        )
    }, undef, 'org created with empty boss class');

    like(exception { $org->boss },
        qr/\ACan't call method "new" without a package or object/,
        'error on accessing boss with empty class');

};

subtest 'attr values 0' => sub {
    test_org_object(
        name       => 0,
        boss_name  => 0,
        boss_title => 0,
        boss_class => 'Pontiff',
        hq_name    => 0,
    );
};

done_testing;
