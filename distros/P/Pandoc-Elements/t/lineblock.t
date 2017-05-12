use strict;
use Test::More;
use Pandoc::Elements;
use JSON;

# internal representation
my $lineblock = LineBlock [ [ Str "  foo"], [ Str "bar"], [ Str " baz"], ];
ok $lineblock->is_block, 'is_block';

{
    local $Pandoc::Elements::PANDOC_VERSION = '1.16';
    my $expect = {
        t => 'Para',
        c => [
            { 'c' => "\x{a0}\x{a0}foo", 't' => 'Str' },
            { 'c' => [],                't' => 'LineBreak' },
            { 'c' => "bar",             't' => 'Str' },
            { 'c' => [],                't' => 'LineBreak' },
            { 'c' => "\x{a0}baz",       't' => 'Str' }
        ]
    };
    is_deeply $expect, decode_json($lineblock->to_json), 'PANDOC_VERSION < 1.18';
}

{
    local $Pandoc::Elements::PANDOC_VERSION = '1.18';
    my $expect = {
        t => 'LineBlock',
        c => [
            [ { 'c' => "\x{a0}\x{a0}foo", 't' => 'Str' } ],
            [ { 'c' => "bar",             't' => 'Str' } ],
            [ { 'c' => "\x{a0}baz",       't' => 'Str' } ]
        ]
    };
    is_deeply $expect, decode_json($lineblock->to_json), 'PANDOC_VERSION >= 1.18';
}

done_testing;
