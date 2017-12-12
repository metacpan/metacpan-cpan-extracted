#!perl

use v5.10;
use Test::More;
use Test::Deep;
use t::start_server;

plan tests => 7;

use IO::Async::Loop;
use Net::Async::Beanstalk;

my $loop = IO::Async::Loop->new();

my $client = Net::Async::Beanstalk->new();
$loop->add($client);
$client->connect(host => 'localhost', service => $server_port)->get;

{
  cmp_deeply([$client->use("foobar")->get],
             ['foobar'],                  'Received expected response for "use foobar"');
  cmp_deeply([$client->list_tube_used()->get],
             ['foobar'],                  'Am now using tube "foobar"');
}

{
  cmp_deeply([$client->watch("foobar")->get],
             ['foobar', 2],               'Received expected response for "watch foobar"');
  cmp_set(   [$client->list_tubes_watched->get],
             [qw(default foobar)],        'Now watching tubes "default" and "foobar"');
}

my $anything = bless { foo => 42 }, "bar";
ok defined $client->put($anything)->get,  'Successfully queued job';

my @job = $client->reserve->get;
cmp_deeply \@job, [1, $anything],         'Successfully retreived job';

my @del = $client->delete($job[0])->get;
cmp_deeply \@del, [ $job[0] ],            'Successfully deleted job';


