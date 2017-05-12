#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Fcntl ':seek';
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 54;
use PerlIO::subfile;
ok(1); # If we made it this far, we're ok.

#########################

my @caps = ("AA\n", 'PAHOEHOE');
my @lower = ("one\n", "two\n", "three\n", "four\n", "five");
my @num = ("007\n", "655360\n");

my @whole;
my @sub;
my $sub_start;
my $sub_end;
my $i = 0;
my $j = 0;

open TEST, ">test" or die "Can't open file: $!";
binmode TEST;
foreach (@caps) {
  $whole[$i++] = tell TEST;
  print TEST $_;
}
$sub_start = tell TEST;
foreach (@lower) {
  $sub[$j++] = $whole[$i++] = tell TEST;
  print TEST $_;
}
$sub_end = tell TEST;
foreach (@num) {
  $whole[$i++] = tell TEST;
  print TEST $_;
}
$_ -= $sub_start foreach (@sub);
close TEST or die "Can't close file: $!";

# Right. Let's play

open TEST, "<test" or die "Can't open file: $!";
binmode TEST;

$!=0;
ok (seek (TEST, $sub_start, SEEK_SET),"seek to where subfile will start")
  or print "# seek failed with \$!=$!";

is (tell (TEST), $sub_start);

$!=0;
is (binmode (TEST, ":subfile"), 1, "Apply subfile discipline with binmode")
  or print "# binmode failed with \$!=$!";

is (tell (TEST), 0, "We should be at offset zero of the subfile");
is (scalar <TEST>, $lower[0]);
is (seek (TEST, 0, SEEK_SET), 1, "seek to the start of the subfile");
is (tell (TEST), 0, "We should be at offset zero of the subfile again");
is (scalar <TEST>, $lower[0]);

$!=0;
is (seek (TEST, length($lower[1]), SEEK_CUR), 1, "seek forwards")
  or print "# seek failed with \$!=$!";

is (scalar <TEST>, $lower[2]);
my $first_three = "$lower[0]$lower[1]$lower[2]";

$!=0;
is (seek (TEST, -length($first_three), SEEK_CUR), 1,
    "seek backwards to the start")
  or print "# seek failed with \$!=$!";

my $buffer;

$!=0;
ok (read (TEST, $buffer, length ($first_three)), "read first 3 lines")
  or print "# read failed with \$!=$!";

is ($buffer, $first_three);

$!=0;
is (seek (TEST, -1-length($first_three), SEEK_CUR), '',
    "Attempt to seek before the start of the subfile")
  or print "# Should have failed to seek backwards to before the start, \$!=$!";

is (scalar <TEST>, $lower[3]);
close TEST or die "Can't close file: $!";

my $caps_length = length (join '', @caps);
open TEST, "<:subfile(start=$caps_length)", "test" or die "Can't open file: $!";
# Hmm. I want tobinmode TEST; as part of the open.
is (tell (TEST), 0, "We should start at offset zero of the subfile");
is (scalar <TEST>, $lower[0]);
close TEST or die "Can't close file: $!";

my $lower_length = length (join '', @lower);
my $layerspec
  = sprintf "<:subfile(start=%d,end=+%d)", $caps_length, $lower_length;
open TEST, $layerspec, "test" or die "Can't open file with $layerspec: $!";
# Hmm. I want tobinmode TEST; as part of the open.
is (tell (TEST), 0, "We should start at offset zero of the subfile");
is (scalar <TEST>, $lower[0]);
my $line;
while (<TEST>) {
  $line = $_;
}
is ($line, $lower[-1], "That should be the last line");
is (eof TEST, 1, "Should be end of file");

$!=0;
is (seek (TEST, 0, SEEK_SET), 1, "seek to the start of the subfile")
  or print "# seek failed with \$!=$!";

is (scalar <TEST>, $lower[0]);

$!=0;
is (seek (TEST, -length $lower[-1], SEEK_END), 1,
    "seek to the last line of subfile")
  or print "# seek failed with \$!=$!";

is (scalar <TEST>, $lower[-1]);
is (eof TEST, 1, "Should be end of file again");
close TEST or die "Can't close file: $!";

# Should be able to do these as hex (or octal)
$layerspec =
  sprintf "<:subfile(start=%d,end=+0x%X)", $caps_length, $lower_length;
open TEST, $layerspec, "test" or die "Can't open file with $layerspec: $!";
is (seek (TEST, -length $lower[-1], SEEK_END), 1,
    "seek to last line of subfile")
  or print "# seek failed with \$!=$!";
is (scalar <TEST>, $lower[-1]);
is (eof TEST, 1, "Should be end of file again again");
# There was an old man called Michael Finnegan...
close TEST or die "Can't close file: $!";

open TEST, "test" or die "Can't open file: $!";
while ($lower[2] ne <TEST>) {
  die "We should not get to end of file." if eof TEST;
}
$layerspec = sprintf ":subfile(start=-%d)", length $first_three;

$!=0;
is (binmode (TEST, $layerspec), 1, "binmode '$layerspec'")
  or print "# failed with $!";

is (tell TEST, 0, "Binmode should take us to the start of the subfile");
while (<TEST>) {
  $line = $_;
}
is ($line, $num[-1], "This should be the last line of numbers");
# Right. We should be able to nest these.
$layerspec = sprintf ":subfile(start=0,end=%d)", $lower_length;

$!=0;
is (binmode (TEST, $layerspec), 1, "nest disciplines with another binmode")
    or print "# binmode '$layerspec' failed with $!";

{
  local $/;
  is (<TEST>, join ('', @lower), "slurp");
}

$!=0;
is (seek (TEST, length $lower[0], SEEK_SET), 1, "seek to the second line of the subfile")
  or print "# failed with $!";

is (scalar <TEST>, $lower[1]);

$!=0;
is (seek (TEST, -length($first_three), SEEK_CUR), '',
    "Attempt to seek before the start of the subfile")
    or print "# Should have failed to seek backwards to before the start, \$!=$!";

is (scalar <TEST>, $lower[2]);
# Right. this is within the outer subfile, but should still be beyond the
# inner subfile. Not sure that seek-beyond-end not failing is unix specific.

$!=0;
is (seek (TEST, length$num[0], SEEK_END), 1,
    "Attempt to seek beyond the end of the inner subfile. Passes on unix")
  or print "# Failed to seek beyond the end of the subfile, \$!=$!";

is (eof TEST, 1, "Beyond the end should indicate EOF");
ok (!defined scalar <TEST>, "should read undef as we are at eof");
close TEST or die "Can't close file: $!";

# And now, it should all work on a pipe, as long as we don't seek.
# perl -pe0 might be an alternative to cat on some platforms
# (platforms which I don't have access to to test on)

foreach my $layer (qw (perlio stdio unix)) {
  open (PIPE, "-|:$layer", "cat test") or die "Can't open pipe: $!";
  is ((read PIPE, $buffer, $caps_length), $caps_length,
      "read $caps_length to skip the capitals, layer $layer");
  $layerspec = sprintf ":subfile(end=%d)", $lower_length;
  is (binmode (PIPE, $layerspec), 1, "binmode '$layerspec'")
    or print "# failed with $!\n";
  is (scalar <PIPE>, $lower[0], "read first line");
  {
    local $/;
    local $TODO;
    $TODO = "Fix this for :perlio layer - however doesn't affect ex::lib::zip"
      if $layer eq 'perlio';
    is (<PIPE>, join ('', @lower[1..$#lower]), "slurp other lines");
  }
  close PIPE or die "Can't close pipe: $!";
}

while (-f "test") {
  unlink "test" or die "Can't unlink: $!";
}
