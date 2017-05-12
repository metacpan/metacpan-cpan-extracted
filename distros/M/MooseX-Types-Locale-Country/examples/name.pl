#!perl

use lib '../lib';

use strict;
use warnings;

use Perl6::Say;

{
    package Foo;

    use Moose;
    use MooseX::Types::Locale::Country qw(
        CountryName
    );

    has 'name' => (
        is          => 'rw',
        isa         => CountryName,
        coerce      => 1,
    );

    __PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new(name => 'germany');  # (lower case)
say $foo->name;                         # 'Germany' (canonical case)

$foo->name('United States of America'); # (alias name)
say $foo->name;                         # 'United States' (canonical name)

eval {
    $foo->name('Programming Republic of Perl');
};
if ($@) {
    say 'Specified country name does not exist';    # Regrettably, true
}
