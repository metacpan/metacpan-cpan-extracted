#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon #':silent',
                 qw/bug tmpcopy_if_writeable $debug/;
use LpodhTestUtils qw/append_para verif_normalized/;

use ODF::lpOD;
use ODF::lpOD_Helper;

my $doc = odf_create_document("text");
my $body = $doc->get_body;

for my $textspec (
  ["YYY[","aa  ","ccc"], # bug found via ODF::MailMerge
  ["","",""], ["","","C"], ["A","",""],
  ["  ","ZZZ"], ["A  ","ZZZ"],
  [" "," ZZZ"], [" ","  ZZZ"], ["  ","  ZZZ"],
  "", " ", "  ", "   ", "A\tB\nC\tD",
  "YYY[aa  ccc]",
) {
  my $frame = $body->insert_element('draw:frame', position => LAST_CHILD);
  scope_guard { $frame->delete };

  my $para = append_para($frame, $textspec);
  my $text = ref($textspec) ? join("", @$textspec) : $textspec;
  $para->Hnormalize();
  is($para->Hget_text, $text, "Hnormalize ".visq($textspec));
  verif_normalized($para);
}

done_testing;
