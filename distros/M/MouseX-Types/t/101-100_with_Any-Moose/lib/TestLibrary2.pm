package TestLibrary2;

use Any::Moose 'X::Types' => [
    -declare => [qw( MTFNPY NonEmptyStr )]
];
use Any::Moose 'X::Types::Moose' => ['Str'];

subtype MTFNPY,
    as Str,
    where { length $_ },
    message { 'MTFNPY must not be empty' };

subtype NonEmptyStr,
    as Str,
    where { length $_ },
    message { 'Str must not be empty' };

1;
