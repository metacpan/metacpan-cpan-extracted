#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops btw/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon #':silent',
                 qw/bug tmpcopy_if_writeable $debug/;
use Capture::Tiny ();
use utf8; # just to be certain

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

my $smiley_char = "\N{U+263A}";  # ☺
my $justsmiley_re = qr/${smiley_char}/;

my $smiley_octets = encode("UTF-8", $smiley_char, Encode::LEAVE_SRC);
my $justsmiley_octet_re = qr/${smiley_octets}/;

my $full_char_re = qr/This.*Para.*${smiley_char}.*Unicode.*text\./;
my $full_octet_re = qr/This.*Para.*${smiley_octets}.*Unicode.*text\./;

bug unless length($ascii_only_re) == do{ use bytes; my $x=length($ascii_only_re) };

sub check_search_chars($) {
  my $octet_mode = shift;
  # search() for a wide char results in a "wide character" error from decode()
  # inside ODF::lpOD unless implicit encoding is disabled
  #
  my $m = eval{ $body->search($smiley_char) };
  if ($octet_mode) { # implicit encoding enabled
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

  # 3/27/24: It seems that older Perls (5.2x.y) can not decode(qr/.../) ;
  # '' is returned with warn "Use of uninitialized value in subroutine entry"
  # This effectively means search(qr/.../) can not be used with older perls
  # if ODF::lpOD is in it's default mode where all arguments are decoded
  # before they are used, such as with "use ODF::lpOD_Helper ':bytes';".
  #
  # AND it means our test will not cause an exception!
  # So do _not_ pass a compiled regex in :bytes mode when using older perls!
  #
  SKIP: {
    skip "Perl version ($]) too old to test search(qr/.../) in :bytes mode"
      if $octet_mode && (!defined($^V) or $^V  lt v5.26.0);
    $m = eval{ $body->search(qr/$smiley_char/) };
    my $ex = $@;
    if ($octet_mode) { # implicit encoding enabled
      isnt($ODF::lpOD::Common::INPUT_CHARSET, undef,
          dvis '$ODF::lpOD::Common::INPUT_CHARSET $ODF::lpOD::VERSION $ex');
      if (defined $m) {
        die dvis 'UNEXPECTEDLY DEFINED $m\n$ex\n';
##        diag dvis 'UNEXPECTEDLY DEFINED $m\n$ex';
##        my ($out,$err,$stat) = Capture::Tiny::capture {
##           no warnings FATAL => 'all'; no warnings; use warnings;  # undo FATAL
##           my $bytes_regex = qr/$smiley_char/;
##           btw dvis '$ODF::lpOD::Common::INPUT_CHARSET $ODF::lpOD::Common::INPUT_ENCODER';
##           my $bytes_regex_copy = $bytes_regex;
##
##           my $xdecoded_regex;
##           # Some smokers die in the following evals
##           # with "uninitialized value in subroutine entry". WHY??
##           eval{ $xdecoded_regex = $ODF::lpOD::Common::INPUT_ENCODER->decode($bytes_regex_copy) };
##           btw dvis '$xdecoded_regex $@';
##
##           my $decoded_regex = eval{ $ODF::lpOD::Common::INPUT_ENCODER->decode($bytes_regex_copy) };
##           btw dvis '$decoded_regex $@';
##
##           my $ydecoded_regex;
##           $ydecoded_regex = $ODF::lpOD::Common::INPUT_ENCODER->decode($bytes_regex_copy);
##           btw dvis '$ydecoded_regex';
##
##           my $m2 = eval{ $body->search($bytes_regex) };
##           btw dvis '$bytes_regex $m2 $@';
##           my $m3 = eval{ $body->search(qr/${smiley_char}Unicode/) };
##           btw dvis '$smiley_char $m3 $@';
##           btw dvis 'body:', fmt_tree($body);
##        };
##        fail("bytes mode problem",
##             dvis('$m\n')."OUT:$out<END stdout>\nERR:$err<END stderr>\n");
      }
      ok(!defined($m) && $@ =~ /wide char/i,
         "bytes mode: search(wide char) blows up (regex)",
         dvis '$m\n$@\nbody:'.fmt_tree($body));
    } else {
      is($ODF::lpOD::Common::INPUT_CHARSET, undef,
          dvis '$ODF::lpOD::Common::INPUT_CHARSET $ODF::lpOD::VERSION');
      ok($m->{segment}, "chars mode: search(wide char) works (regex)",
         dvis '$m\n$@\n');
    }
  }#SKIP:

  # But Hsearch does not throw because it does not try to decode() it's args
  # and will not try to encode the result.  However it will not match
  # wide characters because __leaf2vtext() returns octets in :bytes mode.
  my @m = eval{ $body->Hsearch($smiley_char) };
  if ($octet_mode) {
    ok(@m==0 && $@ eq "",
       "bytes mode: Hsearch(wide char) fails as expected",
       dvis '$@\n$ODF::lpOD::Common::INPUT_CHARSET\n$ODF::lpOD::Common::OUTPUT_CHARSET\n@m=', join("\n   ", map{fmt_match} @m)
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
