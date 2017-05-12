#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;


my $c = Sys::Virt->new(uri => "qemu:///session");

my $st = $c->new_stream();

die "syntax: $0 VOL-PATH OUTPUT-FILE" unless int(@ARGV) == 2;

my $volpath = shift @ARGV;
my $f = shift @ARGV;

my $vol = $c->get_storage_volume_by_path($volpath);

open FILE, ">$f" or die "cannot create $f: $!";

eval {
    $vol->download($st, 0, 0);
    while (1) {
	my $nbytes = 1024;
	my $data;
	my $rv = $st->recv($data, $nbytes);
	last if $rv == 0;
	while ($rv > 0) {
	    my $done = syswrite FILE, $data, $rv;
	    if ($done) {
		$data = substr $data, $done;
		$rv -= $done;
	    }
	}
    }

    $st->finish();
};
if ($@) {
    unlink $f if $@;
    close FILE;
    die $@;
}
close FILE or die "cannot save $f: $!";

