use Test::Chunks;

if (eval("require YAML; 1")) {
    plan tests => 1 * chunks;
}
else {
    plan skip_all => "YAML.pm required for this test"; exit;
}

my ($chunk) = chunks;

eval {
    XXX($chunk->text)
};
is $@, $chunk->xxx, $chunk->name;

__DATA__
=== XXX Test
--- text eval
+{ foo => 'bar' }
--- xxx
---
foo: bar
...
  at t/xxx.t line 13
