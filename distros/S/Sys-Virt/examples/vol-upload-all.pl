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

sub foo {
	my $st = $_[0];
	my $nbytes = $_[2];
        return sysread FILE, $_[1], $nbytes;
};

eval {
    $vol->upload($st, 0, 0);
    $st->send_all(\&foo);

    $st->finish();
};
if ($@) {
    close FILE;
    die $@;
}
close FILE or die "cannot save $f: $!";

