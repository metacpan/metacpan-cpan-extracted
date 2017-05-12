#!perl

use MongoDBx::KeyValue;
use Test::More tests => 7;

my $mkv;
eval { $mkv = MongoDBx::KeyValue->new };

ok($@ =~ m/You must provide the name of the key-value database to use/, 'new() fails when kvdb is not provided');

eval { $mkv = MongoDBx::KeyValue->new(kvdb => 'mongodbx_keyvalue_test') };

SKIP: {
	skip "MongoDB needs to be running for this test.", 6 if $@;

	ok($mkv->set('cache', 'index.html', '<html><head><title>Index</title></head><body>Index</body></html>'), 'html set returned success');

	is($mkv->get('cache', 'index.html'), '<html><head><title>Index</title></head><body>Index</body></html>', 'html get returned what was expected');

	ok($mkv->set('cache', 'index.html', 'removed'), 'html set #2 returned success');

	is($mkv->get('cache', 'index.html'), 'removed', 'html get #2 returned what was expected');

	ok($mkv->set('docs', 'some_doc', { string => 'asdf', integer => 123 }), 'doc set returned success');

	is_deeply($mkv->get('docs', 'some_doc'), { string => 'asdf', integer => 123 }, 'doc get returned success');

	$mkv->db->drop;
}

done_testing();
