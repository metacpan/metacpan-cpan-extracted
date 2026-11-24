use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use PDL;
use PDL::IO::GGUF qw(rgguf wgguf gguf_header);

my (undef, $path) = tempfile(SUFFIX => '.gguf', UNLINK => 1);

my $w = float([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]);
my $i = long([7, 8, 9]);

ok(wgguf($path, { 'layer.weight' => $w, 'layer.idx' => $i }, { 'general.architecture' => 'llama', 'llama.block_count' => 12 }), 'wgguf succeeded');

my $hdr = gguf_header($path);
is($hdr->{version}, 3, 'GGUF v3');
is($hdr->{metadata}{'general.architecture'}, 'llama', 'string metadata round-tripped');
is($hdr->{metadata}{'llama.block_count'}, 12, 'uint32 metadata round-tripped');

my ($loaded, $meta) = rgguf($path);
is_deeply([ $loaded->{'layer.weight'}->dims ], [ $w->dims ], 'weight dims match');
ok(all(approx($loaded->{'layer.weight'}, $w)), 'weight values match');
ok(all($loaded->{'layer.idx'} == $i), 'idx values match');
is($meta->{'general.architecture'}, 'llama', 'list-context metadata returned');

done_testing();
