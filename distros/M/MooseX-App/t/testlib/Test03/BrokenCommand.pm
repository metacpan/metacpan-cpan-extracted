package Test03::BrokenCommand;

use MooseX::App::Command;

option 'conflict1' => (
    is            => 'rw',
    isa           => 'Bool',
    cmd_flag      => 'conflict',
);

option 'conflict2' => (
    is            => 'rw',
    isa           => 'Bool',
    cmd_flag      => 'conflict',
    default       => 1,
);

sub run {
    my ($self) = @_;
}

1;