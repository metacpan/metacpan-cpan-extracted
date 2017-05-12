use strict;
use warnings;

use Test::More;
use Dir::Self;
use Net::Async::SPORE::Loader;

can_ok('Net::Async::SPORE::Loader', qw(new new_from_file));

ok(!Sample::API->can('new'), 'start out without the class');
my $api = Net::Async::SPORE::Loader->new_from_file(
	__DIR__ . '/sample.json',
	class => 'Sample::API'
);
can_ok('Sample::API', 'new');

done_testing;

