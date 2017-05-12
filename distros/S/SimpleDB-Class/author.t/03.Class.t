use Test::More tests => 2;
use lib '../lib';

use_ok('SimpleDB::Class');

my $access = $ENV{AWS_ACCESS_KEY};
my $secret = $ENV{AWS_SECRET_ACCESS_KEY};

my $db = SimpleDB::Class->new(secret_key=>$secret, access_key=>$access, cache_servers=>[{host=>'127.0.0.1', port=>11211}]);
my $domains = $db->list_domains;

is(ref $domains, 'ARRAY', 'list_domains returns an array ref');


