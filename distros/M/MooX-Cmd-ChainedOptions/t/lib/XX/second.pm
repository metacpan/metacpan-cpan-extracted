package XX::second;

use Moo;
use MooX::Cmd;
use MooX::Cmd::ChainedOptions;

option second_opt => (
    is      => 'ro',
    format  => 's',
    default => 'second_opt_v',
);

sub execute { return $_[0] }

1;
