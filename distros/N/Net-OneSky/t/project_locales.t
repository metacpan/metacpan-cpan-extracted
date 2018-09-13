#!/usr/bin/env perl -Tw

use strict;
use warnings;

use Test::More tests => 5;
use Test::Trap;
use Test::MockObject;

use Net::OneSky;

my $client;
my $project;
my $id;
my $resp;

BEGIN {
  $id = 42;
  $client = new Test::MockObject;
  # The Moose attribute restrictions on project require client to be a  Net::OneSky object.
  # So we fake it here, and replace it after it’s created.
  $project = new Net::OneSky::Project(id => $id, client => bless({}, 'Net::OneSky'));
  $project->{client} = $client;

  $resp = new Test::MockObject;
  $resp->mock('is_success', sub { 1 });
  $resp->mock('content', sub { '{"data":[{"code":"en-US", "is_base_language":true},{"code":"fr-FR"},{"code":"de-DE"}]}' });
}

### Simple case

$client->mock('get', sub {
  my ($self, $url) = @_;
  is($url, "/1/projects/$id/languages", 'it uses the correct URL');
  return $resp;
});

is(join(' ', sort($project->locales)), 'de-DE fr-FR', 'it extracts the codes');

# URL only needs to be checked once
$client->mock('get', sub { return $resp });

### Asking for base language

is(join(' ', sort($project->locales(1))), 'de-DE en-US fr-FR', 'it includes the base language when passed true');

### Error case

trap {
  $resp->mock('is_success', sub { 0 });
  $project->locales;
};

is($trap->leaveby, 'die', 'HTTP GET error forces die');
ok($trap->die =~ /ERROR/, 'HTTP GET error reflected in die message');

done_testing
