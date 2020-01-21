use Test::More tests => 1;

package Foo;
use Mo 'xxx';

has 'stuff';

sub hmm { XXX @_ }

package main;

my $f = Foo->new(stuff => 'turkey');

eval { $f->hmm };

like $@, qr!---.*stuff: turkey!s, 'Error with yaml';
