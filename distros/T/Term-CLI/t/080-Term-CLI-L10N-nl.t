#!perl
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use strict 1.00;
use warnings 1.00;

use Test::More 1.001002;
use Term::CLI::L10N;

Term::CLI::L10N->set_language('nl');

my @plural_map = (
    ['gelegenheid' => 'gelegenheden'],

    # vowels should retain "length"
    ['rok'    => 'rokken'],
    ['peer'   => 'peren'],
    ['paar'   => 'paren'],
    ['aap'    => 'apen'],

    # s, f becomes z, v.
    ['neus'   => 'neuzen'],
    ['brief'  => 'brieven'],

    # end "e" or multiple vowels
    ['etalage' => 'etalages'],
    ['bureau' => 'bureaus'],

    # -el -em -en -erd -aar -um
    ['wandelaar' => 'wandelaars'],
    ['lepel'     => 'lepels'],
    ['bofferd'   => 'bofferds'],
    ['nozem'     => 'nozems'],

    # -a -o -u -i -y -> 's
    ['menu'     => "menu's"],
    ['auto'     => "auto's"],
    ['accu'     => "accu's"],
    ['ski'      => "ski's"],
    ['wiskey'   => "wiskey's"],

    # -eur, -foon -> s
    [qw( monteur monteurs )],
    [qw( telefoon telefoons )],
    # -eur -> en
    [qw( kleur kleuren )],

    # professions
    [qw( bankier bankiers )],
    [qw( pastoor pastoors )],

    # foreign words
    [qw( duel duels )],
    [qw( tram trams )],

    # Letters and letter words.
    [qw( cd cd's )],
    [qw( f  f's )],

    # Letters and letter words.
    [qw( ex ex'en )],
    [qw( ls ls'en )],
 
    [qw( vlinder vlinders )],
    [qw( been benen )],

    # Latin
    [qw( museum museums )],
    [qw( aquarium aquariums )],
    [qw( museum musea )],
    [qw( aquarium aquaria )],
    #[qw( stadion stadia )],
    [qw( stadium stadia )],

    [qw( rij rijen )],

    # Exceptions...
    #[qw( ei eieren )],
    #[qw( kind kinderen )],
    #[qw( lam lammeren )],
    #[qw( been beenderen )],
    #[qw( blad bladeren )],
);

is(
    Term::CLI::L10N->handle->numerate(1),
    '',
    "1 x [] -> ''"
);

is(
    Term::CLI::L10N->handle->numerate(2),
    '',
    "2 x [] -> ''"
);

for my $pair (@plural_map) {
    is(
        Term::CLI::L10N->handle->numerate(2, reverse @$pair),
        $$pair[1],
        "2 x [$$pair[1], $$pair[0]] -> $$pair[1]"
    );
    is(
        Term::CLI::L10N->handle->numerate(1, reverse @$pair),
        $$pair[0],
        "1 x [$$pair[1], $$pair[0]] -> $$pair[0]"
    );

    is(
        Term::CLI::L10N->handle->numerate(2, $$pair[1]),
        $$pair[1],
        "2 x $$pair[1] -> $$pair[1]"
    );

    is(
        Term::CLI::L10N->handle->numerate(1, $$pair[1]),
        $$pair[0],
        "1 x $$pair[1] -> $$pair[0]"
    );
}

done_testing();
