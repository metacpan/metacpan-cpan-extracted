#!/usr/bin/perl
package LpodhTestUtils;

use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon qw/bug $debug/;

use ODF::lpOD;
use ODF::lpOD_Helper;
BEGIN {
  *TEXTLEAF_COND   = *ODF::lpOD_Helper::TEXTLEAF_COND;
  *PARA_COND       = *ODF::lpOD_Helper::PARA_COND;
}

use Exporter 'import';
our @EXPORT = qw/verif_normalized/;

sub verif_normalized($) {
  my $elt = shift;
  oops if ref(TEXTLEAF_COND); # not a qr/regex/
  my $cond = TEXTLEAF_COND."|text:span";
  foreach my $e ($elt->descendants_or_self($cond)) {
    my $err;
    my $tag = $e->tag;
    if ($tag eq '#PCDATA') {
      if (my $ps = $e->prev_sibling) {
         $err = dvis 'CONSECUTIVE #PCDATA (w/prev) $e in $elt' 
           if $ps->tag eq '#PCDATA';
      }
      if (my $ns = $e->next_sibling) {
         $err = dvis 'CONSECUTIVE #PCDATA (w/next) $e in $elt' 
           if $ns->tag eq '#PCDATA';
      }
      my $text = $e->get_text // oops;
      $err = dvis '"" text in #PCDATA $e in $elt' 
        if $text eq "";
      $err = dvis 'Consecutive spaces in #PCDATA $e in $elt' 
        if $text =~ /  /;
    }
    elsif ($tag eq 'text:s') {
      if (my $ps = $e->prev_sibling) {
         my $prev_tag = $ps->tag;
         $err = dvis 'CONSECUTIVE text:s (w/prev) $e in $elt' 
           if $prev_tag eq 'text:s';
        $err = dvis 'text:s NOT FOLLOWING A PCDATA SPACE $e in $elt'
           if $prev_tag eq '#PCDATA' && substr($ps->get_text,-1) ne " ";
      }
      if (my $ns = $e->next_sibling) {
         $err = dvis 'CONSECUTIVE text:s (w/next) $e in $elt' 
           if $ns->tag eq 'text:s';
      }
      $err = dvis 'text:s with c==0 $e in $elt' 
        if ($e->get_attribute('c')//1) == 0;
    }
    elsif ($tag eq 'text:span') {
      $err = dvis 'EMPTY text:span $e in $elt'
        unless $e->first_child;
      $err = dvis 'NESTED text:span $e in $e->parent() in $elt'
        if $e->parent->tag eq "text:span";
      if ((my $next = $e->next_sibling)) {
        if ($next->tag eq "text:span") {
          my $s1 = $e->get_attribute("style name");
          my $s2 = $next->get_attribute("style name");
          $err = dvis 'SIBLING SPANS with SAME STYLE $s1 $e and $next in $elt'
            if $s1 eq $s2;
        }
      }
    }
    elsif ($tag eq 'text:tab') { }
    elsif ($tag eq 'text:line-break') { }
    else { oops $e }
    if ($err) {
      my $para = $e->self_or_parent(PARA_COND);
      @_ = ("verif_normalized", "$err\nContaining para:\n".fmt_tree($para));
      goto &fail
    }
  }
}

1;
