package MooseTest;

use Moose;

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

has bop => (
    is      => 'const',
    isa     => HashRef[Int],
    default => sub { { x => 1 } },
);

__PACKAGE__->meta->make_immutable();
