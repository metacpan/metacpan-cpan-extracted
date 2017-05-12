#!/usr/bin/perl -w

use strict;
use Test::More;
use MogileFS::Client;
use MogileFS::Admin;

my $moga = MogileFS::Admin->new(hosts => ['127.0.0.1:7001']);
my $doms = eval { $moga->get_domains };

unless ($doms) {
    plan skip_all => "No mogilefsd process running on 127.0.0.1:7001";
    exit 0;
} else {
    plan tests => 10;
}

my $test_ns = "_MogileFS::Client::TestSuite";

if ($doms->{$test_ns}) {
    pass("test namespace already exists");
} else {
    ok($moga->create_domain($test_ns), "created test namespace");
}

my $mogc = MogileFS::Client->new(hosts  => ['127.0.0.1:7001'],
                                 domain => $test_ns);
ok($mogc, "made mogile client object");

# bogus class..
my $fh = $mogc->new_file("test_file1", "bogus_class");
ok(! $fh, "got a filehandle");
is($mogc->errcode, "unreg_class", "got correct error about making file in bogus class");

$fh = $mogc->new_file("test_file1");
ok($fh, "filehandle in general class");

my $data = "0123456789" x 500;
my $wv = (print $fh $data);
is($wv, length $data, "wrote data bytes out");
ok($fh->close, "closed successfully");

ok(scalar $mogc->get_paths("test_file1") >= 1, "exists in one or more places");

ok($mogc->delete("test_file1"), "deleted test file");

ok($moga->delete_domain($test_ns), "deleted test namespace");

#use Data::Dumper;
#print Dumper($doms);




