#!/usr/bin/perl

=pod

=encoding utf-8

=head1 PURPOSE

Test C<< make_builder($class, %args) >>.

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
use Test::Warnings;

use t::lib::TestUtils;

my $org = 'Organization'->new(
    name       => 'Catholic Church',
    boss_name  => 'Francis',
    boss_title => 'Pope',
    boss_class => 'Pontiff',
    hq_name    => 'Rome',
);

ok( ! $org->has_boss, 'Lazy boss' );
ok( ! $org->has_headquarters, 'Lazy headquarters' );

isa_ok( $org->boss, 'Person' );
isa_ok( $org->boss, 'Pontiff' );
isa_ok( $org->headquarters, 'Place' );

my $test_attr_objects = sub {
    plan tests => 3;
    is( $org->boss->name, 'Francis', 'boss name' );
    is( $org->boss->title, 'Pope', 'boss title' );
    is( $org->headquarters->name, 'Rome', 'HQ name' );
};

subtest 'object attributes' => $test_attr_objects;

$org->clear_boss;
$org->clear_headquarters;

ok( ! $org->has_boss, 'boss cleared' );
ok( ! $org->has_headquarters, 'headquarters cleared' );

subtest 'object attributes after recreation' => $test_attr_objects;

my $org2 = 'Organization'->new(
    name       => 'Catholic Church',
    boss_name  => 'Francis',
    boss_title => 'Pope',
    hq_name    => 'Rome',
);

ok( ! $org2->boss->isa('Pontiff'), 'boss class with no __CLASS__' );

done_testing;
