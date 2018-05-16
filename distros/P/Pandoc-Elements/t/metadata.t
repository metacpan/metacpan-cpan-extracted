use strict;
use Test::More 0.96;
use Pandoc::Elements;
use Scalar::Util qw[ blessed reftype ];
use JSON::PP;

my $doc = pandoc_json(<<JSON);
[ { "unMeta": {
      "true": { "t": "MetaBool", "c": true },
      "false": { "t": "MetaBool", "c": false },
      "string": { "t": "MetaString", "c": "hello\\nworld" },
      "blocks": { "t": "MetaBlocks", "c": [
          {"t": "Para", "c": [{"t":"Str","c":"x"}]},
          {"t": "Para", "c": [{"t":"Str","c":"y"}]}
      ] },
      "map": { "t": "MetaMap", "c": {
        "string": { "t": "MetaString", "c": "0" },
        "list": { "t": "MetaList", "c": [
            { "t": "MetaString", "c": "a" },
            { "t": "MetaString", "c": "b" },
            { "t": "MetaBool", "c": false }
        ] },
        "/~": { "t": "MetaBool", "c": "true" }
      } }
} }, [] ]
JSON

# MetaBool

ok $doc->meta->{true}->content, 'true';
ok !$doc->meta->{false}->content, 'false';

foreach (1, '1', 'true', 'TRUE', 42, 'wtf') {
    my $m = MetaBool($_);
    ok $m->content;
    is '{"c":true,"t":"MetaBool"}', $m->to_json, "true: $_";
}

foreach (0, '', 'false', 'FALSE', undef) {
    my $m = MetaBool($_);
    ok !$m->content;
    is '{"c":false,"t":"MetaBool"}', $m->to_json, "false: $_";
}

is_deeply $doc->value('/true', boolean => 'JSON::PP'), JSON::PP::true, 'JSON::PP::true'; 
is_deeply $doc->value('/false', boolean => 'JSON::PP'), JSON::PP::false, 'JSON::PP::false'; 

# MetaString

is $doc->meta->{string}->content, "hello\nworld";
is $doc->meta->{string}->value, "hello\nworld";

# MetaInlines
{
    my $m = MetaInlines [ Str "foo" ];
    is '{"c":[{"c":"foo","t":"Str"}],"t":"MetaInlines"}',
        $m->to_json, 'MetaInlines';
    is $m->string, 'foo', 'MetaInlines->string';
}

# MetaBlocks
{
    my $m = MetaBlocks [ Para [ Str "x" ], Para [ Str "y" ] ];
    is $m->string, "x\n\ny", 'MetaBlocks->string';
}

# [meta]value

is_deeply $doc->value, {
    false => 0,
    true => 1,
    string => "hello\nworld",
    blocks => "x\n\ny",
    map => {
        string => "0",
        list => ["a", "b", 0],
        '/~' => 1
    }
  }, 'value';

is $doc->value('false'), 0, 'value("false")';
is $doc->value('/false'), 0, 'value("/false")';
is $doc->value('true'), 1, 'value("true")';
is $doc->value('/true'), 1, 'value("/true")';
is $doc->value('/map/string'), "0", 'value("/map/string")';
is $doc->value('/map/list/0'), "a", 'value("/map/list/0")';
is $doc->value('/map/list/2'), "0", 'value("/map/list/2")';
is $doc->value('string'), "hello\nworld", 'value("string")';
is $doc->value('/string'), "hello\nworld", 'value("/string")';
is_deeply $doc->value('/map/~1~0', boolean => 'JSON::PP'),
    JSON::PP::true, 'value("/map/~1~0")';
is_deeply $doc->value('string', element => 'keep'),
    $doc->meta->{string}->content, 'value("string", elements => keep)';
is_deeply $doc->value('/string', element => 'keep'),
    $doc->meta->{string}->content, 'value("/string", elements => keep)';
is $doc->value('blocks'), "x\n\ny", 'value("blocks")';
is $doc->value('/blocks'), "x\n\ny", 'value("/blocks")';
is_deeply $doc->value('blocks', element => 'keep'),
    $doc->meta->{blocks}->content, 'value("blocks", elements => keep)';
is_deeply $doc->value('/blocks', element => 'keep'),
    $doc->meta->{blocks}->content, 'value("/blocks", elements => keep)';

foreach (qw(x map/x true/x blocks/x map/list/x map/list/3)) {
    is $doc->value($_), undef, "value('$_')";
    is $doc->value($_), undef, "value('/$_')";
}

my $doc = do {
    local (@ARGV, $/) = ('t/documents/meta.json');
    pandoc_json(<>);
};

is_deeply { map { $_ => $doc->metavalue($_) } keys %{$doc->meta} },
    $doc->metavalue, 'Document->metavalue';

done_testing;
