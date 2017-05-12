#!/usr/bin/perl

use Net::CDDBSearch;

my $cddb = Net::CDDBSearch->new();


# example 3
# We've got albums list (see example 1 or 2), so we need to get album info and 
# track list for one of them ('Youthanasia' for example)
# we can get link for it : 'http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=ae0bba0c'
$cddb->get_songs_album('http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=ae0bba0c');
$info   = $cddb->info();
$tracks = $cddb->tracks();

print "Info about album : 'http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=ae0bba0c'\n";
print $_,"\t ==> ",$info->{$_},"\n" foreach keys %{$info};
print "Track list :\n";
print "\t",$_," : ",$tracks->{$_}, "\n" foreach (sort keys %{$tracks});

exit;