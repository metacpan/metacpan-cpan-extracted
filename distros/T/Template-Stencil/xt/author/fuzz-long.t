#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

# Long-run fuzz for author testing: many seeds, bigger inputs.
# Run with: prove -b xt/author/fuzz-long.t

my $s = Template::Stencil->new;
my $data = {
    a => 1, b => 'x', v => [1, 2], h => { k => 'v' },
    items => [ { inner => [1, 2] } ],
};

sub try_one {
    my ($src) = @_;
    my $ok = eval { $s->render($src, $data); 1 };
    return $ok || $@ =~ /^Template::Stencil: /;
}

my @frag = (
    '{%', '%}', '{% if ', '{% end %}', '{% for ', ' in ', '{% set ',
    ' = ', '{% include ', '{%#', '{%%}', '{% raw ', '| upper',
    '| default(', '|', 'a.b.c', '[0]', '[12]', 'a', '&&', '||', '==',
    '!=', '<=', 'eq', 'ne', 'lt', '(', ')', "'q'", '"x\\\"y"', '1.5',
    '-2', 'defined(', 'undef', 'not ', '!', '{% elsif ', '{% else %}',
    '{% unless ', '{% content %}', 'text ', "\n", '.', ',', '  ',
);

my $fails = 0;
for my $seed (1 .. 50) {
    srand $seed;
    for (1 .. 400) {
        my $len = int rand 2000;
        my $src = join '', map { chr int rand 256 } 1 .. $len;
        $fails++ unless try_one($src);
    }
    for (1 .. 400) {
        my $n = 1 + int rand 60;
        my $src = join '', map { $frag[rand @frag] } 1 .. $n;
        $fails++ unless try_one($src);
    }
}
is($fails, 0, '40k fuzz inputs handled cleanly');

done_testing;
