#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;


my $c = Sys::Virt->new(uri => "qemu:///session");

my $st = $c->new_stream();

die "syntax: $0 VOL-PATH INPUT-FILE" unless int(@ARGV) == 2;

my $volpath = shift @ARGV;
my $f = shift @ARGV;

my $vol = $c->get_storage_volume_by_path($volpath);

open FILE, "<$f" or die "cannot open $f: $!";

eval {
    $vol->upload($st, 0, 0);
    while (1) {
	my $nbytes = 1024;
	my $data;
	my $rv = sysread FILE, $data, $nbytes;
	if ($rv < 0) {
	    die "cannot read $f: $!";
	}
	last if $rv == 0;
	while ($rv > 0) {
	    my $done = $st->send($data, $rv);
	    if ($done) {
		$data = substr $data, $done;
		$rv -= $done;
	    }
	}
    }

    $st->finish();
};
if ($@) {
    close FILE;
    die $@;
}
close FILE or die "cannot save $f: $!";

