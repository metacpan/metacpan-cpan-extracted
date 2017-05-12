use Test::Base;

use Template::Plugin::POSIX;
use Template;

plan tests => 3 * blocks();

run {
    my $block = shift;
    my $name = $block->name;
    my $tt = Template->new;
    my $template = "[% USE POSIX -%]\n" . $block->tt;
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

__DATA__

=== TEST 1: log
--- tt
[% POSIX.log(100) %]

--- out_like: ^4\.605\d+\n$



=== TEST 2: sprintf
--- tt
[% POSIX.sprintf("%.02f", 3.1415926) %]

--- out
3.14



=== TEST 3: pow
--- tt
[% POSIX.pow(2, 3) %]

--- out
8



=== TEST 4: exp
--- tt
[% POSIX.exp(1) %]

--- out_like: ^2\.718\d+$



=== TEST 5: ceil and floor
--- tt
[% POSIX.ceil(3.3) %]
[% POSIX.ceil(3.8) %]

[% POSIX.floor(3.3) %]
[% POSIX.floor(3.8) %]

--- out
4
4

3
3

