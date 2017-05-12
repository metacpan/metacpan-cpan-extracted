#!/usr/bin/perl

=pod

=encoding utf-8

=head1 PURPOSE

Test the magic C<< __CLASS__ >> mapping.

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

my $i;

{
    package HolyMan;
    use Moo;
    has name  => (is => 'ro');
    has title => (is => 'ro');
}

my %org_args = (
    name       => 'Catholic Church',
    boss_name  => 'Francis',
    boss_title => 'Pope',
    boss_class => sub { $i++ % 2 ? 'Pontiff'->new(@_) : 'HolyMan'->new(@_) },
    hq_name    => 'Rome',
);

my $org = 'Organization'->new(
    %org_args
);

my $boss_test = sub {
    plan tests => 2;
    is( $org->boss->name, 'Francis', 'boss name' );
    is( $org->boss->title, 'Pope', 'boss title' );
};

isa_ok( $org->boss, 'HolyMan', 'object class at first' );
subtest 'boss test #1' => $boss_test;
$org->clear_boss;
isa_ok( $org->boss, 'Pontiff', 'object class after clear and build' );
subtest 'boss test #2' => $boss_test;

isa_ok( Organization->new(%org_args)->boss, 'HolyMan',
        'object class of a new object again' );
isa_ok( Organization->new(%org_args)->boss, 'Pontiff',
        'and object class of another new object again' );

done_testing;
