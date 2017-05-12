#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Any::Moose 'X::Types::Moose' => [':all', 'Bool'];

my @types = any_moose('X::Types::Moose')->type_names;

plan tests => @types * 3;

for my $t (@types) {
    ok my $code = __PACKAGE__->can($t), "$t() was exported";
    if ($code) {
        is $code->(), $t, "$t() returns '$t'";
    }
    else {
        diag "Skipping $t() call test";
    }
    local $TODO = 'is_T is not supported by MouseX::Types';
    ok __PACKAGE__->can("is_$t"), "is_$t() was exported";
}
