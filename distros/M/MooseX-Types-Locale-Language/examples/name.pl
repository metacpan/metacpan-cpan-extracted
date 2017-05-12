#!perl

use lib '../lib';

use strict;
use warnings;

use Perl6::Say;

{
    package Foo;

    use Moose;
    use MooseX::Types::Locale::Language qw(
        LanguageName
    );

    has 'name' => (
        is          => 'rw',
        isa         => LanguageName,
        coerce      => 1,
    );

    __PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new(name => 'german');   # (lower case)
say $foo->name;                         # 'German' (canonical case)

eval {
    $foo->name('Spoken in the Tower of Babel');
};
if ($@) {
    say 'Specified language name does not exist';   # Regrettably, true
}
