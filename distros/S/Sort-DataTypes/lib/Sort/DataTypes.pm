package Sort::DataTypes;
# Copyright (c) 2007-2011 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

$VERSION = "3.01";

require 5.000;
require Exporter;
use Storable qw(dclone);
use warnings;

our %methods = ('alphabetic'   => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                  },
                'numerical'    => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                  },
                'alphanum'     => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                  },
                'random'       => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                  },
                'version'      => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                  },
                'date'         => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                  },
                'ip'           => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                  },
                'nosort'       => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                  },
                'function'     => { 'type'    => 'unambiguous',
                                    'args'    => [],
                                    'reverse' => 0,
                                    'args' => [ { 'type'    => 'function',
                                                },
                                                { 'type'    => 'string',
                                                },
                                              ],
                                  },

                'length'       => { 'type'    => 'ambiguous',
                                    'args'    => [],
                                    'alt'     => 'alphabetic',
                                    'altargs' => [],
                                    'reverse' => 0,
                                  },

                'split'        => { 'type' => 'split',
                                    'args' => [ { 'type'    => 'member',
                                                  'values'  => [ 'lms', 'rms' ],
                                                  'default' => 'lms',
                                                },
                                                {
                                                 'type'     => 'regexp',
                                                 'default'  => '\s+',
                                                }
                                              ],
                                    'alt'     => 'alphabetic',
                                    'altargs' => [],
                                    'reverse' => 0,
                                  },

                'domain'       => { 'type' => 'wrapper' },
                'numdomain'    => { 'type' => 'wrapper' },
                'path'         => { 'type' => 'wrapper' },
                'numpath'      => { 'type' => 'wrapper' },

                'partial'      => { 'type' => 'partial',
                                    'args' => [ {
                                                 'type'     => 'regexp',
                                                 'default'  => '\s+',
                                                }
                                              ],
                                    'alt'     => 'alphabetic',
                                    'altargs' => [],
                                    'reverse' => 0,
                                  },

                'line'         => { 'type' => 'wrapper' },
                'numline'      => { 'type' => 'wrapper' },
               );
my @all_methods  = map { ("sort_$_", "sort_rev_$_", "cmp_$_", "cmp_rev_$_") } keys %methods;

@ISA = qw(Exporter);
@EXPORT_OK = (
              qw(sort_valid_method
                 sort_by_method
                 cmp_valid_method
                 cmp_by_method
               ),
              @all_methods);
%EXPORT_TAGS = (all => \@EXPORT_OK);

foreach my $meth (keys %methods) {
   $methods{$meth}{'function'}      = $meth;
   $methods{"rev_$meth"}            = dclone($methods{$meth});
   $methods{"rev_$meth"}{'reverse'} = 1;
}

use strict;
###############################################################################
###############################################################################

sub sort_valid_method {
   my($method) = @_;
   return (exists $methods{$method} ? 1 : 0);
}

sub cmp_valid_method {
   my($method) = @_;
   return (exists $methods{$method} ? 1 : 0);
}

sub sort_by_method {
   my($method,$list,@args) = @_;

   return  if (! sort_valid_method($method));
   no strict 'refs';
   my $func = "sort_$method";
   return &$func($list,@args);
}

sub cmp_by_method {
   my($method,$list,@args) = @_;

   return  if (! cmp_valid_method($method));
   no strict 'refs';
   my $func = "cmp_$method";
   return &$func($list,@args);
}

###############################################################################
# UNAMBIGUOUS METHODS
###############################################################################

sub sort_numerical {
   return _sort('','numerical',@_);
}

sub cmp_numerical {
   return _cmp('','numerical',@_);
}

sub sort_rev_numerical {
   return _sort('rev','numerical',@_);
}

sub cmp_rev_numerical {
   return _cmp('rev','numerical',@_);
}

sub _numerical {
   my($ele) = @_;
   return 0  if (! defined($ele)  ||  ref($ele));
   return 1  if ($ele =~ /^[+-]?\d+\.?\d*$/  ||
                 $ele =~ /^[+-]?\.\d+$/);
   return 0;
}

sub _cmp_numerical {
   my($x,$y) = @_;
   return ($x <=> $y);
}

###############################################################################

sub sort_alphabetic {
   return _sort('','alphabetic',@_);
}

sub cmp_alphabetic {
   return _cmp('','alphabetic',@_);
}

sub sort_rev_alphabetic {
   return _sort('rev','alphabetic',@_);
}

