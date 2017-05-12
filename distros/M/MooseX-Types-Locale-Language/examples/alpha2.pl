#!perl

use lib '../lib';

use strict;
use warnings;

use Perl6::Say;

{
    package Foo;

    use Moose;
    use MooseX::Types::Locale::Language qw(
        Alpha2Language
    );

    has 'alpha2' => (
        is          => 'rw',
        isa         => Alpha2Language,  # same as 'LanguageCode' subtype
        coerce      => 1,
    );

    __PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new(alpha2 => 'JA');     # (upper case)
say $foo->alpha2;                       # 'ja' (lower case, recommended)

eval {
    $foo->alpha2('foobar');
};
if ($@) {
    say 'Specified language code does not exist';   # true
}
