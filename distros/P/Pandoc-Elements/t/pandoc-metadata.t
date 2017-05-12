use strict;
use Test::More;
use Pandoc::Elements;
use JSON;

is_deeply metadata 'foo', MetaString 'foo';
is_deeply metadata undef, MetaString '';
is_deeply metadata JSON::true(), MetaBool 1;
is_deeply metadata JSON::false(), MetaBool 0;
is_deeply metadata ['foo'], MetaList [ MetaString 'foo' ];
is_deeply metadata { x => [1] }, MetaMap { x => MetaList [ MetaString '1' ] };

is_deeply metadata MetaString 'foo', MetaString 'foo';
is_deeply metadata Str 'ä', MetaInlines [ Str 'ä' ];
is_deeply metadata Para [ Str 'ä' ], MetaBlocks [ Para [ Str 'ä' ] ];

my $ref = \''; 
is_deeply metadata $ref, MetaString "$ref";
$ref = bless {}, 'Pandoc::Elements';
is_deeply metadata $ref, MetaString "$ref";

done_testing;
