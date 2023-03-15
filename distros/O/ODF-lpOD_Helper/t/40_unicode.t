#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Setup qw/bug :silent/; # strict, warnings, Test::More, Carp etc.

use Data::Dumper::Interp qw/visnew ivis dvis vis hvis avis u/;

use ODF::lpOD;
use ODF::lpOD_Helper qw/:DEFAULT fmt_node fmt_match fmt_tree/;
use Encode qw/encode decode/;

my $skel_path = "$Bin/../tlib/Skel.odt";

my $ascii_only_re= qr/This.*Para.*has.*characters./;

my $smiley_char = "☺"; 
my $justsmiley_re = qr/${smiley_char}/;
my $full_char_re = qr/This.*Para.*${smiley_char}.*characters./;

my $smiley_octets = encode("UTF-8", $smiley_char, Encode::LEAVE_SRC);
my $justsmiley_octet_re = qr/${smiley_octets}/;
my $full_octet_re = qr/This.*Para.*${smiley_octets}.*characters./;

bug unless length($ascii_only_re) == do{ use bytes; my $x=length($ascii_only_re) };

my $doc = odf_get_document($skel_path);

#my $content = $doc->get_part(CONTENT);
#my $body = $content->get_body;  # NOT the same as doc->get_body (why??)
my $body = $doc->get_body;

{ # search() for a wide char results in a "wide character" error from decode()
  # inside ODF::lpOD
  my $m = eval { $body->search($smiley_char) };
  ok(!defined($m) && $@ =~ /wide char/i, "default: search(wide char) blows up (string)");
  $m = eval{ $body->search(qr/$justsmiley_re/) };
  ok(!defined($m) && $@ =~ /wide char/i, "default: search(wide char) blows up (regex)");
}
{ # But search() works with octets by default
  my $m = $body->search(${smiley_octets});
  ok($m->{segment}, "default: search(octets) works (string)");
  $m = $body->search(qr/${smiley_octets}/);
  ok($m->{segment}, "default: search(octets) works (regex)");
  my $p = $m->{segment}->get_parent_paragraph;
  my $p_text = $p->get_text();  # the full text of the para
  like($p_text, qr/$full_octet_re/, "default: get_text() returns octets");
  bug unless $p_text =~ qr/$ascii_only_re/;
}
{ # Hsearch for a wide char does not work by default
  my @m = $body->Hsearch($smiley_char);
  ok(@m==0, "default: Hsearch(wide char) fails (string)");
  @m = $body->Hsearch(qr/$justsmiley_re/);
  ok(@m==0, "default: Hsearch(wide char) fails (regex)");
}

{ # The paragraph is fragmented, so we can not search for the whole text
  my $m = $body->search(qr/$full_octet_re/);
  ok(!defined($m->{segment}), "search(octets) can not span segments");
  $m = $body->search(qr/$ascii_only_re/);
  ok(!defined($m->{segment}), "search(ascii only) can not span segments");
}
{ 
  my @m = $body->Hsearch(qr/$full_octet_re/);
  ok(@m && $m[0]->{match} =~ qr/$full_octet_re/, "Hsearch(octets) CAN span segments");
  @m = $body->Hsearch(qr/$ascii_only_re/);
  ok(@m && $m[0]->{match} =~ qr/$full_octet_re/, "Hsearch(ascii only) CAN span segments");
}

#-----------------------------------------------------------------
# Now enable character params by default, no encode/decode needed
lpod->Huse_character_strings();
#-----------------------------------------------------------------

{ # search() for a wide char should work now
  my $m = $body->search($smiley_char);
  ok($m->{segment}, "After Huse_character_strings: search(wide char) works (string)");
  $m = $body->search(qr/$justsmiley_re/);
  ok($m->{segment}, "After Huse_character_strings: search(wide char) works (regex)"); 
  my $p = $m->{segment}->get_parent_paragraph;
  my $p_text = $p->get_text();  # the full text of the para
  like($p_text, qr/$full_char_re/, "After Huse_character_strings: get_text() returns characters");
}
{ # But search() with octets now fails
  my $m = $body->search(${smiley_octets});
  ok(!($m && $m->{segment}), "After Huse_character_strings: search(octets) fails (string)");
  $m = $body->search(qr/${smiley_octets}/);
  ok(!($m && $m->{segment}), "After Huse_character_strings: search(octets) fails (regex)");
}
{
  my @m = $body->Hsearch($smiley_char);
  ok(@m>0 && $m[0]->{match} eq $smiley_char, "After Huse_character_strings: Hsearch(wide char) works (string)");
  @m = $body->Hsearch(qr/$justsmiley_re/);
  ok(@m>0 && $m[0]->{match} eq $smiley_char, "After Huse_character_strings: Hsearch(wide char) works (regex)");
}

{ my $match = $body->Hsearch(qr/$full_char_re/);
  ok( @{$match->{segments}} > 1 
        && $match->{match} =~ qr/$full_char_re/, 
      "After Huse_character_strings: Hsearch(unicode) matches multiple segments" );
}

done_testing();
