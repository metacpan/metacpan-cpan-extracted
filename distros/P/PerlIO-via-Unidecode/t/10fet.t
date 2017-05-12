# -*- coding:utf-8; mode:CPerl -*-
#======================================================================

use strict; use Test; BEGIN {plan tests => 6};
print "#\n# I am ", __FILE__, "\n#  ",
  q[ with Time-stamp: "2014-07-27 02:24:45 MDT sburke@cpan.org"],
  "\n#\n",
;

ok 1;
require PerlIO::via::Unidecode;

use strict;

my $fet_raw_koi8 = join '',  map( chr(hex($_)),
    q[
      eb cf c7 c4 c1   20   de c9 d4 c1 cc c1   20   d4 d9
      0a
      cd d5 de c9 d4 c5 cc d8 ce d9 c5   20   d3 d4 d2 cf cb c9
    ]
  =~ m<(\S+)>g )
;

# That's the KOI-8 encoding of the first line of the poem "When you were
# reading those tormented lines" by Afanasy Afanasevich Fet.


my $fet_fs = 'koi8r.txt';
{
  print "# Creating time file $fet_fs\n";
  open my $FET, ">", $fet_fs    or    die "Can't write-open $fet_fs: $!";
  binmode($FET) or die "Can't binmode $fet_fs - $!";

  print "# Writing ", length($fet_raw_koi8), " bytes of KOI8 to it.\n";
  print $FET $fet_raw_koi8;
  ok 1;

  close($FET) or die "Can't close write-file $fet_fs - $!";
  ok 1;
}

my $unidecoded;
{
  my $Layer = '<:encoding(koi8-r):via(Unidecode)';
  print "#Opening $fet_fs with layer: $Layer\n";
  open(
       my $IN,
       $Layer,
       $fet_fs
    )  or die $!;
  $unidecoded = join '', readline($IN);
  die "Can't read from $fet_fs" unless $unidecoded;
  close($IN);
  $unidecoded =~ s/^\s+//s;
  $unidecoded =~ s/\s+$//s;
  $unidecoded =~ s/\s+/ /g;
}

ok $unidecoded, qr/\S+/; # basic sanity: that it has content

# It should be something like: "Koghda chitala ty muchitiel'nyie stroki"
{
  my $u = $unidecoded;
  $u =~ s/\n//g;
  print "# Got: $u\n";
}

ok( $unidecoded, qr/^Kog .+ tala .+ strok .+ /msx );

# If Unidecode's Cyrillic tables change, then the precise transliteration
# could change.  But I'm just betting on at least those things being okay.

unlink $fet_fs or die "Can't unlink temp-file $fet_fs - $!";

ok 1;
