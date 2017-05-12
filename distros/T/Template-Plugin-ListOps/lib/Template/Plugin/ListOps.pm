package Template::Plugin::ListOps;
# Copyright (c) 2007-2010 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

$VERSION = "2.01";

require 5.004;

use warnings;
use strict;
use base qw( Template::Plugin );
use Template;
use Template::Plugin;
use Array::AsObject;

###############################################################################
###############################################################################

sub unique {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->unique();
   return [ $s->list() ];
}

###############################################################################

sub compact {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->compact();
   return [ $s->list() ];
}

###############################################################################

sub union {
   shift;
   my $list1 = shift;
   my $list2 = shift;
   my $op    = shift;
   $op       = "unique"  if (! $op);
   my $u     = ($op eq "unique" ? 1 : 0);

   my $s1  = new Array::AsObject @$list1;
   my $s2  = new Array::AsObject @$list2;
   my $s3  = $s1->union($s2,$u);
   return [ $s3->list() ];
}

###############################################################################

sub difference {
   shift;
   my $list1 = shift;
   my $list2 = shift;
   my $op    = shift;
   $op       = "unique"  if (! $op);
   my $u     = ($op eq "unique" ? 1 : 0);

   my $s1  = new Array::AsObject @$list1;
   my $s2  = new Array::AsObject @$list2;
   my $s3  = $s1->difference($s2,$u);
   return [ $s3->list() ];
}

###############################################################################

sub intersection {
   shift;
   my $list1 = shift;
   my $list2 = shift;
   my $op    = shift;
   $op       = "unique"  if (! $op);
   my $u     = ($op eq "unique" ? 1 : 0);

   my $s1  = new Array::AsObject @$list1;
   my $s2  = new Array::AsObject @$list2;
   my $s3  = $s1->intersection($s2,$u);
   return [ $s3->list() ];
}

###############################################################################

sub symmetric_difference {
   shift;
   my $list1 = shift;
   my $list2 = shift;
   my $op    = shift;
   $op       = "unique"  if (! $op);
   my $u     = ($op eq "unique" ? 1 : 0);

   my $s1  = new Array::AsObject @$list1;
   my $s2  = new Array::AsObject @$list2;
   my $s3  = $s1->symmetric_difference($s2,$u);
   return [ $s3->list() ];
}

###############################################################################

sub at {
   shift;
   my $list = shift;
   my $pos  = shift;

   my $s = new Array::AsObject @$list;
   $s->at($pos);
}

###############################################################################

sub sorted {
   my(@args) = @_;
   shift @args;
   my $list = shift @args;
   my $meth = shift @args;

   $meth    = "alphabetic"  if (! $meth);

   my %meth = qw(forward       alphabetic
                 reverse       rev_alphabetic
                 forw_num      numerical
                 rev_num       rev_numerical
                 dates         date
                 rev_dates     rev_date);
   if (exists $meth{$meth}) {
      $meth=$meth{$meth};
   }

   my $s = new Array::AsObject @$list;
   $s->sort($meth,@args);
   return [ $s->list() ];
}

###############################################################################

sub join {
   shift;
   my $list = shift;
   my $str  = shift;
   return CORE::join($str,@$list);
}

###############################################################################

sub first {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->first();
}
sub last {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->last();
}

###############################################################################

sub shiftval {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   my $ret = $s->shift();
   @$list  = $s->list();

   $ret;
}
sub popval {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   my $ret = $s->pop();
   @$list  = $s->list();

   $ret;
}

###############################################################################

sub unshiftval {
   shift;
   my $list = shift;
   my @vals   = @_;
   if (@vals  &&  $#vals == 0  &&  ref($vals[0])) {
      @vals = @{ $vals[0] };
   }

   my $s = new Array::AsObject @$list;
   $s->unshift(@vals);
   return [ $s->list() ];
}
sub pushval {
   shift;
   my $list = shift;
   my @vals   = @_;
   if (@vals  &&  $#vals == 0  &&  ref($vals[0])) {
      @vals = @{ $vals[0] };
   }

   my $s = new Array::AsObject @$list;
   $s->push(@vals);
   return [ $s->list() ];
}

