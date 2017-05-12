package TAEB::World::Tile::Stairsup;
use TAEB::OO;
extends 'TAEB::World::Tile::Stairs';

has '+type' => (
    default => 'stairsup',
);

has '+glyph' => (
    default => '<',
);

sub traverse_command { '<' }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