sub cmp_rev_alphabetic {
   return _cmp('rev','alphabetic',@_);
}

sub _alphabetic {
   my($ele) = @_;
   return 1  if (! ref($ele));
   return 0;
}

sub _cmp_alphabetic {
   my($x,$y) = @_;
   return ($x cmp $y);
}

###############################################################################

sub sort_alphanum {
   return _sort('','alphanum',@_);
}

sub cmp_alphanum {
   return _cmp('','alphanum',@_);
}

sub sort_rev_alphanum {
   return _sort('rev','alphanum',@_);
}

sub cmp_rev_alphanum {
   return _cmp('rev','alphanum',@_);
}

sub _alphanum {
   my($ele) = @_;
   return 1  if (! ref($ele));
   return 0;
}

sub _cmp_alphanum {
   my($x,$y) = @_;
   if (_numerical($x)  &&  _numerical($y)) {
      return ($x <=> $y);
   } else {
      return ($x cmp $y);
   }
}

###############################################################################

{
   my $randomized = 0;

   sub _randomize {
      $randomized = 1;
      srand(time);
   }

   sub sort_random {
      _randomize()  if (! $randomized);
      return _sort('','random',@_);
   }

   sub cmp_random {
      _randomize()  if (! $randomized);
      return _cmp('','random',@_);
   }

   sub sort_rev_random {
      _randomize()  if (! $randomized);
      return _sort('','random',@_);
   }

   sub cmp_rev_random {
      _randomize()  if (! $randomized);
      return _cmp('','random',@_);
   }

   sub _random {
      my($ele) = @_;
      return 1;
   }

   sub _cmp_random {
      my($x,$y) = @_;
      return int(rand(3)) - 1;
   }
}

###############################################################################

sub sort_version {
   return _sort('','version',@_);
}

sub cmp_version {
   return _cmp('','version',@_);
}

sub sort_rev_version {
   return _sort('rev','version',@_);
}

sub cmp_rev_version {
   return _cmp('rev','version',@_);
}

sub _version {
   my($ele) = @_;
   return 1  if (! ref($ele));
   return 0;
}

sub _cmp_version {
   my($x,$y) = @_;

   my(@x,@y);
   (@x)=split(/\./,$x);
   (@y)=split(/\./,$y);

   while (@x) {
      return 1  if (! @y);
      my $xx=shift(@x);
      my $yy=shift(@y);

      if ($xx =~ /^(\d+)(.*)$/) {
         my($xv,$xs) = ($1+0,$2);
         if ($yy =~ /^(\d+)(.*)$/) {
            my($yv,$ys) = ($1+0,$2);
            my $ret = ($xv <=> $yv);
            return $ret  if ($ret);
            return -1  if ($xs && ! $ys);
            return  1  if ($ys && ! $xs);
            $ret = ($xx cmp $yy);
            return $ret  if ($ret);
         } else {
            return 1;
         }
      } elsif ($yy =~ /^(\d+)(.*)$/) {
         return -1;
      } elsif ($xx || $yy) {
         my $ret=($xx cmp $yy);
         return $ret  if ($ret);
      }
   }
   return -1  if (@y);
   return  0;
}

###############################################################################

{
   my $date_init = 0;
   my %cache;

   sub sort_date {
      %cache = ();
      if (! $date_init) {
         require Date::Manip;
         Date::Manip::Date_Init();
         $date_init = 1;
      }
      return _sort('','date',@_);
   }

   sub cmp_date {
      %cache = ();
      if (! $date_init) {
         require Date::Manip;
         Date::Manip::Date_Init();
         $date_init = 1;
      }
      return _cmp('','date',@_);
   }

   sub sort_rev_date {
      %cache = ();
      if (! $date_init) {
         require Date::Manip;
         Date::Manip::Date_Init();
         $date_init = 1;
      }
      return _sort('rev','date',@_);
   }

   sub cmp_rev_date {
      %cache = ();
      if (! $date_init) {
         require Date::Manip;
         Date::Manip::Date_Init();
         $date_init = 1;
      }
      return _cmp('rev','date',@_);
   }

   sub _date {
      my($ele) = @_;
      $cache{$ele} = Date::Manip::ParseDate($ele)  if (! exists $cache{$ele});
      return 1  if ($cache{$ele});
      return 0;
   }

   sub _cmp_date {
      my($x,$y) = @_;

      $cache{$x} = Date::Manip::ParseDate($x)  if (! exists $cache{$x});
      $cache{$y} = Date::Manip::ParseDate($y)  if (! exists $cache{$y});

      return $cache{$x} cmp $cache{$y};
   }
}

