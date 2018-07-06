use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;
use Mojo::Loader 'data_section';
use Mojo::Util 'sha1_sum';

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db    = $redis->db;

my $script_myid = data_section(main => 'change_database_add_3_numbers_and_change_back_to_default_database.lua');
my $script_outtable
  = data_section(main => 'pull_out_from_a_redis_list_generate_sha1hex_for_each_element_and_return_the_array.lua');

my $script_myid_sha = $db->script(load => $script_myid);
ok $db->script(exists => $script_myid_sha), 'script myid exists';
ok !$db->script(exists => sha1_sum('nope')), 'script nope does not exist';

my $input = Mojo::Collection->new(1 .. 3)->map(sub { int rand 999999 });
my $key = "$0:eval";
is $redis->db->eval($script_myid, 1, $key, @$input), $input->reduce(sub { $a + $b }), 'eval myid';
is $redis->db->evalsha($script_myid_sha, 1, $key, @$input), $input->reduce(sub { $a + $b }), 'evalsha myid';

done_testing;

__DATA__
@@ change_database_add_3_numbers_and_change_back_to_default_database.lua
redis.call("SELECT", 1)
redis.call("SET", KEYS[1], ARGV[1])
redis.call("INCRBY", KEYS[1], ARGV[2])
local myid = redis.call("INCRBY", KEYS[1], ARGV[3])
redis.call("DEL", KEYS[1])
redis.call("SELECT", 0)
return myid
@@ pull_out_from_a_redis_list_generate_sha1hex_for_each_element_and_return_the_array.lua
local intable = redis.call('LRANGE', KEYS[1], 0, -1);
local outtable = {}
for _,val in ipairs(intable) do
  table.insert(outtable, redis.sha1hex(val))
end
redis.call('DEL', KEYS[1])
return outtable
