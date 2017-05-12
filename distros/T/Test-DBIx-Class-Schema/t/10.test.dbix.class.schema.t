#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

use_ok('Test::DBIx::Class::Schema');

can_ok('Test::DBIx::Class::Schema',
    qw(
        new
        methods
        run_tests
    )
);

my $dbicschematest = Test::DBIx::Class::Schema->new(
    {
        dsn       => 'dbi:Pg:dbname=carrot',
        namespace => 'Carrot::Schema',
        moniker   => 'Juice',
    }
);
isa_ok($dbicschematest, 'Test::DBIx::Class::Schema');
