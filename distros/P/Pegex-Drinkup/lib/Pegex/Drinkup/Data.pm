package Pegex::Drinkup::Data;
use Pegex::Base;
extends 'Pegex::Tree';

my $data;

sub initial {
    $data = {};
}

sub got_cocktail {
    $data->{name} = $_[1];
}

sub got_description {
    $data->{description} = $_[1];
}

sub got_instructions {
    $data->{instructions} = $_[1];
}

sub got_ingredients {
    $data->{ingredients} = [
        map {
            my $ingredient = {
               amount => 0 + $_->[0],
               unit => $_->[1],
               ingredient => $_->[2],
            };
            $ingredient->{note} = $_->[3] if $_->[3];
            $ingredient;
        } @{$_[1]}
    ];
}

sub got_metadata {
    $data->{lc $_[1]->[0]} = $_[1]->[1]
}

sub final {
    return $data;
}

1;
