#!perl

use lib '../lib';

use strict;
use warnings;

use Perl6::Say;

{
    package Foo;

    use Moose;
    use MooseX::Types::Locale::Country qw(
        Alpha2Country
    );

    has 'alpha2' => (
        is          => 'rw',
        isa         => Alpha2Country,   # same as 'CountryCode' subtype
        coerce      => 1,
    );

    __PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new(alpha2 => 'jp');     # (lower case)
say $foo->alpha2;                       # 'JP' (upper case, recommended)

eval {
    $foo->alpha2('foobar');
};
if ($@) {
    say 'Specified country code does not exist';    # true
}
