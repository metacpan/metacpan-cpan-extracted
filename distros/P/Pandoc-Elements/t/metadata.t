use strict;
use Test::More 0.96;
use Pandoc::Elements;
use Scalar::Util qw[ blessed reftype ];

# MetaBool

my $doc = pandoc_json(<<JSON);
[ { "unMeta": {
      "true": { "t": "MetaBool", "c": true },
      "false": { "t": "MetaBool", "c": false },
      "string": { "t": "MetaString", "c": "hello\\nworld" },
      "blocks": { "t": "MetaBlocks", "c": [
          {"t": "Para", "c": [{"t":"Str","c":"x"}]},
          {"t": "Para", "c": [{"t":"Str","c":"y"}]}
      ] }
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

# MetaString

is $doc->meta->{string}->content, "hello\nworld";
is $doc->meta->{string}->metavalue, "hello\nworld";

# MetaInlines
{
    my $m = MetaInlines [ Str "foo" ];
    is '{"c":[{"c":"foo","t":"Str"}],"t":"MetaInlines"}',
        $m->to_json, 'MetaInlines';
}

# metavalue

is_deeply $doc->metavalue,
    { false => 0, true => 1, string => "hello\nworld", blocks => [ "x", "y" ] },
    'metavalue';

# Stringify/bless

my $doc = do {
    local (@ARGV, $/) = ('t/documents/meta.json');
    pandoc_json(<>);
};

# note explain $doc->metavalue;

is_deeply { map { $_ => $doc->metavalue($_) } keys %{$doc->meta} },
    $doc->metavalue, 'Document->metavalue';

done_testing;
