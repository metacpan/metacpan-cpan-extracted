use Test2::V0;
use Mojo::Netdata;
use Mojo::Netdata::Collector::HTTP;

subtest 'basics' => sub {
  my $collector = Mojo::Netdata::Collector::HTTP->new;
  is $collector->type,         'HTTP', 'type';
  is $collector->update_every, 30,     'update_every';

  is $collector->ua->insecure,        0, 'insecure';
  is $collector->ua->connect_timeout, 5, 'connect_timeout';
  is $collector->ua->request_timeout, 5, 'request_timeout';
};

subtest 'register' => sub {
  my %config = (
    collector => 'Mojo::Netdata::Collector::HTTP',
    jobs      => [
      "http://nope.localhost",
      "/ignored"                => {},
      "http://b.localhost",     => {body   => 'foo', dimension => 'body', method => 'POST'},
      "http://f.localhost",     => {form   => {foo => 'bar'}},
      "http://j.localhost",     => {json   => {foo => 'bar'}},
      "http://example.com"      => {family => 'F1', via => '93.184.216.34'},
      "http://example.com"      => {family => 'F1'},
      "http://example.com/test" => {family => 'F1', dimension => 'test'},
    ],
  );

  my %with_defaults = (
    collector => 'Mojo::Netdata::Collector::HTTP',
    headers   => {X => 42},
    family    => 'D1',
    jobs      =>
      ['https://d1.localhost', 'https://r1.localhost' => {family => 'R1', headers => {Y => 0}}],
  );

  my $netdata
    = Mojo::Netdata->new(update_every => 10)->config({collectors => [\%config, \%with_defaults]});
  my $collector = $netdata->collectors->[0];
  ok $collector, 'got collector';

  is(
    $collector->jobs,
    [
      [[GET => 'http://nope.localhost', {}],                       D()],
      [[POST => 'http://b.localhost', {}, 'foo'],                  D()],
      [[GET => 'http://f.localhost', {}, 'form', {foo => 'bar'}],  D()],
      [[GET => 'http://j.localhost', {}, 'json', {foo => 'bar'}],  D()],
      [[GET => 'http://93.184.216.34', {Host => ['example.com']}], D()],
      [[GET => 'http://example.com/test', {}],                     D()],
    ],
    'jobs',
  );

  my $t1    = time;
  my $chart = $collector->chart('F1_code');
  my $tx    = Mojo::Transaction::HTTP->new;
  is $chart->dimension('example.com')->{value}, undef, 'dimension has no value';
  $tx->res->code(301);
  $_->[1]->($tx, $t1) for @{$collector->jobs};
  is $chart->dimension('example.com')->{value}, 301, 'code dimension got updated';

  $chart = $collector->chart('F1_time');
  is $chart->dimension('example.com')->{value}, within(500, 500),
    'responsetime dimension got updated';

  $collector = $netdata->collectors->[1];
  is(
    $collector->jobs,
    [
      [[GET => 'https://d1.localhost', {X => [42]}],           D()],
      [[GET => 'https://r1.localhost', {X => [42], Y => [0]}], D()],
    ],
    'jobs with defaults',
  );

  ok $collector->chart('D1_code')->dimension('d1.localhost'), 'using default family';
  ok $collector->chart('R1_code')->dimension('r1.localhost'), 'override default family';
};

subtest 'register and run' => sub {
  my %config = (
    collector       => 'Mojo::Netdata::Collector::HTTP',
    connect_timeout => 2,
    request_timeout => 2,
    insecure        => 1,
    jobs            => [
      "http://nope.localhost",
      "http://93.184.216.34" =>
        {dimension => 'direct', family => 'Test Group', headers => {Host => 'example.com'}},
      "http://example.com" => {family => 'Test Group'},
    ],
  );

  open my $FH, '>', \(my $stdout = '');
  my $netdata
    = Mojo::Netdata->new(stdout => $FH, update_every => 10)->config({collectors => [\%config]});
  my $collector = $netdata->collectors->[0];
  ok $collector, 'got collector';
  is $collector->update_every,        10, 'update_every from netdata';
  is $collector->ua->insecure,        1,  'insecure';
  is $collector->ua->connect_timeout, 2,  'connect_timeout';
  is $collector->ua->request_timeout, 2,  'request_timeout';

  $collector->emit_charts;
  is $stdout, <<"HERE", 'charts';
CHART HTTP.Test_Group_code '' 'HTTP Status code for Test Group' '#' 'Test Group' httpcheck.code line 10000 10 '' 'mojo' 'mojo_netdata_collector_http'
DIMENSION direct 'direct' absolute 1 1 ''
DIMENSION example_com 'example.com' absolute 1 1 ''
CHART HTTP.Test_Group_time '' 'Response time for Test Group' 'ms' 'Test Group' httpcheck.responsetime line 10000 10 '' 'mojo' 'mojo_netdata_collector_http'
DIMENSION direct 'direct' absolute 1 1 ''
DIMENSION example_com 'example.com' absolute 1 1 ''
CHART HTTP.nope_localhost_code '' 'HTTP Status code for nope.localhost' '#' 'nope.localhost' httpcheck.code line 10000 10 '' 'mojo' 'mojo_netdata_collector_http'
DIMENSION nope_localhost 'nope.localhost' absolute 1 1 ''
CHART HTTP.nope_localhost_time '' 'Response time for nope.localhost' 'ms' 'nope.localhost' httpcheck.responsetime line 10000 10 '' 'mojo' 'mojo_netdata_collector_http'
DIMENSION nope_localhost 'nope.localhost' absolute 1 1 ''
HERE

  $collector->update_p->wait;
  $collector->emit_data;

  like $stdout, qr{BEGIN HTTP\.Test_Group_code.*SET direct = \d+.*SET example_com = \d+.*END}s,
    'emit_data code';
  like $stdout, qr{BEGIN HTTP\.Test_Group_time.*SET direct = \d+.*SET example_com = \d+.*END}s,
    'emit_data time';

  like $stdout, qr{BEGIN HTTP\.nope_localhost_code.*SET nope_localhost = 0.*END}s, 'emit_data code';
  like $stdout, qr{BEGIN HTTP\.nope_localhost_time.*SET nope_localhost = \d+.*END}s,
    'emit_data time';

  note $stdout;
};

done_testing;
