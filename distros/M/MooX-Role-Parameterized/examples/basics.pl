use v5.12;
use strict;
use warnings;

package Counter;

use Moo::Role;
use MooX::Role::Parameterized;

parameter name => (
    is       => 'ro',
    required => 1,
);

role {
    my ( $params, $mop ) = @_;

    my $name = $params->name;

    $mop->has( $name => ( is => 'rw', default => sub {0} ) );

    $mop->method(
        "increment_$name" => sub {
            my $self = shift;
            $self->$name( $self->$name + 1 );
        }
    );

    $mop->method(
        "reset_$name" => sub {
            my $self = shift;
            $self->$name(0);
        }
    );
};

package Game::Wand;

use Moo;
use MooX::Role::Parameterized::With;

with Counter => { name => 'zapped' };

package main;
use feature 'say';

my $wand = Game::Wand->new;

say 'zapped starts at ', $wand->zapped;
$wand->increment_zapped for 1 .. 3;
say 'after 3 increments: ', $wand->zapped;
$wand->reset_zapped;
say 'after reset: ', $wand->zapped;
