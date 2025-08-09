package MooTest;

use Moo '1.006000';

use if $ENV{MOOX_CONST_TYPE_TINY}, 'MooX::TypeTiny';

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
    coerce  => sub { ref( $_[0] ) ? $_[0] : [ $_[0] ] }
);

has baz => (
    is  => 'const',
    isa => Int,
);

has bo => (
    is  => 'once',
    isa => HashRef,
);

has bop => (
    is      => 'const',
    isa     => HashRef[Int],
    default => sub { { x => 1 } },
);

has cr => (
    is  => 'ro',
    isa => sub { die "ouch" unless $_[0] && $_[0] !~ /^0/ },
);

1;
