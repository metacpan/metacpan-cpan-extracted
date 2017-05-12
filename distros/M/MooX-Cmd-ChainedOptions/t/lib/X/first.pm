package X::first;

use Moo;
use MooX::Cmd base => 'XX';
use MooX::Cmd::ChainedOptions;

option first_opt => (
    is      => 'ro',
    format  => 's',
    default => 'first_opt_v',
);

sub execute { return $_[0] }

1;
