#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops btw/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug tmpcopy_if_writeable $debug/;

say "vim: set filetype=conf :" if $debug;

STDOUT->autoflush;
STDERR->autoflush;

use ODF::lpOD;
use ODF::lpOD_Helper qw/:DEFAULT TEXTLEAF_COND TEXTLEAF_OR_PARA_COND PARA_COND/;
BEGIN {
  *_abbrev_addrvis = *ODF::lpOD_Helper::_abbrev_addrvis;
}

use constant FRAME_COND => 'draw:frame';

use Encode qw/encode decode/;

my $master_copy_path = "$Bin/../tlib/NestedFrames.odt";
my $input_path = tmpcopy_if_writeable($master_copy_path);
my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;

my $para0_only_text =
"{Tok1 Outer; nl:\n:nl tab:\t:tab 5spaces:     :5spaces}{Tok9 Just chars immediately following Outer-Frame-as-Character}";

my $para1_text = "{Tok2 1st para in outer Frame (entire para)}" ;

my $para2_only_text =
  " \n{Tok3 2nd Para in outer Frame (preceded by SP,NL)}AAA"
 ."{Tok7 Just chars immediately following Inner-Frame-as-Character}" ;

my $para2_recursive_text =
  " \n{Tok3 2nd Para in outer Frame (preceded by SP,NL)}AAA"
 ."{Tok4 1st Para in inner Frame (entire para)}"
 ."AAA{Tok5 with local format spans }BBBB"
 ."{Tok6 3rd Para in inner Frame (entire) tab:\t:tab 2spaces:  :2spaces}"
 ."{Tok7 Just chars immediately following Inner-Frame-as-Character}" ;

my $para1_recursive_text =
  "{Tok2 1st para in outer Frame (entire para)}"
 ." \n{Tok3 2nd Para in outer Frame (preceded by SP,NL)}AAA"
 ."{Tok4 1st Para in inner Frame (entire para)}"
 ."AAA{Tok5 with local format spans }BBBB"
 ."{Tok6 3rd Para in inner Frame (entire) tab:\t:tab 2spaces:  :2spaces}"
 ."{Tok7 Just chars immediately following Inner-Frame-as-Character}"
 ."{Tok8 Para following ‘Just chars’}" ;

my $para0_recursive_text =
  "{Tok1 Outer; nl:\n:nl tab:\t:tab 5spaces:     :5spaces}"
 .$para1_recursive_text
 ."{Tok9 Just chars immediately following Outer-Frame-as-Character}" ;

my $last_para_text = "{Tok10 Outer para (entire para)}";

my $para0 = $body->next_elt($body, 'text:p');
my $para1 = $para0->next_elt($body, 'text:p');
my $para2 = $para1->next_elt($body, 'text:p');
say "para0=",fmt_node_brief($para0) if $debug;
say "para1=",fmt_node_brief($para1) if $debug;
say "para2=",fmt_node_brief($para2) if $debug;

#################################
# Hget_text and get_text
#################################
{
  is($para0->get_text(),  $para0_only_text, "p0 get_text (non-rec)");
  is($para0->Hget_text(prune_cond => PARA_COND), $para0_only_text, 
     "p0 Hget_text (non-rec)");
  is($para0->Hget_text(), $para0_recursive_text, 
     "Hget_text recursive (now the default)");
  is($para1->get_text(),  $para1_text, "p1 get_text (non-rec)");
  is($para1->Hget_text(prune_cond => PARA_COND),  $para1_text, 
     "p1 Hget_text (non-rec)");

  is($para2->get_text(),  $para2_only_text, "p2 get_text (non-rec)");
  is($para2->Hget_text(prune_cond => PARA_COND), $para2_only_text, 
     "p2 Hget_text (non-rec)");
  is($para2->Hget_text(), $para2_recursive_text, "p2 Hget_text recursive ");

  $para0_recursive_text =~ /Tok2/ or oops;
  my $off = $-[0];
  my $tmp = substr($para0_recursive_text, $off);
  $tmp =~ s/ \n//sg;
  $tmp =~ s/[\t\n]//sg;
  $tmp =~ s/  +/ /g;
  # simulating the bug in ODF::lpOD's get_text()
  my $p0_demented_text = substr($para0_recursive_text,0,$off) . $tmp;
  is($para0->get_text(recursive => TRUE),  $p0_demented_text, "get_text recursive still has bug with tab/nl/spaces");

  # non-recursive on non-container returns nothing
  is($body->get_text(recursive => FALSE),  "", "get_text non-recursive on body",
                     fmt_tree($body));

}

#################################
# masked subtrees
#################################

# Find top-level paragraphs and frame, exluding everything within the frame
{
  my $seq = 0;
  my $elt = $body;
  while( $elt = $elt->Hnext_elt($body, qr/^text:[ph]$|^draw:frame$/, 'draw:frame') ) {
    my $desc = "Hnext_elt(body,paras,frame) item $seq";
    #btw 'GOT: ',fmt_node_brief($elt) if $debug;
    if    ($seq == 0) { ref_is ($elt, $para0, $desc); }
    elsif ($seq == 1) { is ($elt->tag, "draw:frame", $desc); }
    elsif ($seq == 2) { is ($elt->get_text, $last_para_text, $desc); }
    else              { oops }
    $seq++;
  }
}

