package NewsExtractor::Types;
use v5.18;

use Importer 'NewsExtractor::Constants' => 'NEWSPAPER_NAMES';

use Type::Library -base;
use Type::Utils -all;
extends "Types::Standard";

declare Text   => as "Str",  where { defined($_) && ($_ eq '' || utf8::is_utf8($_)) };
declare Text1K => as "Text", where { length($_) <= 1024 };
declare Text4K => as "Text", where { length($_) <= 4096 };

enum NewspaperName => NEWSPAPER_NAMES;

1;
