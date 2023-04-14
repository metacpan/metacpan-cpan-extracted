#!/usr/bin/perl

use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug ok_with_lineno like_with_lineno
                    rawstr showstr showcontrols displaystr 
                    show_white show_empty_string
                    fmt_codestring 
                    timed_run
                    checkeq_literal check _check_end
                  /;

use Data::Dumper::Interp qw/visnew ivis dvis vis hvis avis u/;

use ODF::lpOD;
# Note - initially WITHOUT ':chars'
use ODF::lpOD_Helper qw/:DEFAULT fmt_node fmt_match fmt_tree/;

use Encode qw/encode decode/;

my $skel_path = "$Bin/../tlib/Skel.odt";

my $ascii_only_re= qr/This.*Para.*has.*Unicode/;

my $smiley_char = "☺"; 
my $justsmiley_re = qr/${smiley_char}/;
my $full_char_re = qr/This.*Para.*${smiley_char}.*Unicode.*text\./;

my $smiley_octets = encode("UTF-8", $smiley_char, Encode::LEAVE_SRC);
my $justsmiley_octet_re = qr/${smiley_octets}/;
my $full_octet_re = qr/This.*Para.*${smiley_octets}.*Unicode.*text\./;

bug unless length($ascii_only_re) == do{ use bytes; my $x=length($ascii_only_re) };

my $doc = odf_get_document($skel_path);

#my $content = $doc->get_part(CONTENT);
#my $body = $content->get_body;  # NOT the same as doc->get_body (why??)
my $body = $doc->get_body;

sub check_search_chars($) {
  my $octet_mode = shift;
  # search() for a wide char results in a "wide character" error from decode()
  # inside ODF::lpOD unless implicit encoding is disabled
  my $m = eval{ $body->search($smiley_char) };
  if ($octet_mode) { # implicit encoding enabled
    ok(!defined($m) && $@ =~ /wide char/i, "default: search(wide char) blows up (string)")
      # Sometimes inexplicably does not fail in cpantesters land...
      # I've tested this with LANG=C so there should be no default
      # STD* encoding going on.  Hmm...
      || diag dvis '$m\n$@\n segment ->\n',
                   u(eval{ fmt_tree($m->{segment}//undef) }),"\n",
                   do{ my @lay = PerlIO::get_layers(*STDOUT);
                       join(" ", " STDOUT layers:", @lay ) }
  } else {
    ok($m->{segment}, "With :chars, search(wide char) works (string)")
      || diag dvis '$m\n$@\n';
  }

  $m = eval{ $body->search(qr/$smiley_char/) };
  if ($octet_mode) { # implicit encoding enabled
    # An exception is thrown when ODF::lpOD calles decode() on it's input
    # argument if it contains abstract "wide" characters
    ok(!defined($m) && $@ =~ /wide char/i, "default: search(wide char) blows up (regex)")
      || diag dvis '$m\n$@\n';
  } else {
    ok($m->{segment}, "With :chars, search(wide char) works (regex)")
      || diag dvis '$m\n$@\n';
  }

  # But Hsearch does not throw because it does not try to decode() it's args
  # and will not try to encode the result
  my @m = eval{ $body->Hsearch($smiley_char) };
  oops($@) if $@;
  if ($octet_mode) {
    ok(@m==0, "default: Hsearch(wide char) fails as expected")
      || diag(dvis '$@  \@m=', join("\n   ", map{fmt_match} @m));
  } else {
    oops if $@;
    ok(@m > 0, "With :chars, Hsearch(wide char) works")
      || diag dvis '\n@m\n';
  }
}
sub check_search_octets($) {
  my $octet_mode = shift;
  # search() works with octets by default
  my $m = eval{ $body->search(${smiley_octets}) };
  if ($octet_mode) {
    ok($m->{segment}, "default(octet mode): search(octets) works");
    my $p = $m->{segment}->get_parent_paragraph;
    my $p_text = $p->get_text();  # the full text of the para
    like($p_text, qr/$full_octet_re/, "default: get_text() returns octets")
      || say visnew->dvis('$p_text\n$full_octet_re p=\n').fmt_tree($p);
    bug unless $p_text =~ qr/$ascii_only_re/;
  } else {
    ok(!defined($m->{segment}), "search(octets) fails in :chars mode")
      || diag dvis '\n$m\n';
  }
  my @m = eval{ $body->Hsearch($smiley_octets) };
  if ($octet_mode) { 
    ok(@m > 0, "default(octet mode): Hsearch(octets) works")
      || diag dvis '\n@m\n';
  } else {
    ok(@m==0, "Hsearch(octets) fails in :chars mode")
      || diag dvis '\n@m\n';
  }
}

# The default (without the ":chars" import tag) is octet mode
check_search_chars(1);
check_search_octets(1);

note "=== Switching to character mode ===";
lpod->Huse_character_strings(); # turn on :chars mode
check_search_chars(0);
check_search_octets(0);

note "=== Switching back to octet mode ===";
lpod->Huse_octet_strings(); 
check_search_chars(1);
check_search_octets(1);

note "=== eval \"use ODF::lpOD_Helper ':chars'\" ===";
eval "use ODF::lpOD_Helper ':chars'";
check_search_chars(0);
check_search_octets(0);

done_testing();
