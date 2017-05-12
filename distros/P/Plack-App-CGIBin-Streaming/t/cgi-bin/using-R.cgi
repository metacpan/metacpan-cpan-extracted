#!/usr/bin/perl

use strict;
use warnings;
use Plack::App::CGIBin::Streaming;

BEGIN {push @main::loaded, __FILE__}

my $r=Plack::App::CGIBin::Streaming->request;

my @args=split /,/, $ENV{QUERY_STRING};

my $pc;
my $cl=1;
my $flush_after;
for (my $i=0; $i<@args; $i+=2) {
    my ($k, $v)=@args[$i, $i+1];

    for ($k) {
        /^status$/ and $r->status=$v, next;
        /^H$/ and $r->print_header(split /:/, $v), next;
        /^pc$/ and $r->print_header('pc', 1), $pc=1, next;
        /^cl$/ and $cl=$v, next;
        /^ct$/ and $r->content_type($v), next;
        /^flush_after$/ and $flush_after=$v, next;
    }
}

my $len=0;
if ($pc) {
    for (1..int($cl/100)) {
        $r->print_content('x' x 100);
        $len+=100;
        if ($flush_after and $flush_after<=$len) {
            $r->print_content("<!-- FlushHead -->\nflushed\n");
            $len=0;
        }
    }
    $r->print_content('x' x ($cl%100));
    $len+=$cl%100;
    if ($flush_after and $flush_after<=$len) {
        $r->print_content("<!-- FlushHead -->\nflushed\n");
    }
} else {
    for (1..int($cl/100)) {
        print('x' x 100);
        $len+=100;
        if ($flush_after and $flush_after<=$len) {
            print "\nflushed\n<!-- FlushHead -->";
            $len=0;
        }
    }
    print('x' x ($cl%100));
    $len+=$cl%100;
    if ($flush_after and $flush_after<=$len) {
        print "\nflushed\n<!-- FlushHead -->";
    }
}
