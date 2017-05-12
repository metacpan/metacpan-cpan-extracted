use strict;
use warnings;
use Test::More;
use Net::Heroku;

use constant TEST => $ENV{TEST_ONLINE};

my $username = 'cpantests@empireenterprises.com';
my $password = 'third13_wave';
my $api_key  = 'd46d2e0a23e9dd1746d24f88ba6c52206246fb1f';

ok my $h = Net::Heroku->new(api_key => $api_key);

subtest auth => sub {
  plan skip_all => 'because' unless TEST;

  is +Net::Heroku->new->_retrieve_api_key($username, $password) => $api_key;
  is +Net::Heroku->new(email => $username, password => $password)
    ->ua->api_key => $api_key;

  is +Net::Heroku->new(api_key => $api_key)->ua->api_key => $api_key;
};

subtest errors => sub {
  plan skip_all => 'because' unless TEST;

  # No error
  ok my %res = $h->create;
  ok !$h->error;

  # Error, empty list assignment
  ok !(my %tmp = $h->create(name => $res{name}));
  ok !keys %tmp;

  # Error from json
  ok !$h->create(name => $res{name});
  is $h->error => 'Name is already taken';

  is_deeply { $h->error } => {
    code    => 422,
    message => 'Name is already taken'
  };

  ok $h->destroy(name => $res{name});

  # Error from body
  ok !$h->destroy(name => $res{name});
  is $h->error => 'App not found.';

  is_deeply { $h->error } => {
    code    => 404,
    message => 'App not found.'
  };
};

subtest domains => sub {
  plan skip_all => 'because' unless TEST;

  ok my %res = $h->create;

  ok my $default_domain = [$h->domains(name => $res{name})]->[0];
  is $default_domain->{domain} => $res{domain_name}->{domain};

  ok !$h->add_domain(name => $res{name}, domain => 'mojocasts.com');
  is $h->error => 'mojocasts.com is currently in use by another app.';

  my $domain = 'domain-name-for-' . $res{name} . '.com';
  ok !$h->add_domain(name => $res{name}, domain => $domain);
  ok grep $_->{base_domain} eq $domain => $h->domains(name => $res{name});

  ok $h->remove_domain(name => $res{name}, domain => $domain);
  is_deeply $default_domain => [$h->domains(name => $res{name})]->[0];

  ok $h->destroy(name => $res{name});
};

subtest apps => sub {
  plan skip_all => 'because' unless TEST;

  ok my %res = $h->create(stack => 'cedar');
  like $res{stack} => qr/^cedar/;

  ok grep $_->{name} eq $res{name} => $h->apps;

  ok $h->destroy(name => $res{name});
  ok !grep $_->{name} eq $res{name} => $h->apps;

  # Do not fail with empty names
  #ok %res = $h->create(name => '');
  #ok $res{name};
  #ok $h->destroy(name => $res{name});
};

subtest config => sub {
  plan skip_all => 'because' unless TEST;

  ok my %res = $h->create;

  is { $h->add_config(name => $res{name}, TEST_CONFIG => 'Net-Heroku') }
  ->{TEST_CONFIG} => 'Net-Heroku';

  is { $h->config(name => $res{name}) }->{TEST_CONFIG} => 'Net-Heroku';

  ok $h->destroy(name => $res{name});
};

subtest keys => sub {
  plan skip_all => 'because' unless TEST;

  my $key =
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCwiIC7DZYfPbSn/O82ei262gnExmsvx27nkmNgl5scyYhJjwMkZrl66zofAkwsydxl+7fNfKio+FsdutNva4yVruk011fzKU+Nsa5jEe0MF/x0e6QwBLtq9QthWomgvoNccV9g3TkkjykCFQQ7aLId1Wur0B+MzwCIVZ5Cm/+K2w== cpantests-net-heroku';

  ok $h->add_key(key => $key);
  ok grep $_->{contents} eq $key => $h->keys;

  $h->remove_key(key_name => 'cpantests-net-heroku');
  ok !grep $_->{contents} eq $key => $h->keys;
};

subtest processes => sub {
  plan skip_all => 'because' unless TEST;

  ok my %res = $h->create;

  # List of processes
  #ok grep defined $_->{pretty_state} => $h->ps(name => $res{name});
  ok !$h->ps(name => $res{name});

  # Run process
  is { $h->run(name => $res{name}, command => 'ls') }->{state} => 'starting';

  # Restart app
  ok $h->restart(name => $res{name}), 'restart app';

  # Restart process
  ok $h->restart(name => $res{name}, ps => 'ls'), 'restart app process';

  # Stop process
  ok $h->stop(name => $res{name}, ps => 'ls'), 'stop app process';

  ok $h->destroy(name => $res{name});
};

subtest releases => sub {
  plan skip_all => 'because' unless TEST;

  ok my %res = $h->create;

  # Wait until server process finishes adding add-ons (v2 release)
  for (1 .. 5) {
    last if $h->releases(name => $res{name}) == 2;
    sleep 1;
  }

  # Add buildpack to increment release
  ok $h->add_config(
    name          => $res{name},
    BUILDPACK_URL => 'http://github.com/tempire/perloku.git'
  );

  # List of releases
  my @releases = $h->releases(name => $res{name});
  ok grep $_->{descr} eq 'Add BUILDPACK_URL config' => @releases;

  # One release by name
  my %release =
    $h->releases(name => $res{name}, release => $releases[-1]{name});
  is $release{name} => $releases[-1]{name};

  # Rollback to a previous release
  my $previous_release = 'v' . int @releases;
  is $h->rollback(name => $res{name}, release => $previous_release) =>
    $previous_release;
  ok !$h->rollback(name => $res{name}, release => 'v0');

  ok $h->destroy(name => $res{name});
};

done_testing;
