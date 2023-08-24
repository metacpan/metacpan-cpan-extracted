#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP These tests are for testing by the author\n};
    exit
  }
}

use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug tmpcopy_if_writeable $debug/;

use ODF::lpOD;
use ODF::lpOD_Helper;
BEGIN {
  *_abbrev_addrvis = *ODF::lpOD_Helper::_abbrev_addrvis;
  *TEXTLEAF_COND   = *ODF::lpOD_Helper::TEXTLEAF_COND;
  *PARA_COND       = *ODF::lpOD_Helper::PARA_COND;
  *__leaf2vtext    = *ODF::lpOD_Helper::__leaf2vtext;
}

my $master_copy_path = "$Bin/../tlib/NestedCompact.odt";
my $input_path = tmpcopy_if_writeable($master_copy_path);
my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;
 
my $total_vtext = $body->Hget_text();

# Find all paragraphs and store the vtext and starting overall offset for each
my @paras; # { para, vt_local, vt_recur, offset }
{ my $offset = 0;
  my sub handle_para($) {
    my $para = shift;
    push @paras, { para => $para, offset => $offset };
    my $ix = $#paras;
    # Collect text from the paragraph but not from nested paragraphs, which
    # are handled separately via recursion.
    my $vt_local = "";
    my $vt_recur = "";
    my $elt = $para;
    while ($elt = $elt->Hnext_elt($para, undef, PARA_COND)) {
      say dvis '## $ix $elt ',vis($elt->get_text) if $debug;
      if ($elt->passes(PARA_COND)) {
        __SUB__->($elt); # recurse into nested paragraph, updating $offset
        $vt_recur .= $elt->Hget_text();
      }
      elsif ($elt->passes(TEXTLEAF_COND)) {
        my $text = __leaf2vtext($elt);
        $vt_local .= $text;
        $offset += length($text);
        $vt_recur .= $text;
      }
    }
    $paras[$ix]->{vt_local} = $vt_local;
    $paras[$ix]->{vt_recur} = $vt_recur;
  }
  foreach ($body->Hdescendants(PARA_COND, PARA_COND)) { # top-level paragraphs
    handle_para($_);
  }
}
my %paras = map{ ($_->{para} => $_) } @paras;
if ($debug) {
  for my $p (@paras) {
    say ">>> para=",_abbrev_addrvis($p->{para}),
        #ivis ' offset=$p->{offset} vt_local=$p->{vt_local}\n        recur=$p->{vt_recur}';
        ivis ' offset=$p->{offset} vt_local=$p->{vt_local}';
  }
  say "body: ",fmt_tree($body);
  say dvis '$total_vtext';
}
{ my $lenA = sum0(map{length($_->{vt_local})} values %paras);
  my $lenB = length($total_vtext);
  fail("setup bug", dvis('$lenA $lenB $total_vtext') )
    unless $lenA==$lenB;
}

my $count = 0;
my $next_check_count = 0;
for my $offset (length($total_vtext), 0..length($total_vtext)) {
  for my $itemtext ("", "Z", "  ", "\t", "\n") {
  #for my $itemtext ("", "Z") {
  #for my $itemtext ("") {
    my $testname = "Hinsert_element ".vis($itemtext)." offset=$offset";
    my $elt;
    if ($itemtext =~ /^\S*$/) {
      $elt = $body->Hinsert_element(TEXT_SEGMENT,
                                    position => WITHIN, offset => $offset);
      $elt->set_text($itemtext);
    }
    elsif ($itemtext eq "\t") {
      $elt = $body->Hinsert_element('text:tab', 
                                    position => WITHIN, offset => $offset);
    }
    elsif ($itemtext eq "\n") {
      $elt = $body->Hinsert_element('text:line break', 
                                    position => WITHIN, offset => $offset);
    }
    elsif ($itemtext =~ /^ +$/) {
      $elt = $body->Hinsert_element('text:s', 
                                    position => WITHIN, offset => $offset);
      $elt->set_attribute('c', length($itemtext)); 
    }
    else { oops vis($itemtext) }

    my $para = $elt->parent(qr/^text:[ph]$/) 
                    // oops "elt=",fmt_node($elt),"\n body=",fmt_tree($body);
    my $expected = $paras{$para}->{vt_recur};
    my $poffset = $offset - $paras{$para}->{offset};
    oops visnew->dvisr('$poffset $offset $expected $elt\n$para $paras{$para}\n').fmt_tree($para)
      if $poffset < 0 or $poffset > length($expected);
    substr($expected, $poffset, 0) = $itemtext;
    my $got = $para->Hget_text();
    is ($got, $expected, $testname." (para)", 
        visnew->dvisr('$poffset $para $paras{$para}\n').fmt_tree($para));

    if ($count == $next_check_count) {
      my $big_expected = $total_vtext; 
        substr($big_expected, $offset, 0) = $itemtext;
      my $big_got = $body->Hget_text();
      is ($big_got, $big_expected, $testname." (full body)", fmt_tree($body));
    }

    $elt->delete;

    if ($count == $next_check_count) {
      fail("BUG:Did not restore correctly") 
        if $body->Hget_text() ne $total_vtext;
      $next_check_count += int(rand(100));
    }

    $count++;
  }
}
fail("BUG:Did not restore correctly") 
  if $body->Hget_text() ne $total_vtext;

note "Tested $count insertions\n";

done_testing();
