package # HIDE FROM THE CPAN
    Account;
use Moose;

has 'credit_limit' => (
    is => 'rw',
    isa => 'Int',
    default => 0
);

has 'credit_score' => (
    is => 'ro',
    isa => 'Int',
    default => 0
);

1;