use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile('my $a = <a b c>; $a[0]'), 'a';
is compile('my @a = <a b c>; @a[0]'), 'a';
is compile('my @a; @a = <a b c>; @a[0]'), 'a';
is compile('my $a; $a = <a b c>; $a[0]'), 'a';
is compile(q!['a', <2 three>].elems!), 3;
is compile(q!my $c = [[1], [2], [3]].map( { $_ } );$c.elems!), 3;
is compile(q!(<a b c d>.keys)[2]!), 2;
ok !compile(q!<>.Bool!);
ok compile(q!<a>.Bool!);
ok compile(q!<a>.exists(0)!);
ok !compile(q!<a>.exists(1)!);
ok compile(q!<a b c d>.exists(0)!);
ok compile(q!<a b c d>.exists(1)!);
ok compile(q!<a b c d>.exists(2)!);
ok compile(q!<a b c d>.exists(3)!);
ok !compile(q!<a b c d>.exists(4)!);
ok !compile(q!<a b c d>.exists(5)!);
is_deeply compile(q![<d a c b>].sort!), [qw(a b c d)];
is compile(q!my @a=<a b c d>; push @a, 'e'; @a.join(" ")!), 'a b c d e';
is compile(q!my @a=<a b c d>; ~@a!), 'a b c d';
is compile(q!~<a b c d>;!), 'a b c d';
is compile(q!+<a b c d>;!), 4;
is compile(q!my $a=[<a b c d>]; ~$a!), 'a b c d';
is compile(q!my $a=[<a b c d>]; +$a!), 4;

done_testing;

