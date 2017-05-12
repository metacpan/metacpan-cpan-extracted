#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok "Net::CheckHost";

my $ch = new_ok 'Net::CheckHost';

my $request = $ch->prepare_request('check-ping', host => "localhost", max_nodes => 3);
is $request->method, 'GET';
is $request->uri->scheme, 'https';
is $request->uri->host, 'check-host.net';
is $request->uri->path, '/check-ping';
my %query = $request->uri->query_form;
is $query{host}, 'localhost';
is $query{max_nodes}, 3;
is $request->header('Content-Type'), 'application/json';

done_testing();
