#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug tmpcopy_if_writeable $debug/;

my %dvb = (map{ do{ no strict 'refs'; defined(${$_}) ? ($_ => ${$_}) : () }
              } qw/debug verbose silent/);

use Data::Dumper::Interp qw/visnew ivis dvis vis hvis avis u/;

use ODF::lpOD;

my ($def_INPUT_CHARSET, $def_OUTPUT_CHARSET);
BEGIN {
  die "Default ODF::lpOD::Common::INPUT_CHARSET is unexpectedly undef"
    unless defined($def_INPUT_CHARSET = $ODF::lpOD::Common::INPUT_CHARSET);
  die "Default ODF::lpOD::Common::OUTPUT_CHARSET is unexpectedly undef"
    unless defined($def_OUTPUT_CHARSET = $ODF::lpOD::Common::OUTPUT_CHARSET);
}

use ODF::lpOD_Helper qw/:bytes :DEFAULT/;

is($ODF::lpOD::Common::INPUT_CHARSET, $def_INPUT_CHARSET, 
   ":bytes leaves INPUT_CHARSET unchanged");
is($ODF::lpOD::Common::OUTPUT_CHARSET, $def_INPUT_CHARSET, 
   ":bytes leaves OUTPUT_CHARSET unchanged");

use Encode qw/encode decode/;

my $skel_path = "$Bin/../tlib/Skel.odt";
my $input_path = tmpcopy_if_writeable($skel_path);
my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;

my $ascii_only_re= qr/This.*Para.*has.*Unicode/;

my $smiley_char = "☺"; 
my $justsmiley_re = qr/${smiley_char}/;
my $full_char_re = qr/This.*Para.*${smiley_char}.*Unicode.*text\./;

my $smiley_octets = encode("UTF-8", $smiley_char, Encode::LEAVE_SRC);
my $justsmiley_octet_re = qr/${smiley_octets}/;
my $full_octet_re = qr/This.*Para.*${smiley_octets}.*Unicode.*text\./;

bug unless length($ascii_only_re) == do{ use bytes; my $x=length($ascii_only_re) };

sub check_search_chars($) {
  my $octet_mode = shift;
  # search() for a wide char results in a "wide character" error from decode()
  # inside ODF::lpOD unless implicit encoding is disabled
  my $m = eval{ $body->search($smiley_char) };
  if ($octet_mode) { # implicit encoding enabled
    # Sometimes inexplicably does not fail in cpantesters land...
    # I've tested this with LANG=C so there should be no default
    # STD* encoding going on.  Hmm...
    ok(!defined($m) && $@ =~ /wide char/i, 
       "bytes mode: search(wide char) blows up (string)",
       dvis '$ODF::lpOD::Common::INPUT_CHARSET\n',
       dvis '$ODF::lpOD::Common::OUTPUT_CHARSET\n',
       dvis '$m\n$@\n segment ->\n',
                   u(eval{ fmt_tree($m->{segment}//undef) }),"\n",
                   do{ my @lay = PerlIO::get_layers(*STDOUT);
                       join(" ", " STDOUT layers:", @lay ) 
                     }
    );
  } else {
    ok($m->{segment}, "chars mode: search(wide char) works (string)",
       dvis '$m\n$@\n');
  }

  $m = eval{ $body->search(qr/$smiley_char/) };
  if ($octet_mode) { # implicit encoding enabled
    # An exception is thrown when ODF::lpOD calles decode() on it's input
    # argument if it contains abstract "wide" characters
    ok(!defined($m) && $@ =~ /wide char/i, 
       "bytes mode: search(wide char) blows up (regex)",
       dvis '$m\n$@\n');
  } else {
    ok($m->{segment}, "chars mode: search(wide char) works (regex)",
       dvis '$m\n$@\n');
  }

  # But Hsearch does not throw because it does not try to decode() it's args
  # and will not try to encode the result
  my @m = eval{ $body->Hsearch($smiley_char) };
  if ($octet_mode) {
    ok(@m==0 && $@ eq "", 
       "bytes mode: Hsearch(wide char) fails as expected",
       dvis '$@  \@m=', join("\n   ", map{fmt_match} @m)
      );
  } else {
    ok(@m > 0 && $@ eq "", 
       "chars mode: Hsearch(wide char) works", 
       dvis '\n@m\n');
  }
}
sub check_search_octets($) {
  my $octet_mode = shift;
  # search() works with octets by default
  my $m = eval{ $body->search(${smiley_octets}) };
  if ($octet_mode) {
    ok($m->{segment}, "bytes mode: search(octets) works");
    my $p = $m->{segment}->get_parent_paragraph;
    my $p_text = $p->get_text();  # the full text of the para
    like($p_text, qr/$full_octet_re/, "bytes mode: get_text() returns octets")
      || say visnew->dvis('$p_text\n$full_octet_re p=\n').fmt_tree($p);
    bug unless $p_text =~ qr/$ascii_only_re/;
  } else {
    ok(!defined($m->{segment}), "search(octets) fails in chars mode")
      || diag dvis '\n$m\n';
  }
  my @m = eval{ $body->Hsearch($smiley_octets, %dvb) };
  if ($octet_mode) { 
    ok(@m > 0, "bytes mode: Hsearch(octets) works",
       dvis '\n@m\n$@\n');
  } else {
    ok(@m==0 && $@ eq "", "Hsearch(octets) fails in chars mode", 
       dvis '\n@m\n$@\n');
  }
}

# Initially using the ":bytes" import tag
check_search_chars(1);
check_search_octets(1);

note "=== Switching to character mode ===";
lpod->Huse_character_strings();
check_search_chars(0);
check_search_octets(0);

note "=== Switching back to bytes mode ===";
lpod->Huse_octet_strings();
check_search_chars(1);
check_search_octets(1);

note "=== eval \"use ODF::lpOD_Helper witout ':bytes'\" ===";
eval "use ODF::lpOD_Helper;";
check_search_chars(0);
check_search_octets(0);

note "=== eval \"use ODF::lpOD_Helper with ':bytes' (conflicting)\" ===";
eval "use ODF::lpOD_Helper ':bytes';";
note $@ if $debug;
like($@, qr/previously loaded without :bytes/, "Conflicting :bytes diagnosed");

done_testing();