###############################################################################

sub sort_ip {
   return _sort('','ip',@_);
}

sub cmp_ip {
   return _cmp('','ip',@_);
}

sub sort_rev_ip {
   return _sort('rev','ip',@_);
}

sub cmp_rev_ip {
   return _cmp('rev','ip',@_);
}

sub _ip {
   my($ele) = @_;
   return 0  unless ($ele =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)(?:\/([0-9]+))?$/);
   my ($a,$b,$c,$d,$m) = ($1,$2,$3,$4,$5);
   return 0  if ($a > 255  ||
                 $b > 255  ||
                 $c > 255  ||
                 $d > 255  ||
                 $m > 32);
   return 1;
}

sub _cmp_ip {
   my($x,$y) = @_;
   my(@x,@y);
   $x =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)(?:\/([0-9]+))?$/;
   @x = ($1,$2,$3,$4,$5);
   $y =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)(?:\/([0-9]+))?$/;
   @y = ($1,$2,$3,$4,$5);
   return ($x[0] <=> $y[0]  ||
           $x[1] <=> $y[1]  ||
           $x[2] <=> $y[2]  ||
           $x[3] <=> $y[3]  ||
           (defined $x[4]    &&  ! defined $y[4]  &&  1)  ||
           (! defined $x[4]  &&  defined $y[4]    &&  -1)  ||
           (defined $x[4]    &&  defined $y[4]    &&  $x[4] <=> $y[4])  ||
           0);
}

###############################################################################
sub sort_nosort {
   return 1;
}

sub cmp_nosort {
   return -1;
}

sub sort_rev_nosort {
   return 1;
}

sub cmp_rev_nosort {
   return -1;
}

###############################################################################

sub sort_function {
   my $caller = ( caller )[0];
   return _sort('','function',@_,$caller);
}

sub cmp_function {
   my $caller = ( caller )[0];
   return _cmp('','function',@_,$caller);
}

sub sort_rev_function {
   my $caller = ( caller )[0];
   return _sort('rev','function',@_,$caller);
}

sub cmp_rev_function {
   my $caller = ( caller )[0];
   return _cmp('rev','function',@_,$caller);
}

sub _function {
   return 1;
}

sub _cmp_function {
   my($x,$y,$args) = @_;
   my ($func,$caller) = @$args;
   no strict 'refs';
   if (ref($func) eq 'CODE'  ||  $func =~ /::/) {
      return &$func($x,$y);
   } else  {
      $func      = $caller . "::$func";
      return &$func($x,$y);
   }
}

###############################################################################
# AMBIGUOUS METHODS
###############################################################################

sub sort_length {
   return _sort('','length',@_);
}

sub cmp_length {
   return _cmp('','length',@_);
}

sub sort_rev_length {
   return _sort('rev','length',@_);
}

sub cmp_rev_length {
   return _cmp('rev','length',@_);
}

sub _length {
   my($ele) = @_;
   return 1  if (! ref($ele));
   return 0;
}

sub _cmp_length {
   my($x,$y) = @_;
   return ( length($x) <=> length($y) );
}

###############################################################################
# SPLIT-ELEMENT METHODS
###############################################################################

sub sort_split {
   return _sort_split('','split',@_);
}

sub cmp_split {
   return _cmp_split('','split',@_);
}

sub sort_rev_split {
   return _sort_split('rev','split',@_);
}

sub cmp_rev_split {
   return _cmp_split('rev','split',@_);
}

###############################################################################

sub sort_domain {
   my($listref,@args) = @_;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      return sort_split($listref,'rms',@args);
   } else {
      return sort_split($listref,'rms',qr/\./,@args);
   }
}

sub cmp_domain {
   my($x,$y,@args) = @_;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      return cmp_split($x.$y,'rms',@args);
   } else {
      return cmp_split($x,$y,'rms',qr/\./,@args);
   }
}

sub sort_rev_domain {
   my($listref,@args) = @_;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      return sort_rev_split($listref,'rms',@args);
   } else {
      return sort_rev_split($listref,'rms',qr/\./,@args);
   }
}

sub cmp_rev_domain {
   my($x,$y,@args) = @_;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      return cmp_rev_split($x,$y,'rms',@args);
   } else {
      return cmp_rev_split($x,$y,'rms',qr/\./,@args);
   }
}

###############################################################################

