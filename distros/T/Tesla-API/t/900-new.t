use warnings;
use strict;

use Mock::Sub;
use Tesla::API;
use Test::More;

my $ms = Mock::Sub->new;

my $token_sub = $ms->mock('Tesla::API::_access_token');

my %params = (
    api_cache_persist   => 1,
    api_cache_time      => 400
);

my $t= Tesla::API->new(%params);

is ref($t), 'Tesla::API', "new() returns object of the right class ok";
is ref($t->mech), 'WWW::Mechanize', "...so does mech()";

is $t->api_cache_persist, 1, "api_cache_persist() set ok";
is $t->api_cache_time, 400, "api_cache_time() set ok";

is $token_sub->called, 1, "_access_token() was called during instantiation ok";
is $token_sub->called_count, 1, "_access_token() was called only once ok";

done_testing();