#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exports;

my $RT = "Readonly::Tiny";

require_ok $RT or BAIL_OUT "Module will not load!";

import_ok $RT, [],              "default import OK";
is_import qw/readonly/, $RT,    "default imports readonly";
cant_ok qw/readwrite Readonly/, "default only imports readonly";

my @all = qw/readonly readwrite Readonly/;

new_import_pkg;
import_ok $RT, \@all,           "explicit import OK";
is_import @all, $RT,            "explicit import succeeds";

Test::More->builder->is_passing
    or BAIL_OUT "Module will not load!";

done_testing;
