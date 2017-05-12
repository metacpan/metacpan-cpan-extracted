# -*- perl -*-

use strict; use warnings;
use Test::More tests => 1;

use File::Temp qw(tempfile tempdir);
use Net::DNS::Create qw(Tiny), default_ttl => "1h";

use File::Path qw(make_path);
make_path("./t/tmp");
unlink("./t/tmp/data");

do './t/example.com';
die $@ if $@;

master "./t/tmp/data";

my @test;
open my $test, '<', './t/tmp/data' or die "t/tmp/data: $!";
push @test, $_ while (<$test>);

my @good;
open my $good, '<', './t/good/data' or die "t/good/data: $!";
push @good, $_ while (<$good>);

is_deeply([sort @test], [sort @good]);
