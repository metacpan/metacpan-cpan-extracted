package Counter;
use Moo::Role;
use MooX::Role::Parameterized;
use Types::Standard qw( Str );

parameter name => (
    is       => 'ro',    # this is mandatory on Moo
    isa      => Str,     # optional type
    required => 1,       # mark the parameter "name" as "required"
);

role {
    my ( $p, $mop ) = @_;

    my $name = $p->name;    # $p->{name} will also work

    $mop->has(
        $name => (
            is      => 'rw',
            default => sub {0},
        )
    );

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

package MyGame::Weapon;
use Moo;
use MooX::Role::Parameterized::With;

with Counter => {    # injects 'enchantment' attribute and
    name => 'enchantment',    # methods increment_enchantment ( +1 )
};    # reset_enchantment (set to zero)

package MyGame::Wand;
use Moo;
use MooX::Role::Parameterized::With;

with Counter => {    # injects 'zapped' attribute and
    name => 'zapped',    # methods increment_zapped ( +1 )
};    # reset_zapped (set to zero)

package main;
use strict;
use warnings;
use feature qw(say);

my $weapon = MyGame::Weapon->new( enchantment => 5 );
my $wand   = MyGame::Wand->new( zapped => 8 );

say "starting with:";
say "weapon has ", $weapon->enchantment;
say "wand has ",   $wand->zapped;

$weapon->increment_enchantment;
$wand->reset_zapped;

say "";
say "now, have:";
say "weapon has ", $weapon->enchantment;
say "wand has ",   $wand->zapped;

__END__

output:

starting with:
weapon has 5
wand has 8

now, have:
weapon has 6
wand has 0
