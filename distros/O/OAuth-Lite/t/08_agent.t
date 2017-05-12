use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

use HTTP::Request;
use OAuth::Lite::Agent;

my $agent = OAuth::Lite::Agent->new;
my $req = HTTP::Request->new;
my $filtered = $agent->filter_request($req);
is($filtered->header('Accept-Encoding'), 'gzip');

my $deflate = HTTP::Request->new;
$deflate->header('Accept-Encoding' => 'deflate');
$filtered = $agent->filter_request($deflate);
is($filtered->header('Accept-Encoding'), 'deflate, gzip');

my $gzip = HTTP::Request->new;
$gzip->header('Accept-Encoding' => 'gzip');
$filtered = $agent->filter_request($gzip);
is($filtered->header('Accept-Encoding'), 'gzip');

my $defgzip = HTTP::Request->new;
$defgzip->header('Accept-Encoding' => 'gzip, deflate');
$filtered = $agent->filter_request($defgzip);
is($filtered->header('Accept-Encoding'), 'gzip, deflate');
