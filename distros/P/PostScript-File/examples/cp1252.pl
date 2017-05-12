#! /usr/bin/perl
#---------------------------------------------------------------------
# This example is hereby placed in the public domain.
# You may copy from it freely.
#
# This displays the Windows cp1252 character set.
#---------------------------------------------------------------------

use strict;
use warnings;

use PostScript::File 1.05;      # Need cp1252 support

my $ps = PostScript::File->new(
  paper    => 'letter',
  reencode => 'cp1252', # Best available Unicode support (still not much)
  auto_hyphen => 0,     # We don't want any hyphen translation
  need_fonts  => ['Helvetica'],
  left     => 72,
  top      => 72,
);

$ps->add_to_page( <<END_PAGE );
    /Helvetica-iso findfont
    16 scalefont
    setfont

    212 700 moveto
    (Windows Code Page 1252) show
END_PAGE

my $char = 32;

my ($xMar, $y) = ($ps->get_bounding_box)[0,3];

my $xStep = 26;
my $yStep = 24;

my $xLeft = $xMar + 50;
$y -= 2 * $yStep;

for my $i (0 .. 0xF) {
  $ps->add_to_page(sprintf "%d %d moveto\n%s show\n",
                   $xLeft + $i * $xStep, $y,
                   $ps->pstr(sprintf '%X', $i));
}

while ($char < 0x100) {
  $y -= $yStep;

  $ps->add_to_page(sprintf "%d %d moveto\n%s show\n",
                     $xMar, $y,
                     $ps->pstr(sprintf '0x%X_', $char/16));

  for my $i (0 .. 0xF) {
    $ps->add_to_page(sprintf "%d %d moveto\n%s show\n",
                     $xLeft + $i * $xStep, $y,
                     $ps->pstr(pack('C', $char++)));
  }
}

printf "Wrote %s...\n", $ps->output("cp1252", $ENV{TMP});
