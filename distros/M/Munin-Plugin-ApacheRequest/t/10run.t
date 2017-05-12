#!/usr/bin/perl -w
use strict;

use Munin::Plugin::ApacheRequest;
use Test::More;

use Test::Trap;
#plan skip_all => "Test::Trap required for testing output" if $@;

my $file;
eval { $file = `which tail` };
plan skip_all => "system 'tail' required for testing this distribution" if($@ || !$file);

plan tests => 4;

$Munin::Plugin::ApacheRequest::ACCESS_LOG_PATTERN = 't/data/missing-file';
trap { Munin::Plugin::ApacheRequest::Run('testsite',1000) };
like( $trap->stdout, qr/images.value U\ntotal.value U/, 'returns data for missing apache file');

$Munin::Plugin::ApacheRequest::ACCESS_LOG_PATTERN = 't/data/access.log';
trap { Munin::Plugin::ApacheRequest::Run('testsite',1000) };
like( $trap->stdout, qr/images.value 1893.3211678832\ntotal.value 138923.1298701299/, 'returns data for specified apache file');

@ARGV = ('config');

trap { Munin::Plugin::ApacheRequest::Run('testsite',1000) };
like( $trap->stdout, qr/images.label Image requests/, 'returns configuration headers');

@ARGV = ();

$Munin::Plugin::ApacheRequest::ACCESS_LOG_PATTERN = 't/data/%s-access.log';
trap { Munin::Plugin::ApacheRequest::Run('testsite',1000) };
like( $trap->stdout, qr/images.value 2399.2222222222\ntotal.value 75538.3404255319/, 'returns data for VHOST apache file');
