# Copyright 2016 The Michael Song. All rights rberved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

package Spp::IsAtom;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(is_array is_false is_true is_bool is_chars
  is_atom is_atoms is_sym is_spec is_tillnot
  is_look is_rept is_str_atom is_array_atom);

use 5.012;
no warnings "experimental";
use Spp::Tools;

sub is_array {
   my $x = shift;
   return 1 if ref($x) eq ref([]);
   return 0;
}

sub is_false {
   my $x = shift;
   return 1 if is_array($x) and $x->[0] eq 'false';
   return 0;
}

sub is_true {
   my $x = shift;
   return 1 if is_array($x) and $x->[0] eq 'true';
   return 0;
}

sub is_bool {
   my $x = shift;
   return 1 if is_false($x) or is_true($x);
   return 0;
}

sub is_chars {
   my $x = shift;
   return 1 if ref($x) eq ref('');
   return 0;
}

sub is_atom {
   my $x = shift;
   return 0 if not(is_array($x));
   return 0 if scalar(@{$x}) < 2;
   return 0 if not(is_chars($x->[0]));
   return 1;
}

sub is_atoms {
   my $pairs = shift;
   if (is_array($pairs)) {
      for my $pair (@{$pairs}) {
         next if is_atom($pair);
         return 0;
      }
      return 1;
   }
   return 0;
}

sub is_sym {
   my $rs = shift;
   return 1 if is_atom($rs) and $rs->[0] eq 'Sym';
   return 0;
}

sub is_spec {
   my $atom = shift;
   return 0 if !is_atom($atom);
   return 1 if $atom->[0] eq 'Spec';
   return 0;
}

sub is_rept {
   my $s = shift;
   if (is_atom($s)) {
      return 1 if $s->[0] eq '@Rept';
      return 0;
   }
   return 0;
}

sub is_look {
   my $s = shift;
   if (is_atom($s)) {
      return 1 if $s->[0] eq '@Look';
      return 0;
   }
   return 0;
}

sub is_tillnot {
   my $s = shift;
   if (is_atom($s)) {
      return 1 if $s->[0] eq 'Till';
      return 1 if $s->[0] eq 'Not';
      return 0;
   }
   return 0;
}

sub is_str_atom {
   my $atom = shift;
   if (is_atom($atom)) {
      return 1 if $atom->[0] eq 'Str';
      return 0;
   }
   return 0;
}

sub is_array_atom {
   my $atom = shift;
   if (is_atom($atom)) {
      return 1 if $atom->[0] eq 'Array';
      return 0;
   }
   return 0;
}

sub type {
  my $atom = shift;
  return 'false' if is_false($atom);
  return 'true' if is_true($atom);
  return 'str' if is_chars($atom);
  return $atom->[0] if is_atom($atom);
  return 'None';
}

1;
