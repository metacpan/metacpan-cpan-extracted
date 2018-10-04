#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 4;

use Syntax::Construct ();

is(Syntax::Construct::introduced('defined-or'),
   Syntax::Construct::introduced('//'),
   'introduced-alias');

is(Syntax::Construct::removed('lexical-default-variable'),
   Syntax::Construct::removed('lexical-$_'),
   'removed-alias');

my $passes = eval {
    local $] = '5.000';
    Syntax::Construct->import('defined-or');
    1 };
my $error = $passes ? undef : $@;

is($passes, undef, 'alias rejected');
like($error,
     qr/Unsupported construct defined-or at.*Perl 5\.010 needed/,
     'correct error message');
