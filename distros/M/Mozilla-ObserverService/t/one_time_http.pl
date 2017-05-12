#!/usr/bin/perl -w
use strict;

use HTTP::Daemon;
use File::Slurp;

my $times = 1;
my $d = HTTP::Daemon->new || die;
write_file($ENV{HOME} . "/oth.url", $d->url);

while ($times > 0) {
	my $c = $d->accept or die;
	my $r = $c->get_request;
	$c->send_file_response($ARGV[0]);
	$times--;
}
