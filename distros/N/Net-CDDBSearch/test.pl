BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::CDDBSearch;
$loaded = 1;
print "ok 1\n";


$cddb = Net::CDDBSearch->new();
$cddb->get_albums_artist('Megadeth');
$albums = $cddb->albums();
push(@s,$_) foreach keys %{$albums};
if ($#s > 0) { print "ok 2\n"; } else { print "not ok 2\n"; }

$cddb = Net::CDDBSearch->new();
$cddb->get_albums_album('Youthanasia');
$albums = $cddb->albums();
push(@a,$_) foreach keys %{$albums};
if ($#a > 0) { print "ok 3\n"; } else { print "not ok 3\n"; }

$cddb = Net::CDDBSearch->new();
$cddb->get_songs_album($a[0]);
$info   = $cddb->info();
$tracks = $cddb->tracks();
if ($info->{Title} ne '') { print "ok 4\n"; } else { print "not ok 4\n"; }
push(@t,$_) foreach keys %{$tracks};
if ($#t > 0) { print "ok 5\n"; } else { print "not ok 5\n"; }
