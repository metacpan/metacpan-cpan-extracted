#!perl -w

use strict;
use Parse::CPAN::Modlist;
use Test::More tests => 13;


my $p;
my $module;

open(DATA, "t/data/03modlist.data") || die "Couldn't open t/data/03modlist.data\n";
my $contents = do { local $/; <DATA> };
close DATA;

ok( $p = Parse::CPAN::Modlist->new($contents), 'Got data from new($data)');

is(scalar $p->modules, 2853, 'Correct number of modules');
ok( $module = $p->module('XML::LibXML'), 'Got module' );

is ($module->name,        'XML::LibXML', 'name');
is ($module->author,      'PHISH',       'author');
is ($module->chapter,     '11',          'chapter');
is ($module->d,           'R',           'd');
is ($module->s,           'm',           's');
is ($module->l,           'h',           'l');
is ($module->i,           'O',           'i');
is ($module->p,           'p',           'p');
is ($module->description, 'Interface to the libxml library', 'description');

is($p->module('Another::Fictional::Module'), undef, 'correctly got undef');
