#!perl -w

use strict;
use Parse::CPAN::Modlist;
use Test::More tests => 13;


my $p;
my $module;

ok( $p = Parse::CPAN::Modlist->new("t/data/03modlist.data"), 'Got data from new($file)');

is(scalar $p->modules, 2853, 'Correct number of modules');
ok( $module = $p->module('Errno'), 'Got module' );

is ($module->name,        'Errno', 'name');
is ($module->author,      'P5P',   'author');
is ($module->chapter,     '4',     'chapter');
is ($module->d,           'c',     'd');
is ($module->s,           'd',     's');
is ($module->l,           'p',     'l');
is ($module->i,           'f',     'i');
is ($module->p,           '?',     'p');
is ($module->description, 'Constants from errno.h EACCES, ENOENT etc', 'description');

is($p->module('Completely::Madeup::Module'), undef, 'correctly got undef');
