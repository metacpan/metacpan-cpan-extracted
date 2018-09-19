use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

use Net::Curl::Easy qw(:constants);

use Test::MockModule;
use DDP;

my $module = Test::MockModule->new('Net::Curl::Easy');
$module->mock(setopt => sub {
  my $self = shift;
  my ($opt, @args) = @_;

  $self->{opts} //= {};
  $self->{opts}{$opt} = [@args];

  return 1;
});

subtest 'default settings' => sub {
  my $f = Net::Curl::Parallel->new;

  my $uri = 'http://www.example.com';

  my $idx = $f->add(GET => $uri);
  my $curl = $f->setup_curl($idx);

  is delete $curl->{opts}{CURLOPT_NOPROGRESS()}, [1], 'CURLOPT_NOPROGRESS';
  is delete $curl->{opts}{CURLOPT_TCP_NODELAY()}, [1], 'CURLOPT_TCP_NODELAY';

  is delete $curl->{opts}{CURLOPT_CONNECTTIMEOUT_MS()}, [$f->connect_timeout], 'CURLOPT_CONNECTTIMEOUT_MS';
  is delete $curl->{opts}{CURLOPT_TCP_KEEPALIVE()}, [1], 'CURLOPT_TCP_KEEPALIVE is always set';
  is delete $curl->{opts}{CURLOPT_VERBOSE()}, undef, 'CURLOPT_VERBOSE';

  is delete $curl->{opts}{CURLOPT_ACCEPT_ENCODING()}, [''], 'CURLOPT_ACCEPT_ENCODING';
  is delete $curl->{opts}{CURLOPT_PROTOCOLS()}, [CURLPROTO_HTTP | CURLPROTO_HTTPS], 'CURLOPT_PROTOCOLS';
  is delete $curl->{opts}{CURLOPT_USERAGENT()}, [$f->agent], 'CURLOPT_USERAGENT';
  is delete $curl->{opts}{CURLOPT_URL()}, [$uri], 'CURLOPT_URL';

  is delete $curl->{opts}{CURLOPT_POST()}, undef, 'CURLOPT_POST';
  is delete $curl->{opts}{CURLOPT_POSTFIELDS()}, undef, 'CURLOPT_POSTFIELD';

  is delete $curl->{opts}{CURLOPT_HTTPHEADER()}, [['Connection: keep-alive']], 'CURLOPT_HTTPHEADER';
  is delete $curl->{opts}{CURLOPT_FOLLOWLOCATION()}, [''], 'CURLOPT_FOLLOWLOCATION';
  is delete $curl->{opts}{CURLOPT_MAXREDIRS()}, [0], 'CURLOPT_MAXREDIRS';
  is delete $curl->{opts}{CURLOPT_AUTOREFERER()}, [1], 'CURLOPT_AUTOREFERER';
  is delete $curl->{opts}{CURLOPT_SSL_VERIFYPEER()}, [$f->verify_ssl_peer], 'CURLOPT_SSL_VERIFYPEER';
  is delete $curl->{opts}{CURLOPT_TIMEOUT_MS()}, [$f->request_timeout], 'CURLOPT_TIMEOUT_MS';

  # These are set to IO objects, so ignore them.
  ok delete $curl->{opts}{CURLOPT_WRITEDATA()}, 'CURLOPT_WRITEDATA set';
  ok delete $curl->{opts}{CURLOPT_WRITEHEADER()}, 'CURLOPT_WRITEHEADER set';

  is 0+keys(%{$curl->{opts}}), 0, 'All options accounted for';
};

# TESTS:
# if !POST && !keep_alive, then no headers set
subtest 'keep_alive false -> no headers' => sub {
  my $f = Net::Curl::Parallel->new(
    keep_alive => 0,
  );

  my $idx = $f->add(GET => 'http://www.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_HTTPHEADER()}, undef, 'CURLOPT_HTTPHEADER';
};

# verbose -> VERBOSE
subtest 'setting verbose' => sub {
  my $f = Net::Curl::Parallel->new(
    verbose => 1,
  );

  my $idx = $f->add(GET => 'http://www.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_VERBOSE()}, [1], 'CURLOPT_VERBOSE set';
};

# adding headers show up
subtest 'adding a header' => sub {
  my $f = Net::Curl::Parallel->new;

  my $idx = $f->add(GET => 'http://www.example.com', ['Header1: foo']);
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_HTTPHEADER()}, [[
    'Header1: foo',
    'Connection: keep-alive',
  ]], 'CURLOPT_HTTPHEADER';
};

# Verify changing the following result in changes:
# * connect_timeout
#   * 0 => undef
#   * 1 => [1]
subtest 'Zeroing the connect timeout' => sub {
  my $f = Net::Curl::Parallel->new(
    connect_timeout => 0,
  );

  my $idx = $f->add(GET => 'http://www.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_CONNECTTIMEOUT_MS()}, undef, 'CURLOPT_CONNECTTIMEOUT_MS';
};
subtest 'Setting the connect timeout to 1' => sub {
  my $f = Net::Curl::Parallel->new(
    connect_timeout => 1,
  );

  my $idx = $f->add(GET => 'http://www.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_CONNECTTIMEOUT_MS()}, [1], 'CURLOPT_CONNECTTIMEOUT_MS';
};

# * agent
subtest 'Changing the agent shows up' => sub {
  my $f = Net::Curl::Parallel->new(
    agent => 'My Agent',
  );

  my $idx = $f->add(GET => 'http://www.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_USERAGENT()}, ['My Agent'], 'CURLOPT_USERAGENT';
};

# * uri
subtest 'Changing the URI shows up' => sub {
  my $f = Net::Curl::Parallel->new;

  my $idx = $f->add(GET => 'http://not.your.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_URL()}, ['http://not.your.example.com'], 'CURLOPT_URL';
};

# * verify_ssl_peer
subtest 'Changing the URI shows up' => sub {
  my $f = Net::Curl::Parallel->new(
    verify_ssl_peer => 0,
  );

  my $idx = $f->add(GET => 'http://www.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_SSL_VERIFYPEER()}, [0], 'CURLOPT_SSL_VERIFYPEER';
};

# * request_timeout
#   * 0 => undef
#   # 1 => [1]
subtest 'Zeroing the request timeout' => sub {
  my $f = Net::Curl::Parallel->new(
    request_timeout => 0,
  );

  my $idx = $f->add(GET => 'http://www.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_TIMEOUT_MS()}, undef, 'CURLOPT_TIMEOUT_MS';
};
subtest 'Setting the request timeout to 1' => sub {
  my $f = Net::Curl::Parallel->new(
    request_timeout => 1,
  );

  my $idx = $f->add(GET => 'http://www.example.com');
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_TIMEOUT_MS()}, [1], 'CURLOPT_TIMEOUT_MS';
};

subtest 'POST' => sub {
  my $f = Net::Curl::Parallel->new;

  my $idx = $f->add(POST => 'http://www.example.com', undef, { foo => 1, bar => 2 });
  my $curl = $f->setup_curl($idx);

  is $curl->{opts}{CURLOPT_POST()}, [1], 'CURLOPT_POST';
  is $curl->{opts}{CURLOPT_POSTFIELDS()}, in_set(['foo=1&bar=2'], ['bar=2&foo=1']), 'CURLOPT_POSTFIELD';
};

done_testing;
