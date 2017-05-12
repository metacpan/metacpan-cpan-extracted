#!/usr/bin/perl -w
use strict;

use HTTP::Daemon;
use File::Slurp;

my $d = HTTP::Daemon->new || die;
write_file($ENV{HOME} . "/oth.url", $d->url);

my $c = $d->accept or die;
my $r = $c->get_request;
$c->send_file_response($ARGV[0]);
undef $c;

$c = $d->accept or die;
$r = $c->get_request;
$c->send_file_response($ARGV[0]);
undef $c;
