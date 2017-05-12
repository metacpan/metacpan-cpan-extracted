#!/usr/bin/perl -w
use File::Spec;
use Cwd qw(abs_path);
use FindBin qw($Bin);

BEGIN {
    unshift @INC, abs_path( File::Spec->catdir( $Bin, '..', 'lib' ) );
}

{

    package MooseState;

    use Moose;

    has 'name' => (
        is       => 'rw',
        default => 1,
    );

    has 'capital' => (
        is       => 'ro',
        default => 1,
    );

    has 'population' => (
        is       => 'rw',
        default => 1,
    );

    __PACKAGE__->meta->make_immutable();
}
{

    package MoState;

    use Moo;

    has 'name' => (
        is       => 'rw',
        default => 1,
    );

    has 'capital' => (
        is       => 'ro',
        default => 1,
    );

    has 'population' => (
        is       => 'rw',
        default => 1,
    );
}

{

    package MomoState;

    use Momo;

    has name       => 1;
    has capital    => 1;
    has population => 1;

    1;
}

package main;

use strict;
use warnings 'all';
use Benchmark qw( :all :hireswallclock );

my %args = (
    name       => 'Colorado',
    capital    => 'Denver',
    population => 5_000_000,
);

my $results = timethese(
    1_000_000,
    {
        blessed_hashref => \&blessed_hashref,
        hashref         => \&hashref,
        moose           => \&moose,
        moo             => \&moo,
        momo            => \&momo,
    }
);

cmpthese($results);

sub blessed_hashref {
    my $state = bless {%args}, 'Foo';
    $state->{name};
}    # end blessed_hashref()

sub hashref {
    my $state = {%args};
    $state->{name};
}    # end hashref()

sub moose {
    my $state = MooseState->new(%args);
    $state->name;
    $state->name('james');
}    # end moose()

sub moo {
    my $state = MoState->new(%args);
    $state->name;
    $state->name('james');
}    # end mo()

sub momo {
    my $state = MomoState->new(%args);
    $state->name;
    $state->name('james');
}    # end mo()