# Collect nodes with Hdescendants.
# Verifies that Hnext_elt produces the same
#   ...which is no big deal bc Hdescendants calls Hnext_elt
#   ...so this DOES NOT verify that Hnext_elt does the right thing!
sub call_Hdescendants($@) {
  my ($subtree_root, @args) = @_;

  my @segs1;
  my $elt = $subtree_root;
  while ($elt = $elt->Hnext_elt($subtree_root, @args)) {
    push @segs1, $elt;
  }

  my @segs2 = $subtree_root->Hdescendants(@args);

  fail(Carp::cluck dvis 'Hnext_elt & Hdescendants not working the same\n$subtree_root @args \n@segs1\n@segs2') unless "@segs1" eq "@segs2";

  my @segs3 = $subtree_root->Hdescendants_or_self(@args);
#btw dvis '@segs3';
  if ($subtree_root->passes($args[0])) {
    fail("Hdescendants_or_self - did not find self"
         .dvis '\n$args[0]\n$subtree_root\n@segs3')
      unless ($#segs3 == $#segs2+1) && $segs3[0]==$subtree_root;
    shift @segs3;
  }
  fail(Carp::cluck "Hdescendants_or_self wrong result",
                   "\nsubtree_root:", fmt_tree($subtree_root),
                   "\nst_root->passes = ", vis($subtree_root->passes($args[0])),
                   dvis '\n@args\n@segs1\n@segs3') 
     unless "@segs1" eq "@segs3";

  @segs1
}

##### more Hnext_elt tests #####

# para2 is inside the outer frame.
{ my @r = call_Hdescendants($para2, PARA_COND, PARA_COND);
  # All 3 paras inside the inner frame
  is(scalar(@r), 3, "Hnext_elt #1", dvis '@r\npara2:', fmt_tree($para2));
}
{ my @r = call_Hdescendants($para2, PARA_COND, "draw:frame");
  # 0 paras inside the inner frame
  is(scalar(@r), 0, "Hnext_elt masking frame");
}

foreach my $stroot (call_Hdescendants($body, FRAME_COND."|".PARA_COND)) {
  # This triggered a bug fixed 8/22/23 where a pruned node is the
  # last sibling of a parent whic itself it the last sibling under
  # a subtree_root, and the subtree_root does have a sibling
  my @nodes = call_Hdescendants($stroot, undef, PARA_COND);
  foreach my $elt (@nodes) {
    fail("escaped from subtree_root ??  elt=".fmt_node($elt)."\nstroot:".fmt_tree($stroot))
      unless $elt->parent == $stroot
              || $elt->parent->parent == $stroot
              || $elt->parent->parent->parent == $stroot;
  }
}

# Get text nodes and frames in/below a paragraph but exclude anything inside
# a frame (including, in this test, a nested frame)
my $textleaf_cond = '#TEXT|text:tab|text:line-break|text:s';
{
  my $text = "";
  my $frame_count = 0;
  foreach my $elt (call_Hdescendants($para2, $textleaf_cond."|draw:frame", "draw:frame")) {
    my $tag = $elt->tag;
    if ($tag =~ /^(?:#PCDATA|text:tab|text:line-break|text:s)$/) {
      $text .= $elt->Hget_text();
      btw fmt_node_brief($elt),"\n  now text=",vis($text) if $debug;
    }
    elsif ($tag eq 'draw:frame') {
      btw "Got FRAME ", fmt_node_brief($elt) if $debug;
      ++$frame_count;
    }
    else { fail("unexpected node ".fmt_node($elt)) }
  }
  is($text, $para2_only_text, "Hnext_elt(para2,textleaves+frames,frame) text ok");
  is($frame_count, 1, "Hnext_elt(para2,textleaves+frames,frame) framecount");
}

# But get everything if prune_cond is absent or matches nothing
{
  my $text = "";
  foreach my $elt (call_Hdescendants($para0, $textleaf_cond)) {
    $text .= $elt->Hget_text();
  }
  is($text, $para0_recursive_text, "Hnext_elt omitting prune_cond");
}
{
  my $text = "";
  foreach my $elt (call_Hdescendants($para0, $textleaf_cond, undef)) {
    $text .= $elt->Hget_text();
  }
  is($text, $para0_recursive_text, "Hnext_elt w prune_cond=undef");
}
{
  my sub callback {
    my $e = shift;
    $e->passes($textleaf_cond);
  }
  my $text = "";
  foreach my $elt (call_Hdescendants($para0, \&callback)) {
    $text .= $elt->Hget_text();
  }
  is($text, $para0_recursive_text, "Hnext_elt w prune_cond callback");
}
{
  my @segs = call_Hdescendants($para0, $textleaf_cond, "lpOD_H:nevermatch");
  my $text = join("", map{$_->Hget_text()} @segs);
  is($text, $para0_recursive_text, "Hnext_elt w prune_cond that never matches");
}


done_testing();