sub sort_numdomain {
   my($listref,@args) = @_;

   $methods{'split'}{'alt'} = 'alphanum';
   $methods{'rev_split'}{'alt'} = 'alphanum';

   my $ret;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      $ret = sort_split($listref,'rms',@args);
   } else {
      $ret = sort_split($listref,'rms',qr/\./,@args);
   }

   $methods{'split'}{'alt'} = 'alphabetic';
   $methods{'rev_split'}{'alt'} = 'alphabetic';
   return $ret;
}

sub cmp_numdomain {
   my($x,$y,@args) = @_;

   $methods{'split'}{'alt'} = 'alphanum';
   $methods{'rev_split'}{'alt'} = 'alphanum';

   my $ret;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      $ret = cmp_split($x,$y,'rms',@args);
   } else {
      $ret = cmp_split($x,$y,'rms',qr/\./,@args);
   }

   $methods{'split'}{'alt'} = 'alphabetic';
   $methods{'rev_split'}{'alt'} = 'alphabetic';
   return $ret;
}

sub sort_rev_numdomain {
   my($listref,@args) = @_;

   $methods{'split'}{'alt'} = 'alphanum';
   $methods{'rev_split'}{'alt'} = 'alphanum';

   my $ret;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      $ret = sort_rev_split($listref,'rms',@args);
   } else {
      $ret = sort_rev_split($listref,'rms',qr/\./,@args);
   }

   $methods{'split'}{'alt'} = 'alphabetic';
   $methods{'rev_split'}{'alt'} = 'alphabetic';
   return $ret;
}

sub cmp_rev_numdomain {
   my($x,$y,@args) = @_;

   $methods{'split'}{'alt'} = 'alphanum';
   $methods{'rev_split'}{'alt'} = 'alphanum';

   my $ret;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      $ret = cmp_rev_split($x,$y,'rms',@args);
   } else {
      $ret = cmp_rev_split($x,$y,'rms',qr/\./,@args);
   }

   $methods{'split'}{'alt'} = 'alphabetic';
   $methods{'rev_split'}{'alt'} = 'alphabetic';
   return $ret;
}

###############################################################################

sub sort_path {
   my($listref,@args) = @_;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      return sort_split($listref,'lms',@args);
   } else {
      return sort_split($listref,'lms',qr/\//,@args);
   }
}

sub cmp_path {
   my($x,$y,@args) = @_;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      return cmp_split($x.$y,'lms',@args);
   } else {
      return cmp_split($x,$y,'lms',qr/\//,@args);
   }
}

sub sort_rev_path {
   my($listref,@args) = @_;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      return sort_rev_split($listref,'lms',@args);
   } else {
      return sort_rev_split($listref,'lms',qr/\//,@args);
   }
}

sub cmp_rev_path {
   my($x,$y,@args) = @_;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      return cmp_rev_split($x,$y,'lms',@args);
   } else {
      return cmp_rev_split($x,$y,'lms',qr/\//,@args);
   }
}

###############################################################################

sub sort_numpath {
   my($listref,@args) = @_;

   $methods{'split'}{'alt'} = 'alphanum';
   $methods{'rev_split'}{'alt'} = 'alphanum';

   my $ret;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      $ret = sort_split($listref,'lms',@args);
   } else {
      $ret = sort_split($listref,'lms',qr/\//,@args);
   }

   $methods{'split'}{'alt'} = 'alphabetic';
   $methods{'rev_split'}{'alt'} = 'alphabetic';
   return $ret;
}

sub cmp_numpath {
   my($x,$y,@args) = @_;

   $methods{'split'}{'alt'} = 'alphanum';
   $methods{'rev_split'}{'alt'} = 'alphanum';

   my $ret;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      $ret = cmp_split($x,$y,'lms',@args);
   } else {
      $ret = cmp_split($x,$y,'lms',qr/\//,@args);
   }

   $methods{'split'}{'alt'} = 'alphabetic';
   $methods{'rev_split'}{'alt'} = 'alphabetic';
   return $ret;
}

sub sort_rev_numpath {
   my($listref,@args) = @_;

   $methods{'split'}{'alt'} = 'alphanum';
   $methods{'rev_split'}{'alt'} = 'alphanum';

   my $ret;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      $ret = sort_rev_split($listref,'lms',@args);
   } else {
      $ret = sort_rev_split($listref,'lms',qr/\//,@args);
   }

   $methods{'split'}{'alt'} = 'alphabetic';
   $methods{'rev_split'}{'alt'} = 'alphabetic';
   return $ret;
}

