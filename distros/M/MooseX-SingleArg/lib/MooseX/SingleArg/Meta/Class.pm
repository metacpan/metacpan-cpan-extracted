package # Hide from the indexer for now until docs are added later.
    MooseX::SingleArg::Meta::Class;
use Moose::Role;

has single_arg => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_single_arg',
);

has force_single_arg => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

1;