###############################################################################

sub minval {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->min("numerical");
}
sub maxval {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->max("numerical");
}

sub minalph {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->min("alphabetic");
}
sub maxalph {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->max("alphabetic");
}

###############################################################################

sub impose {
   shift;
   my $list      = shift;
   my $string    = shift;
   my $placement = shift;
   $placement = "append"  if (! $placement);

   my @ret;
   if ($placement eq "append") {
      foreach my $ele (@$list) {
         push(@ret,"$ele$string");
      }
   } else {
      foreach my $ele (@$list) {
         push(@ret,"$string$ele");
      }
   }
   return [ @ret ];
}

###############################################################################

sub reverse {
   shift;
   my $list = shift;

   my $s = new Array::AsObject @$list;
   $s->reverse();
   return [ $s->list() ];
}

###############################################################################

sub rotate {
   shift;
   my $list      = shift;
   my $direction = shift;
   my $num       = shift;
   if (! $direction  ||  ($direction ne "ftol"  &&  $direction ne "ltof")) {
      $num       = $direction;
      $direction = "ftol";
   }
   $num          = 1  if (! $num);
   $num          = -$num  if ($direction eq "ltof");

   my $s = new Array::AsObject @$list;
   $s->rotate($num);
   return [ $s->list() ];
}

###############################################################################

sub count {
   shift;
   my $list = shift;
   my $val  = shift;

   my $s = new Array::AsObject @$list;
   $s->count($val);
}

###############################################################################

sub delete {
   shift;
   my $list = shift;
   my $val  = shift;
   my $op   = shift;
   $op      = "unique"  if (! $op);
   my $all  = ($op eq "unique" ? 1 : 0);

   my $s = new Array::AsObject @$list;
   $s->delete($all,0,$val);
   return [ $s->list() ];
}

###############################################################################

sub is_equal {
   shift;
   my $list1 = shift;
   my $list2 = shift;
   my $op    = shift;
   $op       = "unique"  if (! $op);
   my $u     = ($op eq "unique" ? 1 : 0);

   my $s1  = new Array::AsObject @$list1;
   my $s2  = new Array::AsObject @$list2;
   $s1->is_equal($s2,$u);
}

sub not_equal {
   return 1 - is_equal(@_);
}

###############################################################################

sub clear {
   shift;
   my $list = shift;
   return [ ];
}

###############################################################################

sub fill {
   shift;
   my $list   = shift;
   my $val    = shift;
   my $start  = shift;
   my $length = shift;

   my $s = new Array::AsObject @$list;
   $s->fill($val,$start,$length);
   return [ $s->list() ];
}

###############################################################################

sub splice {
   shift;
   my $list   = shift;
   my $start  = shift;
   my $length = shift;
   my @vals   = @_;
   if (@vals  &&  $#vals == 0  &&  ref($vals[0])) {
      @vals = @{ $vals[0] };
   }

   my $s = new Array::AsObject @$list;
   $s->splice($start,$length,@vals);
   return [ $s->list() ];
}

###############################################################################

sub indexval {
   shift;
   my $list = shift;
   my $val  = shift;

   my $s = new Array::AsObject @$list;
   my $ret = $s->index($val);
   return $ret;
}
sub rindexval {
   shift;
   my $list = shift;
   my $val  = shift;

   my $s = new Array::AsObject @$list;
   my $ret = $s->rindex($val);
   return $ret;
}

###############################################################################

sub set {
   shift;
   my $list  = shift;
   my $index = shift;
   my $val   = shift;

   my $s = new Array::AsObject @$list;
   $s->set($index,$val);
   return [ $s->list() ];
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:
