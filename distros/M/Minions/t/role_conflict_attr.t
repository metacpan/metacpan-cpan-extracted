use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package Lawyer;

    our %__meta__ = (
        role => 1,
        has  => { clients => { default => sub { [] } } } 
    );
}

{
    package Server;

    our %__meta__ = (
        role => 1,
        has  => { clients => { default => sub { [] } } } 
    );

    sub serve {
        my ($self) = @_;
    }
}

{
    package BusyDudeImpl;

    our %__meta__ = (
        roles => [qw( Lawyer Server )],
    );
}

{
    package BusyDude;

    our %__meta__ = (
        interface => [qw( serve )],
        implementation => 'BusyDudeImpl'
    );
}
package main;

throws_ok {
    Minions->minionize(\ %BusyDude::__meta__);
} qr/Cannot have 'clients' in both Server and Lawyer/;

done_testing();
