package MooseX::SingleArg::Meta::Class;
$MooseX::SingleArg::Meta::Class::VERSION = '0.08';
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
