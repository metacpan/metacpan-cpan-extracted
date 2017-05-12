#!perl -w

use strict;
use Test::More;
use Test::Spelling;

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
Goro Fuji (gfx)
gfuji(at)cpan.org
MouseX::NativeTraits

incrementing
decrementing
Stevan
clearers
cpan
gfx
Num
Str
versa
uniq
indices
dec
kv
isa
arity
metaclass
attr
