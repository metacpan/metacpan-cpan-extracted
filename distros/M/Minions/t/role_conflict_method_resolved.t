use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package Camper;

    our %__meta__ = (
        role => 1,
    );

    sub pitch {
        my ($self) = @_;
    }
}

{
    package BaseballPro;

    our %__meta__ = (
        role => 1,
    );

    sub pitch {
        my ($self) = @_;
    }
}

{
    package BusyDudeImpl;

    our %__meta__ = (
        roles => [qw( Camper BaseballPro )],
    );

    sub pitch {
        my ($self) = @_;
        return "I'm so busy";
    }
}

{
    package BusyDude;

    our %__meta__ = (
        interface => [qw( pitch )],
        implementation => 'BusyDudeImpl'
    );
    Minions->minionize;
}

package main;

my $dude = BusyDude->new;
is($dude->pitch, "I'm so busy", '');

done_testing();
