use Test::More;
use Time::HiRes;
use Splunk::HEC::Request;
use Sys::Hostname;
use strict;

# Request
my $req = Splunk::HEC::Request->new;
is $req->host, Sys::Hostname::hostname(), 'host is set';
is $req->time, sprintf('%.3f', Time::HiRes::time()), 'right time';
is $req->source,     '', 'source is empty';
is $req->sourcetype, '', 'sourcetype is empty';
is $req->index,      '', 'index is empty';
$req->event({message => 'Event Message', severity => 'INFO'});
is $req->event->{message},  'Event Message', 'Message set';
is $req->event->{severity}, 'INFO',          'Severity set';

done_testing();
