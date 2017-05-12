use Test::Base;

use Template::Plugin::Perl;
use Template;

plan tests => 3 * blocks();

run {
    my $block = shift;
    my $name = $block->name;
    my $tt = Template->new;
    my $template = "[% USE Perl -%]\n" . $block->tt;
    my $output;
    my $res = $tt->process(\$template, {}, \$output);
    ok $res, "$name - process ok";
    $res || warn $tt->error();
    ok defined $output, "$name - output defined";
    if (defined $block->out) {
        is $output, $block->out, "$name - output compare ok";
    } else {
        my $pat = $block->out_like;
        like $output, qr/$pat/s, "$name - output match ok";
    }
};

# unsupported builtins: chomp, chop, pos

__DATA__

=== TEST 1: chr, hex, and index
--- tt
[% Perl.chr(97) %]
[% var = 48; Perl.chr(var) %]

[% Perl.hex(3) %]
[% var = 'a'; Perl.hex(var) %]

[% Perl.index('abcd', 'bc') %]
[% Perl.index('hello, world!', 'l', 4) %]

--- out
a
0

3
10

1
10



=== TEST 2: crypt
--- tt

[% Perl.crypt('a', 3) %]

--- out_like: \S+



=== TEST 3: lc, lcfirst, length, oct, and ord
--- tt
[% Perl.lc('Hello, World') %]
[% Perl.lcfirst('Hello, World') %]

[% Perl.length('ABC') %]
[% Perl.oct('10') %]

[% Perl.ord('a') %]
[% Perl.ord('b') %]

--- out
hello, world
hello, World

3
8

97
98



=== TEST 4: reverse, rindex, sprintf, and substr
--- tt
[% Perl.reverse('hello', 'world').join(': ') %]
[% Perl.rindex('hello', 'l') %]
[% Perl.sprintf("%.02f", 7.82432) %]
[% Perl.substr('hello', 2) %]

--- out
world: hello
3
7.82
llo



=== TEST 5: uc and ucfirst
--- tt
[% Perl.uc('Hello, World') %]
[% Perl.ucfirst('hello, world') %]

--- out
HELLO, WORLD
Hello, world



=== TEST 6: quotemeta, split
--- tt
[% Perl.quotemeta("(hello*)") %]
[% Perl.split(',\s*', 'hello, world').join(':') %]

--- out
\(hello\*\)
hello:world



=== TEST 7: abs
--- tt
[% Perl.abs(-3) %]
[% Perl.abs(0) %]
[% Perl.abs(52) %]

--- out
3
0
52



=== TEST 8: atan2
--- tt
[% Perl.atan2(5, 2) %]

--- out_like: ^1\.1902\d+\n$



=== TEST 9: cos
--- tt
[% Perl.cos(10) %]

--- out_like: ^-0\.83907\d+\n$



=== TEST 10: exp
--- tt
[% Perl.exp(2) %]

--- out_like: ^7\.38905\d+\n$



=== TEST 11: int
--- tt
[% Perl.int(-1.3) %]
[% Perl.int(3.14) %]
[% Perl.int(-532) %]

--- out
-1
3
-532



=== TEST 12: log
--- tt
[% Perl.log(100) %]
--- out_like: ^4\.60517\d+\n$



=== TEST 13: rand and srand
--- tt
[% Perl.srand(0) %] [% Perl.rand(5) %]

--- out_like: ^1 [0-4]\.\d+\n$



=== TEST 14: sin and sqrt
--- tt
[% Perl.sin(52) %] [% Perl.sqrt(2) %]

--- out_like: ^0\.986627\d+ 1\.414\d+\n$



=== TEST 15: join and sort
--- tt
[% Perl.join(',', 'a', 'b', 'c') %]
[% list = ['a', 'b', 'c']; Perl.join(',', list) %]

[% Perl.sort('b', 'c', 'a').join(' ') %]

--- out
a,b,c
a,b,c

a b c



=== TEST 16: eval
--- tt
[% Perl.eval('2**3') %]
[% Perl.eval('qw/hello world/').join(',') %]

--- out
8
hello,world



=== TEST 17: glob
--- tt
[% Perl.glob('t/*.t').join(' ') %]

--- out_like: t/sanity\.t



=== TEST 18: pow
--- tt
[% Perl.pow(2, 3) %]

--- out
8

