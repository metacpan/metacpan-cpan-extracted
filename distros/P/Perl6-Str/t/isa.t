use strict;
use warnings;
use Test::More tests => 14;
use lib '../lib';
use lib 'lib';

use Perl6::Str;

my $s = Perl6::Str->new('the brown fox');

isa_ok $s,              'Perl6::Str';
isa_ok $s->uc,          'Perl6::Str';
isa_ok $s->lc,          'Perl6::Str';
isa_ok $s->ucfirst,     'Perl6::Str';
isa_ok $s->lcfirst,     'Perl6::Str';
isa_ok $s->capitalize,  'Perl6::Str';
isa_ok $s->reverse,     'Perl6::Str';
isa_ok $s->chop,        'Perl6::Str';
isa_ok $s->chomp,       'Perl6::Str';
isa_ok $s->substr(0),   'Perl6::Str';
isa_ok $s->substr(0, 1),        'Perl6::Str';
isa_ok $s->substr(0, 1, '--'),  'Perl6::Str';
isa_ok $s->samecase('Abc'),     'Perl6::Str';
isa_ok $s->sameaccent('Abc'),   'Perl6::Str';
