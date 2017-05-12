use warnings FATAL => 'all';
use strict;
use utf8;

use Test::More tests => 6;

use Quote::Ref;

is_deeply qwa∘foo bar baz∘, [qw∘foo bar baz∘];
is_deeply qwh∘foo bar baz "∘, {qw∘foo bar baz "∘};

is_deeply qwa∘foo ∞ ♥ bar∘, [qw∘foo ∞ ♥ bar∘];
is_deeply qwh∘foo ∞ ♥ bar∘, {qw∘foo ∞ ♥ bar∘};

is_deeply qwa∘\\\∘ \\ \∘ \\∘, [qw∘\\\∘ \\ \∘ \\∘];
is_deeply qwh∘\\\∘ \\ \∘ \\∘, {qw∘\\\∘ \\ \∘ \\∘};
