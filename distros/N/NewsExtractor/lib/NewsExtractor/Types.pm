package NewsExtractor::Types;
use v5.18;

use Importer 'NewsExtractor::Constants' => 'NEWSPAPER_NAMES';
use Importer Encode => 'is_utf8';

use Type::Library -base;
use Type::Utils -all;
extends "Types::Standard";

declare Text   => as "Str",  where {
    ($_ eq '') || ( is_utf8($_) && ($_ !~ m/[^\P{PosixCntrl}\n]/) )
};

declare Text1K => as "Text", where { length($_) <= 1024 };
declare Text4K => as "Text", where { length($_) <= 4096 };

enum NewspaperName => NEWSPAPER_NAMES;

1;
