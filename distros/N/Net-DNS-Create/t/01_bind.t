# -*- perl -*-

use strict; use warnings;
use Test::More tests => 1;

use File::Temp qw(tempfile tempdir);
use Net::DNS::Create qw(Bind), default_ttl => "1h", conf_prefix => "test_", dest_dir => './t/tmp';

use File::Path qw(make_path);
make_path("./t/tmp");
unlink("./t/tmp/test_example.com.zone");
unlink("./t/tmp/test_master.conf");

do './t/example.com';
die $@ if $@;

master "master.conf";

my @test;
open my $test, '<', './t/tmp/test_example.com.zone' or die "./t/tmp/test_example.com.zone: $!";
push @test, s/\s+/ / && $_ while (<$test>);

my @good;
open my $good, '<', './t/good/test_example.com.zone' or die "./t/good/test_example.com.zone: $!";
push @good, s/\s+/ / && $_ while (<$good>);

use Test::Deep;
cmp_deeply([sort @test], [sort @good], "bind output is good");
