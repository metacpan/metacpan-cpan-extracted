package NetHack::Item::Food;
{
  $NetHack::Item::Food::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item';

use constant subtypes => "corpse";
use constant type => "food";

has is_partly_eaten => (
    traits  => [qw/IncorporatesUndef/],
    is      => 'rw',
    isa     => 'Bool',
);

has is_laid_by_you => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has is_custom_fruit => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute => 'is_partly_eaten',
    stat      => 'eaten',
};

with 'NetHack::Item::Role::IncorporatesStats' => {
    attribute => 'is_laid_by_you',
    stat      => 'laid',
};

sub nutrition_per_weight {
    my $self = shift;
    return $self->nutrition_each / $self->weight;
}

after incorporate_stats => sub {
    my $self = shift;
    my $stats = shift;

    $self->is_custom_fruit($stats->{is_custom_fruit});
};

sub nutrition_each {
    return shift->collapse_spoiler_value("nutrition");
}

sub total_nutrition {
    my $self = shift;
    return $self->nutrition_each * $self->quantity;
}

__PACKAGE__->meta->install_spoilers(qw/time vegan vegetarian/);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