sub cmp_rev_numpath {
   my($x,$y,@args) = @_;

   $methods{'split'}{'alt'} = 'alphanum';
   $methods{'rev_split'}{'alt'} = 'alphanum';

   my $ret;
   if (@args  &&  (ref($args[0]) eq ''  ||  ref($args[0]) eq 'Regexp')) {
      $ret = cmp_rev_split($x,$y,'lms',@args);
   } else {
      $ret = cmp_rev_split($x,$y,'lms',qr/\//,@args);
   }

   $methods{'split'}{'alt'} = 'alphabetic';
   $methods{'rev_split'}{'alt'} = 'alphabetic';
   return $ret;
}

###############################################################################
# PARTIAL-ELEMENT METHODS
###############################################################################

sub sort_partial {
   return _sort_partial('','partial',@_);
}

sub cmp_partial {
   return _cmp_partial('','partial',@_);
}

sub sort_rev_partial {
   return _sort_partial('rev','partial',@_);
}

sub cmp_rev_partial {
   return _cmp_partial('rev','partial',@_);
}

###############################################################################

sub sort_line {
   my($listref,$n,@args) = @_;

   my $sep;
   if (@args  &&  (ref($args[0]) eq 'Regexp'  ||  ! ref($args[0]))) {
      $sep = shift(@args);
   }

   my $hash;
   if (@args) {
      $hash = shift(@args);
   }

   my @a = ($listref);
   push(@a,$sep)  if (defined $sep);
   push(@a,[$n,['alphabetic']]);

   return sort_partial(@a);
}

sub cmp_line {
   my($x,$y,$n,$sep) = @_;
   my @a = ($x,$y);
   push(@a,$sep)  if (defined $sep);
   push(@a,[$n,['alphabetic']]);

   return cmp_partial(@a);
}

sub sort_rev_line {
   my($listref,$n,@args) = @_;

   my $sep;
   if (@args  &&  (ref($args[0]) eq 'Regexp'  ||  ! ref($args[0]))) {
      $sep = shift(@args);
   }

   my $hash;
   if (@args) {
      $hash = shift(@args);
   }

   my @a = ($listref);
   push(@a,$sep)  if (defined $sep);
   push(@a,[$n,['alphabetic']]);

   return sort_rev_partial(@a);
}

sub cmp_rev_line {
   my($x,$y,$n,$sep) = @_;
   my @a = ($x,$y);
   push(@a,$sep)  if (defined $sep);
   push(@a,[$n,['alphabetic']]);

   return cmp_rev_partial(@a);
}

###############################################################################
sub sort_numline {
   my($listref,$n,@args) = @_;

   my $sep;
   if (@args  &&  (ref($args[0]) eq 'Regexp'  ||  ! ref($args[0]))) {
      $sep = shift(@args);
   }

   my $hash;
   if (@args) {
      $hash = shift(@args);
   }

   my @a = ($listref);
   push(@a,$sep)  if (defined $sep);
   push(@a,[$n,['alphanum']]);

   return sort_partial(@a);
}

sub cmp_numline {
   my($x,$y,$n,$sep) = @_;
   my @a = ($x,$y);
   push(@a,$sep)  if (defined $sep);
   push(@a,[$n,['alphanum']]);

   return cmp_partial(@a);
}

sub sort_rev_numline {
   my($listref,$n,@args) = @_;

   my $sep;
   if (@args  &&  (ref($args[0]) eq 'Regexp'  ||  ! ref($args[0]))) {
      $sep = shift(@args);
   }

   my $hash;
   if (@args) {
      $hash = shift(@args);
   }

   my @a = ($listref);
   push(@a,$sep)  if (defined $sep);
   push(@a,[$n,['alphanum']]);

   return sort_rev_partial(@a);
}

sub cmp_rev_numline {
   my($x,$y,$n,$sep) = @_;
   my @a = ($x,$y);
   push(@a,$sep)  if (defined $sep);
   push(@a,[$n,['alphanum']]);

   return cmp_rev_partial(@a);
}

###############################################################################
###############################################################################

# Only used for ambiguous/unambiguous comparisons.
sub _sort {
   my($rev,$method,@args) = @_;

   my($err,$list,$args,$hash,@extra) = _args_sort($method,@args);
   return undef  if ($err);
   return 1      if (! @$list);

   # Sort the list.

   my @list;
   if (defined $hash) {
      @list = sort { __cmp($rev,$method,$$hash{$a},$$hash{$b},$args,@extra) } @$list;
   } else {
      @list = sort { __cmp($rev,$method,$a,$b,$args,@extra) } @$list;
   }

   # Done

   @$list = @list;
   return 1;
}

# Only used for ambiguous/unambiguous comparisons.
sub _cmp {
   my($rev,$method,@args) = @_;

   my($err,$x,$y,$args,@extra) = _args_cmp($method,@args);
   return undef  if ($err);
   return __cmp($rev,$method,$x,$y,$args,@extra);
}

# Only used for ambiguous/unambiguous comparisons.
sub __cmp {
   my($rev,$method,$x,$y,$args,@extra) = @_;

   no strict 'refs';

   # Compare the two elements

   my($func,$cmp,$flag,$sort_type);

   $func = $methods{$method}{'function'};
   $cmp  = "_cmp_$func";
   $flag = &$cmp($x,$y,$args);
   return $flag  if (! defined($flag));
   $sort_type = $methods{$method}{'type'};

   while (! $flag  &&  (@extra  ||  $sort_type ne 'unambiguous')) {
      if (@extra) {
         if (ref($extra[0]) eq 'ARRAY') {
            my(@args);
            ($method,@args) = @{ shift(@extra) };
            if (! exists $methods{$method}) {
               warn "ERROR: alternate sort error - invalid method: $method\n";
               return undef;
            }
            my($err,$method_args) = _args_method_args($method,\@args);
            return undef  if ($err);
            if (@args) {
               warn "ERROR: alternate sort error - invalid arguments: @args\n";
               return undef;
            }
            $args = $method_args;
         } else {
            warn "ERROR: alternate sort error - invalid definition\n";
            return undef;
         }

      } else {
         $method = $methods{$method}{'alt'};
         $args   = $methods{$method}{'altargs'};
      }
      $func      = $methods{$method}{'function'};
      $cmp       = "_cmp_$func";
      $flag      = &$cmp($x,$y,$args);
      return $flag  if (! defined($flag));
      $sort_type = $methods{$method}{'type'};
   }

   # If it's reverse...

   if ($rev  ||  $methods{$method}{'reverse'}) {
      $flag *= -1;
   }

   # Done

   return $flag;
}

###############################################################################

sub _sort_split {
   my($rev,$method,@args) = @_;

   my($err,$list,$args,$hash,@extra) = _args_sort($method,@args);
   return undef  if ($err);
   return 1      if (! @$list);

   # Sort the list.

   my @list;
   if (defined $hash) {
      @list = sort { __cmp_split($rev,$method,$$hash{$a},$$hash{$b},$args,@extra) } @$list;
   } else {
      @list = sort { __cmp_split($rev,$method,$a,$b,$args,@extra) } @$list;
   }

   # Done

   @$list = @list;
   return 1;
}

sub _cmp_split {
   my($rev,$method,@args) = @_;

   my($err,$x,$y,$args,@extra) = _args_cmp($method,@args);
   return undef  if ($err);
   return __cmp_split($rev,$method,$x,$y,$args,@extra);
}

sub __cmp_split {
   my($rev,$method,$x,$y,$args,@extra) = @_;

   no strict 'refs';

   # Compare the two elements

   my(@x,@y,$ms,$re);
   ($ms,$re) = @$args;
   @x        = split($re,$x);
   @y        = split($re,$y);

   my $flag  = 0;
   my $sort_method;

 PIECE: while (! $flag  &&  (@x  ||  @y)) {
      if ($ms eq 'rms') {
         $x  = pop(@x);
         $y  = pop(@y);
      } else {
         $x  = shift(@x);
         $y  = shift(@y);
      }
      $sort_method = $method;

      # Handle the case where one (or both) is missing

      if (! defined $x  ||  $x eq '') {
         if (! defined $y  ||  $y eq '') {
            $flag = 0;
            next PIECE;
         } else {
            $flag = -1;
            last PIECE;
         }
      } elsif (! defined $y  ||  $y eq '') {
         $flag = 1;
         last PIECE;
      }

      # Compare two pieces

      my $sort_type = 'split';

      while (! $flag  &&  (@extra  ||  $sort_type ne 'unambiguous')) {
         if (@extra) {
            if (ref($extra[0]) eq 'ARRAY') {
               my(@args);
               ($sort_method,@args) = @{ shift(@extra) };
               if (! exists $methods{$sort_method}) {
                  warn "ERROR: alternate sort error - invalid method: $sort_method\n";
                  return undef;
               }
               my($err,$method_args) = _args_method_args($sort_method,\@args);
               return undef  if ($err);
               if (@args) {
                  warn "ERROR: alternate sort error - invalid arguments: @args\n";
                  return undef;
               }
               $args = $method_args;
            } else {
               warn "ERROR: alternate sort error - invalid definition\n";
               return undef;
            }

         } else {
            $args   = $methods{$sort_method}{'altargs'};
            $sort_method = $methods{$sort_method}{'alt'};
         }

         my $func   = $methods{$sort_method}{'function'};
         my $cmp    = "_cmp_$func";
         $flag      = &$cmp($x,$y,$args);
         return $flag  if (! defined($flag));
         $sort_type = $methods{$sort_method}{'type'};
      }
   }

   # If it's reverse...

   if ($rev  ||  $methods{$sort_method}{'reverse'}) {
      $flag *= -1;
   }

   # Done

   return $flag;
}

###############################################################################

sub _sort_partial {
   my($rev,$method,@args) = @_;

   my($err,$list,$args,@extra) = _args_sort($method,@args);
   return undef  if ($err);
   return 1      if (! @$list);

   # Sort the list.

   my @list;
   @list = sort { __cmp_partial($rev,$method,$a,$b,$args,@extra) } @$list;

   # Done

   @$list = @list;
   return 1;
}

sub _cmp_partial {
   my($rev,$method,@args) = @_;

   my($err,$x,$y,$args,@extra) = _args_cmp($method,@args);
   return undef  if ($err);
   return __cmp_partial($rev,$method,$x,$y,$args,@extra);
}

sub __cmp_partial {
   my($rev,$method,$x,$y,$args,@extra) = @_;

   no strict 'refs';

   # Compare the two elements

   my(@x,@y,$re);
   $re   = $$args[0];
   @x    = split($re,$x);
   @y    = split($re,$y);

   my $flag  = 0;
   my $sort_method;

 FIELD: foreach my $field_args (@extra) {
      my @field_args = @$field_args;

      # Get $n

      if (! @field_args) {
         warn "ERROR: field args error - field number required\n";
         return undef;
      }
      my $n = shift(@field_args);
      if ($n !~ /^\d+$/) {
         warn "ERROR: field args error - field number must be integer: $n\n";
         return undef;
      }

      # Get $hash

      my $hash;
      if (@field_args  &&  ref($field_args[0]) eq 'HASH') {
         $hash = shift(@field_args);
      } else {
         $hash = undef;
      }

      # Get the Nth fields (and handle the undef cases)

      my($a,$b);
      if (@x < $n  ||  ! defined $x[$n-1]  ||  $x[$n-1] eq '') {
         if (@y < $n  ||  ! defined $y[$n-1]  ||  $y[$n-1] eq '') {
            $flag = 0;
            next FIELD;
         } else {
            $flag = -1;
            last FIELD;
         }
      } elsif (@y < $n  ||  ! defined $y[$n-1]  ||  $y[$n-1] eq '') {
         $flag = 1;
         last FIELD;
      }

      $a = $x[$n-1];
      $b = $y[$n-1];

      # Handle $hash (if defined)

      if (defined $hash) {
         if (! exists $$hash{$a}) {
            if (! exists $$hash{$b}) {
               $flag = 0;
               next FIELD;
            } else {
               $flag = -1;
               last FIELD;
            }
         } elsif (! exists $$hash{$b}) {
            $flag = 1;
            last FIELD;
         }
         $a = $$hash{$a};
         $b = $$hash{$b};
      }

      # Compare two fields

      $sort_method = 'partial';
      my $sort_type = 'partial';

    METHOD: while (! $flag  &&  (@field_args  ||  $sort_type ne 'unambiguous')) {
         if (@field_args) {
            if (ref($field_args[0]) eq 'ARRAY') {
               my(@args);
               ($sort_method,@args) = @{ shift(@field_args) };
               if (! exists $methods{$sort_method}) {
                  warn "ERROR: alternate sort error - invalid method: $sort_method\n";
                  return undef;
               }
               my($err,$method_args) = _args_method_args($sort_method,\@args);
               return undef  if ($err);
               if (@args) {
                  warn "ERROR: alternate sort error - invalid arguments: @args\n";
                  return undef;
               }
               $args = $method_args;
            } else {
               warn "ERROR: alternate sort error - invalid definition\n";
               return undef;
            }

         } else {
            $args   = $methods{$sort_method}{'altargs'};
            $sort_method = $methods{$sort_method}{'alt'};
         }

         my $func   = $methods{$sort_method}{'function'};
         my $cmp    = "_cmp_$func";
         $flag      = &$cmp($a,$b,$args);
         return $flag  if (! defined($flag));
         $sort_type = $methods{$sort_method}{'type'};
      }

      last FIELD  if ($flag);
   }

   # If it's reverse...

   if ($rev  ||  $methods{$sort_method}{'reverse'}) {
      $flag *= -1;
   }

   # Done

   return $flag;
}

###############################################################################

sub _args_sort {
   my(@args) = @_;
   my(@ret,$err,$method,$listref,$method_args,$hash);

   # Method

   if (! @args) {
      warn "ERROR: sort argument error - method required\n";
      return (1);
   }
   $method = shift(@args);
   if (! exists $methods{$method}) {
      warn "ERROR: sort argument error - invalid method: $method\n";
      return (1);
   }

   # Listref

   if (! @args) {
      warn "ERROR: sort argument error - listref expected\n";
      return (1);
   }

   if (ref($args[0]) eq 'ARRAY') {
      $listref = shift(@args);
   } else {
      warn "ERROR: sort argument error - listref expected\n";
      return (1);
   }
   push(@ret,$listref);

   # Method arguments

   ($err,$method_args) = _args_method_args($method,\@args);
   return (1)  if ($err);
   push(@ret,$method_args);

   # Hash

   if ($method ne 'partial') {
      if (@args  &&  ref($args[0]) eq 'HASH') {
         $hash = shift(@args);
      } else {
         $hash = undef;
      }
      push(@ret,$hash);
   }

   # Extra

   if ($method eq 'unambiguous'  &&  @args) {
      warn "ERROR: sort argument error - unexpected arguments: @args\n";
      return (1);
   }

   return (0,@ret,@args);
}

# ($method,$x,$y,@method_args,@extra)
#
sub _args_cmp {
   my(@args) = @_;
   my(@ret,$err,$method,$x,$y,$method_args,$hash);

   # Method

   if (! @args) {
      warn "ERROR: cmp argument error - method required\n";
      return (1);
   }
   $method = shift(@args);
   if (! exists $methods{$method}) {
      warn "ERROR: cmp argument error - invalid method: $method\n";
      return (1);
   }

   # X,Y

   if (@args < 2) {
      warn "ERROR: cmp argument error - two elements expected\n";
      return (1);
   }
   $x = shift(@args);
   $y = shift(@args);
   push(@ret,$x,$y);

   # Method arguments

   ($err,$method_args) = _args_method_args($method,\@args);
   return (1)  if ($err);
   push(@ret,$method_args);

   # Extra

   if ($method eq 'unambiguous'  &&  @args) {
      warn "ERROR: cmp argument error - unexpected arguments: @args\n";
      return (1);
   }

   return (0,@ret,@args);
}

sub _args_method_args {
   my($method,$args) = @_;
   my @method_args;

   my @expected = @{ $methods{$method}{'args'} };

   foreach my $expected (@expected) {
      my $type = $$expected{'type'};

      if      ($type eq 'member') {
         my %vals = map { $_,1 } @{ $$expected{'values'} };
         if (@$args  &&  exists $vals{ $$args[0] }) {
            push(@method_args,shift(@$args));
         } else {
            push(@method_args,$$expected{'default'});
         }

      } elsif ($type eq 'regexp') {
         if (@$args) {
            if (ref($$args[0]) eq 'Regexp') {
               push(@method_args,shift(@$args));
            } elsif (! ref($$args[0])) {
               my $re = shift(@$args);
               push(@method_args,qr/$re/);
            } else {
               my $re = $$expected{'default'};
               push(@method_args,qr/$re/);
            }
         } else {
            my $re = $$expected{'default'};
            push(@method_args,qr/$re/);
         }

      } elsif ($type eq 'function') {
         if (@$args  &&  (ref($$args[0]) eq 'CODE'  ||  ! ref($$args[0]))) {
            push(@method_args,shift(@$args));
         } else {
            die "ERROR: invalid argument - function required\n";
         }

      } elsif ($type eq 'string') {
         if (@$args  &&  ! ref($$args[0])) {
            push(@method_args,shift(@$args));
         } elsif (exists $$expected{'default'}) {
            push(@method_args,$$expected{'default'});
         } else {
            die "ERROR: invalid argument - string required\n";
         }

      } else {
         die "ERROR: invalid argument descriptor: $type\n";
      }
   }

   return (0,\@method_args);
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
