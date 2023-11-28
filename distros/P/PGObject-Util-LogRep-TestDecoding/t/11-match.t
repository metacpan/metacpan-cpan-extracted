use Test2::V0 -target => { pkg => 'PGObject::Util::LogRep::TestDecoding' };

plan 6;

ok(my $parser = pkg()->new(schema => ['foo'], tables => ['public.test', 'storage.test']),
    'instantiated parser');

ok($parser->matches('table foo.bar: INSERT:'), 'Schema matches');
ok($parser->matches('table public.test: INSERT:'), 'Table public.test matches');
ok($parser->matches('table storage.test: SOMETHING:'), 'Storage.test matches');
ok(! $parser->matches('table storage.test2: SOMETHING:'), 'Storage.test2 not matched');
ok(! $parser->matches('table foo2.bar: INVALID'), 'foo2.bar does not match');

