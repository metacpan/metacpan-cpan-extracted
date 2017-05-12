#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More tests => 6;
use Mojo::Log::More;

my $buf = '';
open my $fh, '>:scalar', \$buf or die;

my $log = Mojo::Log::More->new(level => 'debug', handle => $fh);
isa_ok $log, 'Mojo::Log::More';

$log->debug("message");
ok $buf =~ /^\S+ 01-log.t:14 DEBUG> message$/, "log debug";
$buf = ''; seek $fh, 0, 0;

$log->info("message");
ok $buf =~ /^\S+ 01-log.t:18 INFO> message$/, "log info";
$buf = ''; seek $fh, 0, 0;

$log->warn("message");
ok $buf =~ /^\S+ 01-log.t:22 WARN> message$/, "log warn";
$buf = ''; seek $fh, 0, 0;

$log->error("message");
ok $buf =~ /^\S+ 01-log.t:26 ERROR> message$/, "log error";
$buf = ''; seek $fh, 0, 0;

$log->fatal("message");
ok $buf =~ /^\S+ 01-log.t:30 FATAL> message$/, "log fatal";
