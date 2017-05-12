#!perl

use lib '../lib';

use strict;
use warnings;

use Perl6::Say;

{
    package Foo;

    use Moose;
    use MooseX::Types::Locale::Country qw(
        NumericCountry
    );

    has 'numeric' => (
        is          => 'rw',
        isa         => NumericCountry,
        coerce      => 1,
    );

    __PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new(numeric => 392);
say $foo->numeric;                      # 392

eval {
    $foo->numeric(9999);
};
if ($@) {
    say 'Specified country code does not exist';    # true
}
