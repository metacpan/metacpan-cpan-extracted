#!/usr/bin/perl

use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops btw btwN/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon #':silent',
                 qw/bug tmpcopy_if_writeable $debug/;

use LpodhTestUtils qw/verif_normalized/;

use ODF::lpOD;
use ODF::lpOD_Helper qw/:DEFAULT Hr_MASK TEXTLEAF_FILTER PARA_FILTER/;
BEGIN {
  *_abbrev_addrvis = *ODF::lpOD_Helper::_abbrev_addrvis;
  *__leaf2vtext    = *ODF::lpOD_Helper::__leaf2vtext;
}

my $input_path = "$Bin/../tlib/Skel.odt";
my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;
verif_normalized($body);

my $orig_vtext = $body->Hget_text();

if ($debug) {
  say fmt_tree($body, showoff=>1);
}else { my $offset = 0;
  my $o = visnew->Useqq("controlpics:unicode");
  while ($offset < length($orig_vtext)) {
    printf "%3d: %s\n", $offset, $o->vis(substr($orig_vtext,$offset,16));
    $offset += 16;
  }
}

addrvis_digits(5);

# Find "interesting" insertion offsets
my @insert_locs;
for my $item ("here", "\t", ' ') {
  my $m = $body->Hsearch($item) // oops ivis 'Can not find $item';
  my $nlocs_before = @insert_locs;
  die dvis 'Expected $item to be in a single segment; $m'
    unless @{$$m{segments}}==1;
  my $seglen = length( $$m{segments}[0]->Hget_text );
  if ($seglen == 1) {
    die dvis '??? offset/end ??? $m' if $$m{offset} != 0 or $$m{end} != 1;
  } else {
    die dvis 'Expected $item to be in middle of a segment; $m'
      unless $$m{offset} > 0 && $$m{end} < $seglen;
    push @insert_locs, [$m, position => WITHIN,
                            offset => $$m{voffset}-$$m{offset}]; # start of seg
    push @insert_locs, [$m, position => WITHIN,
                            offset => $$m{voffset}-$$m{offset}+$seglen-1];
    push @insert_locs, [$m, position => WITHIN,
                            offset => $$m{voffset}-$$m{offset}+1];
  }
  for my $add (0..10) {
    push @insert_locs, [$m, position => WITHIN, offset => $$m{voffset}+$add];
  }
  push @insert_locs, [$m, position => WITHIN,
                          offset => $$m{voffset}-$$m{offset}+$seglen];
  push @insert_locs, [$m, position => WITHIN,
                          offset => $$m{voffset}-$$m{para_voffset}];
  if ($debug) {
    say dvis '### TESTCASES for $item $$m{voffset} :';
    foreach (@insert_locs[$nlocs_before..$#insert_locs]) {
      say ivis '      $$m{para} $$m{voffset} ', visnew->hvisl(@$_[1..$#$_])
    }
  }
}

my $tix = 0;
for my $content ([], [""], [" "], ["\t"], ["A   BC"],
                 [["bold"],"ABC"],
                 [["bold"],"   ABC",["italic"],"DEF","GHI"],
                )
{
  my $content_text = join("",grep{!ref} @$content);
  foreach (@insert_locs) {
    my ($old_m, %insert_opts) = @$_;
    # Save and restore the guts of the paragraph to be edited
    my $saved_para_clone = $$old_m{para}->clone;
    my $desc = ivis '${tix}:Hinsert_content $content %insert_opts';

    # Re-find the segment(s) because the paragraph gets rebuilt each time below
    my $m = $body->Hsearch($$old_m{match}, offset => $$old_m{voffset}) // oops;
    verif_normalized($$m{para}); # oops if not

    my @orig_text_segs = $$m{para}->descendants(TEXTLEAF_FILTER);

    my $h = $body->Hinsert_content($content, %insert_opts,
                                   debug => $debug) // oops;

    # Hinsert_content and Hinsert_element are not supposed to ever merge
    # segments, so all original segments should still exist (one of them
    # might have been split of WITHIN offset pointed into it's middle).
    foreach my $i (0..$#orig_text_segs) {
      my $node = $orig_text_segs[$i];
      fail($desc."\nERROR: segment did not survive:",
           dvis '$i @orig_text_segs\n%insert_opts\n$m\n'.fmt_node($node))
        unless $node->parent;
    }

    is($h->{vlength}, length($content_text), $desc." (vlength)");

    substr(my $exp_vtext=$orig_vtext, $insert_opts{offset}, 0) = $content_text;
    is($body->Hget_text, $exp_vtext, $desc." (text)");

    # Un-do the edit
    foreach($$m{para}->children) { $_->delete }
    foreach($saved_para_clone->children) {
      my $child_copy = $_->clone;
      $child_copy->paste_last_child($$m{para});
    }
    $saved_para_clone->delete;
    $tix++;
  }
  $body->Hnormalize;
  verif_normalized($body);
}

done_testing();
