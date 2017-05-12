package TestLibrary;
use warnings;
use strict;

use Any::Moose 'X::Types::Moose' => [qw( Str ArrayRef Int )];
use Any::Moose 'X::Types' => [
    -declare => [qw( NonEmptyStr IntArrayRef TwentyThree Foo2Alias )]
];

subtype NonEmptyStr,
    as Str,
    where { length $_ },
    message { 'Str must not be empty' };

coerce NonEmptyStr,
    from Int,
        via { "$_" };

subtype IntArrayRef,
    as ArrayRef,
    where { not grep { $_ !~ /^\d+$/ } @$_ },
    message { 'ArrayRef contains non-Int value' };

coerce IntArrayRef,
    from Int,
        via { [$_] };

subtype TwentyThree,
    as Int,
    where { $_ == 23 },
    message { 'Int is not 23' };

subtype Foo2Alias,
    as Str,
    where { 1 };

1;
