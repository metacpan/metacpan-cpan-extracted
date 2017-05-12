use strict;
use warnings;
use Test::More;
use Test::Deep;
use Redis::ScriptCache;
use Redis;

if (not -f 'redis_connect_data') {
  plan(skip_all => "Need Redis test server host:port in the 'redis_connect_data' file");
  exit(0);
}

open my $fh, "<", "redis_connect_data" or die $!;
my $host = <$fh>;
$host =~ s/^\s+//;
chomp $host;
$host =~ s/\s+$//;

my $conn;
eval { $conn = Redis->new(server => $host); 1 }
or do {
  my $err = $@ || 'Zombie error';
  diag("Failed to connect to Redis server: $err. Not running tests");
  plan(skip_all => "Cannot connect to Redis server");
  exit(0);
};

eval {
  $conn->script_load("return 1");
  1
} or do {
  my $err = $@ || 'Zombie error';
  diag("Redis server does not appear to support Lua scripting. Not running tests");
  plan(skip_all => "Redis server does not support Lua scripting");
  exit(0);
};

plan tests => 12;

# start with no scripts to test load on demand
$conn->script_flush;

my $cache = Redis::ScriptCache->new(redis_conn => $conn);
isa_ok($cache, "Redis::ScriptCache");

$cache = Redis::ScriptCache->new(
    redis_conn => $conn,
    script_dir => 't/lua',
);

# although we're passing in the script_name, we return it, so we can
# future-proof it with versioning, like script_name_v2
my $script_name = $cache->register_script('script_name', 'return 2');
is( $script_name, 'script_name', "register_script 'script_name'");

# repeat, testing that re-registration works OK
$script_name = $cache->register_script('script_name', 'return 2');
is( $script_name, 'script_name', "re-register_script 'script_name'");

# test for scalar ref
$script_name = $cache->register_script('script_name', \'return 2');
is( $script_name, 'script_name', "register_script 'script_name' with scalar ref");

# test register_file
# because script_dir is already declared, 't/lua' is implicit
$script_name = $cache->register_file('test.lua');
is( $script_name, 'test', "register_file 'test' (default case with script_dir with no trailing slash)");

# repeat, testing that re-registration works OK
$script_name = $cache->register_file('test.lua');
is( $script_name, 'test', "re-register_file 'test'");

# create an object with a trailing slash in script_dir, and then register
$cache = Redis::ScriptCache->new(
    redis_conn => $conn,
    script_dir => 't/lua/',
);
$script_name = $cache->register_file('test.lua');
is( $script_name, 'test', "register_file 'test' with script_dir with trailing slash");

# TODO: add test-cases for invalid file-paths
# TODO: is an absolute path a valid path?

# run_script for an already-registered script
my $res = $cache->run_script('test');
is($res, 2, "run script without args works");

$res = $cache->run_script('test', [0]);
is($res, 2, "run script with args works");

my @script_names = $cache->register_all_scripts();
cmp_deeply(\@script_names, bag( 'test3', 'test2', 'test' ), "load_scripts works for good scripts");

$res = $cache->run_script('test3');
my @output = ( 1, 2, 3 );
cmp_deeply($res, \@output, "return arrayref");

my @res = $cache->run_script('test3');
cmp_deeply(\@res, \@output, "return array");
