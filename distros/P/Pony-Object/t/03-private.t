#!/usr/bin/env perl

use lib './lib';
use lib './t';

use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 4;

use Private::Ancestor;
use Private::Descendant;

my $a = Private::Ancestor->new;
my $d = Private::Descendant->new;

ok($a->some_public eq 'public calls private', 'regular public');
ok($d->some_public eq 'public calls private', 'public calls private');
eval { $d->mine_public };
ok($@, 'from current class');
ok($d->ok_public eq 'public calls public calls private', 'public calls public calls private');

diag( "Testing private for Pony::Object $Pony::Object::VERSION" );