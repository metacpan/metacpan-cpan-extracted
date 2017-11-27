#!/usr/bin/perl

#
# Copyright (C) 2017 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended 0.000058;
use File::FindStrings::Boilerplate 'script';

use File::FindStrings qw(find_words_in_file find_words_in_string);
use Perl6::Slurp;

MAIN: {
    my (@tests) = (
        {
            file    => 't/data/empty.txt',
            words   => [],
            results => [],
            note    => 'Empty file search with empty word list works',
        },
        {
            file    => 't/data/empty.txt',
            words   => ['teststring'],
            results => [],
            note    => 'Empty file search with word works',
        },
        {
            file    => 't/data/Boilerplate.txt',
            words   => ['teststring'],
            results => [],
            note    => 'Perl file search with non-found word works',
        },
        {
            file    => 't/data/Boilerplate.txt',
            words   => [ 'teststring', 'Bogusstring' ],
            results => [],
            note    => 'Perl file search with non-found word list works',
        },
        {
            file    => 't/data/Boilerplate.txt',
            words   => ['Joel'],
            results => [],
            note    => 'Perl file search with a substring work gives expected result',
        },
        {
            file    => 't/data/Boilerplate.txt',
            words   => [ 'Joel', 'Joelle' ],
            results => [ { word => 'Joelle', line => 2 } ],
            note    => 'Perl file search with a found word works',
        },
        {
            file    => 't/data/Boilerplate.txt',
            words   => [ 'Joel', 'Joelle', 'Maslak' ],
            results => [ { word => 'Joelle', line => 2 }, { word => 'Maslak', line => 2 }, ],
            note    => 'Perl file search with a found words works',
        },
        {
            file    => 't/data/Boilerplate.txt',
            words   => [ 'This', 'Joelle', 'Maslak' ],
            results => [
                { word => 'Joelle', line => 2 },
                { word => 'Maslak', line => 2 },
                { word => 'This',   line => 15 },
                { word => 'This',   line => 18 },
                { word => 'This',   line => 21 },
                { word => 'This',   line => 27 },
                { word => 'This',   line => 29 },
                { word => 'This',   line => 32 },
                { word => 'This',   line => 78 },
            ],
            note => 'Perl file search with a found words works',
        },
    );

    foreach my $test (@tests) {
        my (@results) = find_words_in_file( $test->{file}, $test->{words}->@* );
        is( \@results, $test->{results}, $test->{note} );
    }

    foreach my $test (@tests) {
        my $string = slurp($test->{file});
        my (@results) = find_words_in_string( $string, $test->{words}->@* );
        is( \@results, $test->{results}, 'String form: ' . $test->{note} );
    }

    done_testing;
}

1;

