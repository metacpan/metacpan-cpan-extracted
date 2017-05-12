use strict;
use warnings;
use utf8;
use Test::More;
use Spellunker;

my @SRC = (
   'Spellunker->new',
   'Spell::unker->new',
   '$foo->new',
   '$foo->new()',
   '$foo->new(3)',
   '$foo{bar}',
   '%args',
   '@args',
   '$args',
   '\$args',
   '*args',
   '+MyApp::Plugin::FooBar',
   'foo()',
   'foo($x)',
   'foo($x, $y)',
);

for (@SRC) {
    ok(Spellunker::looks_like_perl_code($_), $_);
}

done_testing;

