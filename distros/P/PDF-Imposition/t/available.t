#!perl

use strict;
use warnings;
use Test::More;
use PDF::Imposition;

my @schemas = PDF::Imposition->available_schemas;

plan tests => scalar(@schemas) + 1;

foreach my $schema (@schemas) {
    ok(PDF::Imposition->new(schema => $schema), "$schema loaded");
}

eval {
    PDF::Imposition->new(schema => 'pippo');
};
ok ($@, "pippo failed");

