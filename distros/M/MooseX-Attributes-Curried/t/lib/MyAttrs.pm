package MyAttrs;
use MooseX::Attributes::Curried (
    has_str => {
        is  => 'bare',
        isa => 'Str',
    },
    has_int => {
        is      => 'bare',
        isa     => 'Int',
        default => 0,
    },
);

1;

