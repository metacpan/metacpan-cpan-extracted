#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;

Sys::Virt::Event::register_default();

my $c = Sys::Virt->new(uri => "qemu:///session");

my $st = $c->new_stream(Sys::Virt::Stream::NONBLOCK);

die "syntax: $0 VOL-PATH INPUT-FILE" unless int(@ARGV) == 2;

my $volpath = shift @ARGV;
my $f = shift @ARGV;

my $vol = $c->get_storage_volume_by_path($volpath);

my $quit = 0;

open FILE, "<$f" or die "cannot open $f: $!";

my $nextdata;
my $nextdatalen;

sub moredata {
    return if $nextdatalen;
    $nextdatalen = sysread FILE, $nextdata, 1024;
}

sub streamevent {
    my $st = shift;
    my $events = shift;

    if ($events & (Sys::Virt::Stream::EVENT_HANGUP |
		   Sys::Virt::Stream::EVENT_ERROR)) {
	$quit = 1;
	return;
    }

    &moredata;
    if ($nextdatalen == 0) {
	$quit = 1;
	$st->remove_callback();
	return;
    }
    my $rv = $st->send($nextdata, $nextdatalen);

    if ($rv > 0) {
	$nextdata = substr $nextdata, $rv;
	$nextdatalen -= $rv;
    }
}

eval {
    $vol->upload($st, 0, 0);

    $st->add_callback(Sys::Virt::Stream::EVENT_WRITABLE, \&streamevent);

    while (!$quit) {
	Sys::Virt::Event::run_default();
    }
    $st->finish();
};
if ($@) {
    close FILE;
    die $@;
}
close FILE or die "cannot save $f: $!";

