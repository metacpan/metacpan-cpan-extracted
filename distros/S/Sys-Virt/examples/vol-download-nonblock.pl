#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;

Sys::Virt::Event::register_default();

my $c = Sys::Virt->new(uri => "qemu:///session");

my $st = $c->new_stream(Sys::Virt::Stream::NONBLOCK);

die "syntax: $0 VOL-PATH OUTPUT-FILE" unless int(@ARGV) == 2;

my $volpath = shift @ARGV;
my $f = shift @ARGV;

my $vol = $c->get_storage_volume_by_path($volpath);

my $quit = 0;

open FILE, ">$f" or die "cannot create $f: $!";

sub streamevent {
    my $st = shift;
    my $events = shift;

    if ($events & (Sys::Virt::Stream::EVENT_HANGUP |
		   Sys::Virt::Stream::EVENT_ERROR)) {
	$quit = 1;
	return;
    }

    my $data;
    my $rv = $st->recv($data, 1024);

    if ($rv == 0) {
	$quit = 1;
	$st->remove_callback();
	return;
    }

    while ($rv > 0) {
	my $ret = syswrite FILE, $data, $rv;
	$data = substr $data, $ret;
	$rv -= $ret;
    }
}

eval {
    $vol->download($st, 0, 0);

    $st->add_callback(Sys::Virt::Stream::EVENT_READABLE, \&streamevent);

    while (!$quit) {
	Sys::Virt::Event::run_default();
    }
    $st->finish();
};

if ($@) {
    unlink $f if $@;
    close FILE;
    die $@;
}
close FILE or die "cannot save $f: $!";

