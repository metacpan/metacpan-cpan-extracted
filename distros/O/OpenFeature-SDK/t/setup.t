use v5.36;
use Test::More;

use OpenFeature::SDK;
use OpenFeature::ProviderRegistry;
use OpenFeature::InMemoryProvider;

my $test_sdk = OpenFeature::SDK->new();
my $provider = OpenFeature::InMemoryProvider->new();
my $provider_registry = OpenFeature::ProviderRegistry->new();
$test_sdk->set_provider($provider, 'in-memory');
$test_sdk->set_provider({ foo => 'bar' }, 'test');
$test_sdk->set_provider({ foo => 'baz' });

is($test_sdk->{'provider_registry'}->get_provider('test')->{'foo'}, 'bar', 'TestProvider');
is($test_sdk->{'provider_registry'}->get_default_provider()->{'foo'}, 'baz', 'TestDefaultProvider');

my $in_memory_client = $test_sdk->get_client('in-memory');
is($in_memory_client->get_boolean_value('foo', 1), 0, 'TestWithProvider');
is($in_memory_client->{'domain'}, 'in-memory', 'TestClientDomain');

# Hook stuff doesn't really work yet because I don't know how Perl datastructures work :)
$in_memory_client->add_hooks(['foo', 'bar']);
is($in_memory_client->{'hooks'}[0], 'foo', 'TestHookAddingEmpty');
is($in_memory_client->{'hooks'}[1], 'bar', 'TestHookAddingEmpty');

done_testing();
