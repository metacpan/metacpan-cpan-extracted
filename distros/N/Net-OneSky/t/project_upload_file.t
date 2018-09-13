#!/usr/bin/env perl -Tw

use strict;
use warnings;

use Test::More tests => 8;
use Test::MockObject;
use Test::Trap;

use Net::OneSky;

my $client;
my $project;
my $id;
my $format;
my $file;
my $locale;

BEGIN {
  $id = 42;
  $format = 'MY_FORMAT';
  $file = '/an/absolute/path/to/a/file';
  $locale = 'hi-IN';
  $client = new Test::MockObject;
  # The Moose attribute restrictions on project require client to be a  Net::OneSky object.
  # So we fake it here, and replace it after it’s created.
  $project = new Net::OneSky::Project(id => $id, client => bless({}, 'Net::OneSky'));
  $project->{client} = $client;
}

#### Simple case

$client->mock('file_upload', sub {
  my ($self, $url, $query_data) = @_;
  my %q = @$query_data;

  is($url, "/1/projects/$id/files", 'it uses the correct URL');
  is(join(' ', @{$q{file}}), "$file file", 'it passes the file & basename');
  is($q{locale}, $locale, 'it passes the locale');
  is($q{file_format}, $format, 'it passes the format');
});

$project->upload_file($file, $format, $locale);

#### Error cases

trap {
  $project->upload_file(undef, $format, $locale);
};

is($trap->leaveby, 'die', 'it requires the filename');
ok($trap->die =~ /missing file/i, '   with the correct error message');

trap {
  $project->upload_file($file, undef, $locale);
};

is($trap->leaveby, 'die', 'it requires the format');
ok($trap->die =~ /missing format/i, '   with the correct error message');

done_testing
