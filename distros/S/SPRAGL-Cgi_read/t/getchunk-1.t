#!/usr/bin/perl
# t/getchunk-1.pl
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

my $dir;
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $dir = dirname(abs_path($0)) =~ s/[^\/]+$/lib/r;
    };

use lib $dir;
use_ok 'SPRAGL::Cgi_read::Getchunk';

my $s;
$s->$* = 'Det Røde Hus lå på en høj, mod vest omgivet
af et oversvømmet område. Araucaria-træerne på
den anden side af gitteret mildnede ikke dets
tunge udseende. I stedet for flade tage var der
skrå skifertage og et kvadratisk tårn med et ur, og
alt dette syntes at sammentrykke murene og de
sparsomme vinduer.';

my ($s1,$eoc1) = readchunk($s,'...','..','.');
ok ($s1->$* eq 'Det Røde Hus lå på en høj, mod vest omgivet
af et oversvømmet område');
ok ($eoc1 eq '.');

my ($s2,$eoc2) = readchunk($s,'. I stedet','.');
ok ($s2->$* eq ' Araucaria-træerne på
den anden side af gitteret mildnede ikke dets
tunge udseende');
ok ($eoc2 eq '. I stedet');

my ($s3,$eoc3) = readchunk($s,'.');
ok ($s3->$* eq ' for flade tage var der
skrå skifertage og et kvadratisk tårn med et ur, og
alt dette syntes at sammentrykke murene og de
sparsomme vinduer');
ok ($eoc3 eq '.');

ok ($s->$* eq 'Det Røde Hus lå på en høj, mod vest omgivet
af et oversvømmet område. Araucaria-træerne på
den anden side af gitteret mildnede ikke dets
tunge udseende. I stedet for flade tage var der
skrå skifertage og et kvadratisk tårn med et ur, og
alt dette syntes at sammentrykke murene og de
sparsomme vinduer.');

__END__
