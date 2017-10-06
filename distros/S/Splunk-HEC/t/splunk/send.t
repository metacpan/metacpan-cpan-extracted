use Test::More;
use Splunk::HEC;
use strict;

plan skip_all => 'set SPLUNK_HEC_URL and SPLUNK_HEC_TOKEN to enable this test'
  unless $ENV{SPLUNK_HEC_URL} && $ENV{SPLUNK_HEC_TOKEN};

# Basic send test
my $hec = Splunk::HEC->new(url => $ENV{SPLUNK_HEC_URL}, token => $ENV{SPLUNK_HEC_TOKEN});

my $res = $hec->send(event => {message => 'Something happened', severity => 'INFO'});
is $res->is_success, 1,   'is_success is true';
is $res->code,       200, 'right code (200)';
isnt $res->content,  '',  'content is not empty';

done_testing();
