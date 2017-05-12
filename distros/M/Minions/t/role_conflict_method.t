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
}

{
    package BusyDude;

    our %__meta__ = (
        interface => [qw( pitch )],
        implementation => 'BusyDudeImpl'
    );
}
package main;

throws_ok {
    Minions->minionize(\ %BusyDude::__meta__);
} qr/Cannot have 'pitch' in both BaseballPro and Camper/;

done_testing();
