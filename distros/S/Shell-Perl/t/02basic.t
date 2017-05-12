#!perl -T

use Test::More tests => 3;

BEGIN { use_ok('Shell::Perl'); }

my $sh = Shell::Perl->new();
ok($sh, 'defined return of new()');
isa_ok($sh, 'Shell::Perl');


