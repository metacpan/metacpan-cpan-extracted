package MooTest;

use Moo '1.006000';

use MooX::Const;
use Types::Standard -types;

use namespace::autoclean;

has foo => (
    is      => 'ro',
    isa     => ArrayRef[Int],
    default => sub { [1] },
);

has bar => (
    is      => 'const',
    isa     => ArrayRef[Int],
    default => sub { [1] },
);

has baz => (
    is  => 'const',
    isa => Int,
);

has bo => (
    is  => 'wo',
    isa => HashRef,
);

1;
