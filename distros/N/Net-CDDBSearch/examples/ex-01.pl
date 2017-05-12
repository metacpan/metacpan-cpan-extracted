#!/usr/bin/perl

use Net::CDDBSearch;

my $cddb = Net::CDDBSearch->new();

# example 1
# We need to find all albums for particular artist
$cddb->get_albums_artist('Megadeth');
$albums = $cddb->albums();

print "You asked : '$cddb->{QUERY}'\n";
print "Founded .....\n";
print $_,"\t ==> ",@{$albums->{$_}}[0],' : ',@{$albums->{$_}}[1], "\n" foreach keys %{$albums};

exit;