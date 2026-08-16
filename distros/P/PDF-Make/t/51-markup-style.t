#!perl

# Attributes, values and inheritance.
#
# The bias throughout is that a mistake in a template is worth an exception
# with a position, never a default. A silently ignored attribute is how a
# document ends up subtly wrong on somebody's desk, which costs far more than
# a render that refuses to start.

use strict;
use warnings;
use Test::More;
use PDF::Make::Markup::Parse;
use PDF::Make::Markup::Style;

my $S = 'PDF::Make::Markup::Style';

sub root { return PDF::Make::Markup::Parse->parse($_[0]) }

sub node {
    my ($markup) = @_;
    my $root = root($markup);
    return $root->{children}[0] || $root;
}

# ---- values -----------------------------------------------------------------

subtest 'colours normalise to #rrggbb' => sub {
    is $S->colour('#abc'),    '#aabbcc', 'three digits expand';
    is $S->colour('#AABBCC'), '#aabbcc', 'six digits lowercase';
    is $S->colour('red'),     '#ff0000', 'a name';
    is $S->colour('Grey'),    '#808080', 'case-insensitive, and grey is spelt both ways';
    is $S->colour('gray'),    '#808080', '  including the other one';

    for my $bad ('#ab', '#abcd', 'reddish', '', 'rgb(1,2,3)', '#gggggg') {
        eval { $S->colour($bad) };
        like $@, qr/is not a colour/, "'$bad' is refused";
    }
};

subtest 'lengths are points' => sub {
    is $S->length_pt('12'),    12,   'a number';
    is $S->length_pt('12pt'),  12,   'pt is tolerated';
    is $S->length_pt('0.5'),   0.5,  'fractional';
    is $S->length_pt('-3'),    -3,   'negative';
    for my $bad ('12px', '1em', '50%', 'wide', '') {
        eval { $S->length_pt($bad) };
        like $@, qr/is not a number of points/, "'$bad' is refused";
    }
};

subtest 'booleans are written, not guessed' => sub {
    is $S->boolean($_), 1, "'$_' is true"  for qw(1 true yes on TRUE Yes);
    is $S->boolean($_), 0, "'$_' is false" for qw(0 false no off FALSE No);
    for my $bad ('maybe', '2', '', 'y') {
        eval { $S->boolean($bad) };
        like $@, qr/is not a yes or no/, "'$bad' is refused";
    }
};

# ---- attributes -------------------------------------------------------------

subtest 'an element validates and coerces its own attributes' => sub {
    my $n = node('<doc><h1 size="20" color="#1a1a2e" align="centre">x</h1></doc>');
    my $s = $S->attrs($n);
    is $s->{size}, 20, 'size coerced to a number';
    is $s->{colour}, '#1a1a2e', 'color spelt the other way still lands on colour';
    is $s->{align}, 'center', 'centre normalises to center';
};

subtest 'unknown and misplaced attributes are errors with a position' => sub {
    my $n = node(qq{<doc>\n  <h1 colr="#fff">x</h1>\n</doc>});
    eval { $S->attrs($n) };
    like $@, qr/unknown attribute 'colr' on <h1> at line 2, column 3/,
        'a typo is named, with where it is';

    $n = node('<doc><h1 weight="2">x</h1></doc>');
    eval { $S->attrs($n) };
    like $@, qr/<h1> does not take 'weight'/,
        'an attribute the tag cannot act on is refused';
    like $@, qr/it takes: align, bold, colour/,
        '  and the message lists what it does take';

    $n = node('<doc><cell pad="lots">x</cell></doc>');
    eval { $S->attrs($n) };
    like $@, qr/pad 'lots' is not a number of points/, 'a bad value is named';
};

subtest 'page size and font size do not share a name' => sub {
    my $n = root('<doc page-size="A4" margin="36"><h1 size="20">x</h1></doc>');
    my $s = $S->attrs($n);
    is $s->{'page-size'}, 'A4', 'doc takes page-size';
    is $s->{margin}, 36, 'and a margin';

    $n = root('<doc size="A4"></doc>');
    eval { $S->attrs($n) };
    like $@, qr/size 'A4' is not a number of points/,
        'size on doc is a font size, so a page name is refused there'
        or diag $@;
};

# ---- style declarations -----------------------------------------------------

subtest 'style entries parse as name:value lists' => sub {
    my $n = node('<doc><style/></doc>');
    my $d = $S->declarations('size:20; colour:#1a1a2e;bold:1', $n, 'h1');
    is $d->{size}, 20, 'size';
    is $d->{colour}, '#1a1a2e', 'colour';
    is $d->{bold}, 1, 'bold';

    is_deeply $S->declarations('', $n, 'text'), {}, 'an empty list is empty';
    is_deeply $S->declarations('  ;; ', $n, 'text'), {}, 'so is a list of nothing';

    eval { $S->declarations('size 20', $n, 'h1') };
    like $@, qr/is not name:value/, 'a missing colon is an error';

    eval { $S->declarations('size:20', $n, 'nope') };
    like $@, qr/no such tag '<nope>' in <style>/, 'an unknown tag is an error';

    eval { $S->declarations('weight:2', $n, 'text') };
    like $@, qr/'weight' does not apply to <text>/,
        'a property the tag cannot use is an error';
};

# ---- inheritance ------------------------------------------------------------

subtest 'text properties inherit, box properties do not' => sub {
    my $parent = { size => 10, colour => '#333333', pad => 8, bg => '#eeeeee',
                   weight => 2, align => 'right' };
    my $child  = $S->inherit($parent, { size => 12 });

    is $child->{size}, 12, 'own value wins';
    is $child->{colour}, '#333333', 'colour inherited';
    is $child->{align}, 'right', 'align inherited';
    ok !exists $child->{pad},    'padding does not leak into children';
    ok !exists $child->{bg},     'nor background';
    ok !exists $child->{weight}, 'nor weight';

    my $grand = $S->inherit($child, {});
    is $grand->{size}, 12, 'inheritance is transitive';
    is $grand->{colour}, '#333333', '  for every inherited property';
};

subtest 'font_args names things the way Builder::Font does' => sub {
    my $f = $S->font_args({ size => 11, colour => '#001122', font => 'Times',
                            bold => 1, 'line-height' => 14, pad => 6 });
    is_deeply $f, { size => 11, colour => '#001122', family => 'Times',
                    bold => 1, line_height => 14 },
        'renamed, and box properties left out';
};

# ---- the table is the documentation -----------------------------------------

subtest 'every tag the parser knows has an entry here' => sub {
    for my $t (PDF::Make::Markup::Parse->tags) {
        ok defined $S->allowed($t->{name}),
            "<$t->{name}> has an attribute set";
    }
};

subtest 'every allowed attribute is a real property' => sub {
    my $props = $S->properties;
    for my $t (PDF::Make::Markup::Parse->tags) {
        my $allow = $S->allowed($t->{name}) or next;
        for my $a (@$allow) {
            ok $props->{$a}, "<$t->{name}> allows '$a', which is a property";
        }
    }
};

done_testing;
