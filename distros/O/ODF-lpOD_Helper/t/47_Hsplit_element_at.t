#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug tmpcopy_if_writeable $debug/;
use Test2::Tools::Compare qw/T/;

use ODF::lpOD;
use ODF::lpOD_Helper;

my $doc = odf_create_document("text");
my $body = $doc->get_body;

my $emptypara = odf_create_paragraph;

my $para = odf_create_paragraph;
#$body->insert_element($para);
my $str = "A     B\t\tC\n\nDEF";
$para->set_text($str);
say "para=",fmt_tree($para) if $debug;
is($para,
   hash {
     field first_child => hash {
       field gi => $XML::Twig::gi2index{"#PCDATA"};
       field pcdata => match qr/^A ?/;
       field next_sibling => hash {
         field gi => $XML::Twig::gi2index{"text:s"};
         field att => hash { field "text:c" => in_set(4,5); etc };
         field next_sibling => hash {
           field pcdata => "B";
           field next_sibling => hash {
             field gi => $XML::Twig::gi2index{"text:tab"};
             field next_sibling => hash {
               field next_sibling => hash {
                 field next_sibling => hash {
                   field gi => $XML::Twig::gi2index{"text:line-break"};
                   etc };
                 etc };
               etc };
             etc };
           etc };
         etc };
       etc };
     etc },
  "expected nodes in para"
);

for my $off (0..length($str)-1) {
  my ($node, $off) = $para->Hoffset_into_vtext(0);
  fail("Wrong at $off") 
    unless substr($node->Hget_text(),$off,1) eq substr($str,$off,1);
}
pass("Hoffset_into_vtext for each virtual char");
{ my ($node, $off) = $para->Hoffset_into_vtext(length($str));
  ok(!defined($off) && $node->text eq "DEF", "Hoffset_into_vtext last+1");
  eval { my ($n,$o) = $para->Hoffset_into_vtext(length($str)+1); };
  is($@, T, "para->Hoffset_into_vtext(last+2) throws");
}
{ my $emptypara = odf_create_paragraph;
  my ($node, $off) = $emptypara->Hoffset_into_vtext(0);
  is([$node,$off],
     array { item undef; item undef; },
     "empty->Hoffset_into_vtext(0)"
  );
  eval { my ($n,$o) = $emptypara->Hoffset_into_vtext(1); };
  is($@, T, "empty->Hoffset_into_vtext(last+2) throws");
}

####################### TEST Hsplit_element_at ##################

{ 
  my $tpara = odf_create_paragraph(); 
  $tpara->set_text(""); 
  my $empty_pcdata = $tpara->first_child;
  my $nelt = $empty_pcdata->Hsplit_element_at(0);
  ok($empty_pcdata->tag eq "#PCDATA" && $empty_pcdata->Hget_text eq ""
      &&
     $nelt->tag eq "#PCDATA" && $nelt->Hget_text eq ""
      && $empty_pcdata != $nelt,
     "emptypcdata->Hsplit_element_at(0)"
  );
  eval{ $nelt = $empty_pcdata->Hsplit_element_at(1) };
  is($@, T, "empty_pcdata->Hsplit_element_at(1) throws");
  say fmt_tree($tpara) if $debug;
  $tpara->normalize;
  fail() if $tpara->first_child; # both empty children should have been deleted
}

{ 
  my $tpara = odf_create_paragraph(); 
  $tpara->set_text("     "); 
  my $m = $tpara->Hsearch(qr/.*/); # either text:s{5} or " " + text:s{4}
  say fmt_match($m) if $debug;
  my $s_segment = $m->{segments}[-1];
  my $s_len = (@{$m->{segments}} == 1 ? 5 : 4);
  for my $i (1..$s_len-1) {
    my $nelt = $s_segment->Hsplit_element_at($i);
    ok($s_segment->tag eq "text:s" && $s_segment->Hget_text eq (" " x $i)
        &&
       $nelt->tag eq "text:s" && $nelt->Hget_text eq (" " x ($s_len-$i))
        && $s_segment != $nelt,
       "text:s ->Hsplit_element_at($i)"
    );
    $tpara->Hnormalize();
  }
}

done_testing();
