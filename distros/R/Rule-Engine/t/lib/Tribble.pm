package # HIDE FROM THE CPAN
    Tribble;
use Moose;

has 'favorite_temp' => (
    is => 'ro',
    isa => 'Int',
    default => 65
);

has 'happy' => (
    is => 'rw',
    isa => 'Bool',
    default => 0
);

1;