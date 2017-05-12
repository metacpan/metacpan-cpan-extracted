package NetHack::Item::Potion;
{
  $NetHack::Item::Potion::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item';
with 'NetHack::Item::Role::Lightable';

use constant type => "potion";

has is_diluted => (
    traits  => [qw/IncorporatesUndef/],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub did_dilute_partially {
    my $self = shift;
    $self->is_diluted(1);
}

sub did_dilute_into_water {
    my $self = shift;

    $self->is_uncursed(1);
    $self->is_diluted(0); # water doesn't dilute

    # convert to water
    $self->_clear_tracker;
    $self->appearance("clear potion");
    $self->identity("potion of water");
}

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute => 'is_diluted',
    stat      => 'diluted',
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

