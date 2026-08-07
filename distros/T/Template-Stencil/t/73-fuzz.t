#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

# Deterministic-seed fuzz: every input must either compile+render or
# croak cleanly - never crash, hang, or corrupt. A short bounded run
# lives here; the long run is xt/author/fuzz-long.t. Inputs that ever
# broke the compiler get committed to t/corpus/fuzz/ and are always
# replayed first.

my $s = Template::Stencil->new;
my $data = {
    a => 1, b => 'x', v => [1, 2], h => { k => 'v' },
    loop => 'shadow', items => [ { inner => [1] } ],
};

sub try_one {
    my ($src) = @_;
    my $ok = eval { $s->render($src, $data); 1 };
    return $ok || $@ =~ /^Template::Stencil: /;
}

# Replay the committed corpus of previously-found bad inputs.
my @corpus = glob 't/corpus/fuzz/*';
for my $f (@corpus) {
    open my $fh, '<', $f or die $!;
    my $src = do { local $/; <$fh> };
    ok(try_one($src), "corpus: $f");
}
pass('corpus empty so far') unless @corpus;

# Random byte soup.
srand 424242;
my @bytes = map { chr } 0 .. 255;
my $fails = 0;
for my $i (1 .. 300) {
    my $len = int rand 200;
    my $src = join '', map { $bytes[rand @bytes] } 1 .. $len;
    $fails++ unless try_one($src);
}
is($fails, 0, '300 random byte strings handled');

# Tag soup: random sequences of grammar fragments.
my @frag = (
    '{%', '%}', '{% if ', '{% end %}', '{% for ', ' in ', '{% set ',
    ' = ', '{% include ', '{%#', '{%%}', '{% raw ', '| upper', '|',
    'a.b', '[0]', 'a', '&&', '||', '==', 'eq', '(', ')', "'q'", '"x"',
    '1.5', 'defined(', 'undef', '{% elsif ', '{% else %}',
    '{% content %}', 'text ', "\n", '.', ',',
);
$fails = 0;
for my $i (1 .. 300) {
    my $n = 1 + int rand 25;
    my $src = join '', map { $frag[rand @frag] } 1 .. $n;
    $fails++ unless try_one($src);
}
is($fails, 0, '300 tag-soup strings handled');

done_testing;
