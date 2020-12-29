#!/usr/bin/perl

use Test::Pod tests => 10;

pod_file_ok( './lib/Net/API/REST.pm' );
pod_file_ok( './lib/Net/API/REST/Cookies.pm' );
pod_file_ok( './lib/Net/API/REST/DateTime.pm' );
pod_file_ok( './lib/Net/API/REST/JWT.pm' );
pod_file_ok( './lib/Net/API/REST/Query.pm' );
pod_file_ok( './lib/Net/API/REST/Request.pm' );
pod_file_ok( './lib/Net/API/REST/Request/Params.pod' );
pod_file_ok( './lib/Net/API/REST/Request/Upload.pod' );
pod_file_ok( './lib/Net/API/REST/Response.pm' );
pod_file_ok( './lib/Net/API/REST/Status.pm' );

