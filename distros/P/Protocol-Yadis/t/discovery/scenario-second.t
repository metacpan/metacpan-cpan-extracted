#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use Protocol::Yadis;

my $y = Protocol::Yadis->new(
    http_req_cb => sub {
        my ($url, $method, $headers, $body, $cb) = @_;

        my $error;
        my $status = 200;
        $body    = '';
        $headers = {};

        if ($url eq '1') {
            $status = 404;
        }
        elsif ($url eq '2') {
        }
        elsif ($url eq '3') {
            $headers = {
                'Content-Type'    => 'application/xrds+xml'
            };
            $body =<<'';
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)"
   xmlns:openid="http://openid.net/xmlns/1.0">
 <XRD>
  <Service priority="10">
   <Type>http://openid.net/signon/1.0</Type>
   <URI>http://www.myopenid.com/server</URI>
   <openid:Delegate>http://smoker.myopenid.com/</openid:Delegate>
  </Service>
 </XRD>
</xrds:XRDS>

        }
        elsif ($url eq '4') {
            $body = 'foobar';
        }
        elsif ($url eq 'error') {
            $error = 'Error';
        }

        $cb->($url, $status, $headers, $body, $error);
    }
);

# Error -> FAIL
$y->discover(
    'error' => sub {
        my ($y, $doc, $error) = @_;

        ok(not defined $doc);
        is($error, 'Error');
    }
);

# !200 -> FAIL
$y->discover(
    '1' => sub {
        my ($y, $doc, $error) = @_;

        ok(not defined $doc);
        is($error, 'Wrong response status');
    }
);

# 200 -> !document -> FAIL
$y->discover(
    '2' => sub {
        my ($y, $doc, $error) = @_;

        ok(not defined $doc);
        is($error, 'No document was found');
    }
);

# 200 -> document -> yadis -> OK
$y->discover(
    '3' => sub {
        my ($y, $doc, $error) = @_;

        ok($doc);
        ok(not defined $error);
    }
);

# 200 -> document -> !yadis -> FAIL
$y->discover(
    '4' => sub {
        my ($y, $doc, $error) = @_;

        ok(not defined $doc);
        is($error, 'No <head> was found');
    }
);
