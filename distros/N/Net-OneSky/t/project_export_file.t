#!/usr/bin/env perl -Tw

use strict;
use warnings;

use Test::More tests => 13;
use Test::MockObject;
use Test::Trap;

use Net::OneSky;

my $client;
my $project;
my $id;
my $locale;
my $remote_file;
my $local_file;
my $resp;
my $file_data;

BEGIN {
  $id = 42;
  $remote_file = 'section.en-US.yml';
  $local_file = '/an/absolute/path/to/a/file';
  $locale = 'hi-IN';
  $file_data = 'file data!';

  $client = new Test::MockObject;
  # The Moose attribute restrictions on project require client to be a  Net::OneSky object.
  # So we fake it here, and replace it after it’s created.
  $project = new Net::OneSky::Project(id => $id, client => bless({}, 'Net::OneSky'));
  $project->{client} = $client;

  $resp = new Test::MockObject;
  $resp->mock('is_success', sub { 1 });
  $resp->mock('code', sub { 200 });
  $resp->mock('content', sub { $file_data });
}

#### Simple case

$client->mock('get', sub {
  my ($self, $url, $query_data) = @_;
  my %q = @$query_data;

  is($url, "/1/projects/$id/translations", 'it uses the correct URL');
  is($q{locale}, $locale, 'it passes the locale');
  is($q{source_file_name}, $remote_file, 'it passes the source_file_name');
  is($q{export_file_name}, $local_file, 'it passes the export_file_name');
  return $resp;
});

my $result = $project->export_file($locale, $remote_file, $local_file);

is($result, $file_data, 'it returns the file contents');

#### Error cases

## Argument requirements

$client->mock('get', sub { $resp });

trap {
  $project->export_file(undef, $remote_file);
};

is($trap->leaveby, 'die', 'it requires the locale');
ok($trap->die =~ /missing locale/i, '   with the correct error message');

trap {
  $project->export_file($locale);
};

is($trap->leaveby, 'die', 'it requires the remote file');
ok($trap->die =~ /missing remote_file/i, '   with the correct error message');

$resp->mock('code', sub {202});

## Incomplete file response

trap {
  $project->export_file($locale, $remote_file);
};

is($trap->leaveby, 'die', 'it dies when the file is not ready');
ok($trap->die =~ /incomplete response/i, '   with the correct error message');

## block_until_done

trap {
  $project->export_file($locale, $remote_file, $local_file, 1);
};

is($trap->leaveby, 'die', 'it dies when the file is not ready');
ok($trap->die =~ /implemented/i, '   with the correct error message');

done_testing
