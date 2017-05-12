#!perl

use lib '../lib';

use strict;
use warnings;

use Perl6::Say;

{
    package Foo;

    use Moose;
    use MooseX::Types::Locale::Country qw(
        Alpha3Country
    );

    has 'alpha3' => (
        is          => 'rw',
        isa         => Alpha3Country,
        coerce      => 1,
    );

    __PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new(alpha3 => 'jpn');    # (lower case)
say $foo->alpha3;                       # 'JPN' (upper case, recommended)

eval {
    $foo->alpha3('foobar');
};
if ($@) {
    say 'Specified country code does not exist';    # true
}
