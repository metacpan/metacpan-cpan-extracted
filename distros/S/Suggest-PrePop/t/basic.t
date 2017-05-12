use strict;
use warnings;

use Test::FailWarnings;
use Test::Most;
use Test::RedisDB;

use version;

use Suggest::PrePop;

my $server = Test::RedisDB->new;
plan(skip_all => 'Could not start test redis-server') unless $server;
my $redis         = $server->redisdb_client;
my $rangebylexmin = version->parse('2.8.9');
plan(skip_all => 'Minimum Redis version not met. Required: '
      . $rangebylexmin->normal)
  unless version->parse($redis->version) >= $rangebylexmin;

my $former_val = $ENV{'REDIS_CACHE_SERVER'};
$ENV{'REDIS_CACHE_SERVER'} = $server->host . ':' . $server->port;

subtest 'defaults' => sub {
    my $suggestor = new_ok('Suggest::PrePop');

    cmp_ok $suggestor->cache_namespace, 'eq', 'SUGGEST-PREPOP',
      'Cache namespace';
    cmp_ok $suggestor->min_activity, '==', 5, 'Minimum activity';
    cmp_ok $suggestor->top_count,    '==', 7, 'Default item count to return';
    cmp_ok $suggestor->entries_limit, '==', 131_072, 'Entries limit';

};

subtest 'simple' => sub {
    my $suggestor = new_ok('Suggest::PrePop');
    ok $suggestor->add("my fun search", 10), 'Can add an item';
    eq_or_diff $suggestor->ask("my", 10), ['my fun search'],
      'A single entry in the suggestions now';
    cmp_ok $suggestor->prune, '==', 0, 'Not enough entries to prune anything.';
    cmp_ok $suggestor->drop_prefix('my fun'), '==', 1, 'Can drop our item by prefix';
};

subtest 'full' => sub {
    my @test_data = (
        ['mycroft holmes',           10],
        ['mycroft',                  11],
        ['myc',                      2],
        ['sherlock holmes',          6],
        ['sherlock',                 5],
        ['surelock',                 1],
        ['watson',                   4],
        ['moriarty',                 15],
        ['prof moriarty',            8],
        ['prof. moriarty',           9],
        ['professor moriarty',       8],
        ['professor james moriarty', 6],
        ['doctor watson', 10, 'doctors'],
        ['dr. watson',    6,  'doctors'],
        ['dr watson',     6,  'doctors'],
        ['The Doctor', 8, 'doctors', 'who'],
        ['the doctor', 6, 'doctors', 'who'],
    );
    # Limit is only applied on prune.
    my $suggestor = new_ok('Suggest::PrePop' => [entries_limit => 7]);

    foreach my $item (@test_data) {
        ok $suggestor->add(@$item),
          'Add "' . $item->[0] . '" ' . $item->[1] . ' times';
    }
    eq_or_diff(
        $suggestor->scopes,
        ['', 'doctors', 'who'],
        'Empty, doctors and who scopes'
    );
    eq_or_diff(
        $suggestor->ask('m'),
        ['moriarty', 'mycroft', 'mycroft holmes'],
        'Single letter prefix matches'
    );
    eq_or_diff(
        $suggestor->ask('my'),
        ['mycroft', 'mycroft holmes'],
        'Double letter prefix matches'
    );
    eq_or_diff($suggestor->ask('dr'), [],
        'Doctors live in their own search space');
    eq_or_diff(
        $suggestor->ask('dr', 5, 'doctors'),
        ['dr watson', 'dr. watson'],
        '...where we can find them.'
    );
    eq_or_diff($suggestor->ask('the', 5, 'who'),
        ['The Doctor'], 'Results combine and produce the most popular result');
    eq_or_diff(
        $suggestor->ask('t', 5, 'doctors', 'who'),
        $suggestor->ask('t', 5, 'doctors'),
        'Do not get cross-namespace dupes'
    );
    eq_or_diff(
        $suggestor->ask('prof'),
        [
            'prof. moriarty',
            'prof moriarty',
            'professor moriarty',
            'professor james moriarty'
        ],
        'Score order more important'
    );
    eq_or_diff($suggestor->ask('prof', 1),
        ['prof. moriarty'], 'Can limit to just the top entry');

    eq_or_diff(
        $suggestor->ask('sher'),
        ['sherlock holmes', 'sherlock'],
        'Can find both sherlock entries'
    );

    cmp_ok $suggestor->prune, '==', 5, 'Prune back to the entries limit';

    eq_or_diff($suggestor->ask('sher'),
        ['sherlock holmes'], 'Leaving only one sherlock entry');

    cmp_ok $suggestor->prune(0), '==', 7,
      'Can completely empty default namespace';
    cmp_ok $suggestor->prune(0, 'doctors', 'who', 'junk'), '==', 7,
      'Can completely empty "doctors" and "who" namespaces even with junk';

};

# Try to leave the environment unmangled, if possible.
$ENV{'REDIS_CACHE_SERVER'} = $former_val;

done_testing;
