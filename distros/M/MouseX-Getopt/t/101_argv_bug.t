#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use MouseX::Getopt;

{
    package App;
    use Mouse;

    with 'MouseX::Getopt';

    has 'length' => (
        is      => 'ro',
        isa     => 'Int',
        default => 24,
    );

    has 'verbose' => (
        is     => 'ro',
        isa    => 'Bool',
        default => 0,
    );
    no Mouse;
}

{
    my $app = App->new_with_options(argv => [ '--verbose', '--length', 50 ]);
    isa_ok($app, 'App');

    ok($app->verbose, '... verbosity is turned on as expected');
    is($app->length, 50, '... length is 50 as expected');
}

