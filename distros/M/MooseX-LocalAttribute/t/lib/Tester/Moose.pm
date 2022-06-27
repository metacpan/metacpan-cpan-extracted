package Tester::Moose;
use Moose;

has hashref => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => {
        'change_hashref' => 'set',
    },
    default => sub { return { key => 'value' } },
);

has string => (
    is      => 'rw',
    isa     => 'Str',
    default => 'string',
);

1;
