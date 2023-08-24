#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug tmpcopy_if_writeable $debug/;

use LpodhTestUtils qw/verif_normalized/;

use ODF::lpOD;
use ODF::lpOD_Helper;
BEGIN {
  *_abbrev_addrvis = *ODF::lpOD_Helper::_abbrev_addrvis;
  *TEXTLEAF_COND   = *ODF::lpOD_Helper::TEXTLEAF_COND;
  *PARA_COND       = *ODF::lpOD_Helper::PARA_COND;
  *__leaf2vtext    = *ODF::lpOD_Helper::__leaf2vtext;
}

my $master_copy_path = "$Bin/../tlib/Skel.odt";
my $input_path = tmpcopy_if_writeable($master_copy_path);
my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;

my $pristine_bodytext = $body->Hget_text();
say dvis '$pristine_bodytext' if $debug;

$body->normalize; # just in case it isn't from LibreOffice
verif_normalized($body);

#FIXME: replace adjacent to PCTEXT or text:s to check normalization

#my $torepl = "e";
my $torepl = "here";
for my $repl ([""], [["italic","small-caps"],""], []) {

  my @repls = $body->Hreplace($torepl, $repl, multi => TRUE, debug => $debug);

  my $new_bodytext = $body->Hget_text();
  (my $exp = $pristine_bodytext) =~ s/\Q$torepl\E//g;
  is ($new_bodytext, $exp, "multi replace '${torepl}' with ".vis($repl));
  oops unless (scalar(@repls)*length($torepl))
                == (length($pristine_bodytext)-length($new_bodytext));

  verif_normalized($body);

  # un-do the replacement
  my %para2incr;
  foreach my $r (@repls) {
    my $para = $r->{para};
    my $incr = $para2incr{$para}//=0;
    $para->Hreplace("", [$torepl], offset => $incr + $r->{para_voffset});
    $para2incr{$para} += length($torepl);
    verif_normalized($para);
  }
  is($body->Hget_text(), $pristine_bodytext);
}
    
my $count = 0;
for my $start_text ("Front Stuff", "  :(3", "  ")
{
  # Replace $start_text with various things, each time replacing that thing
  # with $start_text to restore the paragraph.   
  # The paragraph is the the first one containing $start_text;
  
  my $m0 = $body->Hsearch($start_text) // bug;
  my $para = $m0->{para};
  my $pristine_paratext = $para->get_text;

  my @repl_content;
  if ($ENV{AUTHOR_TESTING}) {
    @repl_content = (
      [""],
      [["bold", 13], "NEW"],
      [["bold", color => "red", size => "140%", "italic"], "NEW"],
      ["NEW"], ["NEW"], 
      ["\t"], ["NEW\t"], ["\tNEW"], ["NEW\tzz6"],
      ["\n"], ["NEW\n"], ["\nNEW"], ["NEW\nzz9"],
      [" "], ["NEW "], [" NEW"], ["NEW zz12"],
      ["  "], ["NEW  "], ["  NEW"], ["NEW  zz15"],
      ["   "], ["NEW   "], ["   NEW"], ["NEW   zz18"],
      ["NEW \t\t\n   \n\n  "],
      [["italic"], "foobarNEWfoobar", " NEW foobar", [17], "17ptNEW", ["bold", 38], " 38ptNEW"],
    );
  } else {
    @repl_content = (
      [""],
      [["bold", 13], "NEW"],
      ["\t"], ["NEW\t"], ["\tNEW"], ["NEW\tzz6"],
      ["\n"], [" "], ["  "], ["NEW  "], ["  NEW"], ["NEW  zz15"],
      ["NEW   zz18"],
      ["NEW \t\t\n   \n\n  "],
    );
    SKIP: {
      skip "Some author-only test cases";
      ok(0, "Never happens");
    }
  }
  foreach (@repl_content) {
    my $new_content = $_;
    foreach (@$new_content) { #make unique
      s/NEW/sprintf("NEW%03d", $count++)/esg unless ref; 
    }
    my $testname = "Hreplace ".vis($start_text)." with ".vis($new_content);

    my $content_vtext = join("", grep{! ref} @$new_content);
    
    my ($replinfo, @extra) = $body->Hreplace(qr/\Q${start_text}\E/s, 
                                             $new_content, 
                                             debug => $debug);
    oops unless $replinfo && !@extra;
    note "AFTER :\n", fmt_tree($para) if $debug;

    my $new_paratext = $para->get_text;

    my $para_exp = $pristine_paratext;
    substr($para_exp, $m0->{para_voffset}, length($start_text))=$content_vtext;

    is($new_paratext, $para_exp, $testname." (para check)",
       dvis '\n  $pristine_paratext\n  $new_content  $content_vtext'
           .'\n  $new_paratext\n  $para_exp\n  $pristine_paratext'
           .'\n  $m0\n  $replinfo'
    );
    verif_normalized($para);
      
    my $body_exp = $pristine_bodytext;
    substr($body_exp, $m0->{voffset}, length($start_text)) = $content_vtext;

    my $body_got = $body->Hget_text();
    is ($body_got, $body_exp,
        $testname." (full body check)",
        fmt_tree($body)
    );

    # Undo the substitution. FIXME: This should clean up empty spans!?!
    $para->Hreplace($content_vtext, [$start_text], 
                    offset => $$replinfo{para_voffset}, debug => $debug);
    fail("undo did not work")
      unless $para->get_text() eq $pristine_paratext;
    verif_normalized($para);
  }
  note "Final body vtext = ",vis($body->Hget_text())
    if $debug;

}

done_testing();
