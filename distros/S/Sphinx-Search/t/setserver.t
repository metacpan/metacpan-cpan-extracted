#! /usr/bin/perl


use Test::More;
use strict;
use warnings;
use Socket;

use Sphinx::Search;

use lib qw(t/testlib testlib);
use TestDB;



my $testdb = TestDB->new();

if (my $msg = $testdb->preflight) {
    plan skip_all => $msg;
}

unless ($testdb->run_searchd()) {
    plan skip_all => "Failed to run searchd; skipping tests.";
}

plan tests => 5;


my $sphinx = Sphinx::Search->new({ port => $testdb->searchd_port });
ok($sphinx, "Constructor");

my $e;

$sphinx->SetServer('', $testdb->searchd_port); 
$e = $sphinx->Query('a');
ok(! $e, "Error on empty server");
like($sphinx->GetLastError(), qr/Failed to open connection|Bad arg length/);

$sphinx->Query('a');
$sphinx->SetServer('my.nosuchhost.exists', $testdb->searchd_port);
$e = $sphinx->Query('a');
ok(! $e, "Error on non-existent server");
like($sphinx->GetLastError(), qr/Failed to open connection|Bad arg length/);


