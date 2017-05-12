use lib 't';
use Test::Chunks;

plan tests => 1;

eval "use TestChunkier";

like("$@", qr{Can't use TestChunkier after using Test::Chunks});
