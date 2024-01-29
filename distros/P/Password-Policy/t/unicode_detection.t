use strict;
use warnings;
use utf8;

use Test::More tests => 4;
use Test::Fatal 'lives_ok';

use Password::Policy::Rule::Length;
use Encode 'encode';

my $pw = 'οМΛʊώȯŨͲĔʨҚҠԾǔǶՍŎѢʯΝ';
my $len = length $pw;
my $rule = Password::Policy::Rule::Length->new (10);
is $len, 20, 'Standard len is correct';
lives_ok { $rule->check ($pw) } '20-char *decoded* pw is long enough';

my $encpw = encode ('UTF-8', $pw, Encode::FB_CROAK);
my $strmb = String::Multibyte->new ('UTF8');
my $mblen = $strmb->length ($encpw);
is $mblen, 20, 'Multibyte len is correct';
is $rule->check ($encpw), 1, '20-char *encoded* pw is long enough';