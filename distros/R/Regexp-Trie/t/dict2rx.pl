#!/usr/bin/env perl
#
# $Id: dict2rx.pl,v 0.1 2006/04/27 04:01:27 dankogai Exp $
#
use strict;
use warnings;
use  Regexp::Trie;

my $src = shift || die "$0 src [dst]";
my $dst = shift || "$src.rx";
my $trie = Regexp::Trie->new;

my $count;
$|=1;
open my $in, "<:raw", $src or die "$src : $!";
while(<$in>){
    chomp;
    $trie->add($_);
    ++$count % 1000 == 0 and print "$count\r";
}
close $in;
print "$count\n";
system ("ps v$$");
my $qr = $trie->regexp;
open my $out, ">:raw", $dst or die "$dst : $!";
print $out 'qr{'.$qr.'}';
close $out;
system ("ps v$$");

__END__
