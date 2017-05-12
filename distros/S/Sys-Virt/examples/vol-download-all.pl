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

sub foo {
	my $st = shift;
	my $data = shift;
	my $nbytes = shift;
	return syswrite FILE, $data, $nbytes;
};

eval {
    $vol->download($st, 0, 0);
    $st->recv_all(\&foo);

    $st->finish();
};
if ($@) {
    unlink $f if $@;
    close FILE;
    die $@;
}
close FILE or die "cannot save $f: $!";

