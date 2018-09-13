#!/usr/bin/env perl -Tw

use strict;
use warnings;

use Test::More tests => 9;
use Test::MockObject;
use Test::Trap;

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
  $resp->mock('content', sub { '{"data":[{"file_name":"a.yml"},{"file_name":"b.json"}],"meta":{"page_count":1}}' });
}

#### Simple case

$client->mock('get', sub {
  my ($self, $url, $query_data) = @_;
  my %q = @$query_data;

  is($url, "/1/projects/$id/files", 'it uses the correct URL');
  return $resp;
});

is (join(' ', sort($project->list_files)), 'a.yml b.json', 'it extracts file names');

### Pagination

my $calls = 0;
my @files = qw{a.yml b.json};
$resp->mock('content', sub {
  my $file = $files[$calls - 1];
  qq{{"data":[{"file_name":"$file"}],"meta":{"page_count":2}}}
});

$client->mock('get', sub {
  is($_[2]->[1], ++$calls, 'it correctly increments the page number in requests');
  return $resp;
});

is (join(' ', sort($project->list_files)), 'a.yml b.json', 'it correctly paginates');

### Error cases

$client->mock('get', sub {
  return $resp;
});

$resp->mock('content', sub { '{}' });

trap {
  $project->list_files;
};

is($trap->leaveby, 'die', 'it dies if no page count is returned');
$DB::single = 1;

ok($trap->die =~ /NO files/, '   with the correct error');


$resp->mock('is_success',  sub { 0 });

trap {
  $project->list_files;
};

is($trap->leaveby, 'die', 'it dies if the request fails');
$DB::single = 1;

ok($trap->die =~ /ERROR fetching file list/, '   with the correct error');

done_testing
