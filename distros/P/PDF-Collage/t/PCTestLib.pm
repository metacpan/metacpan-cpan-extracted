#!/usr/bin/env perl
package PCTestLib;
use v5.24;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
use File::Spec::Functions qw< splitpath splitdir catdir catpath >;
use Exporter 'import';
our @EXPORT_OK = qw< child parent sibling >;

sub child ($dir, $name) {
   my ($v, $dirs) = splitpath($dir, 'no-file');
   return catpath($v, $dirs, $name);
}

sub parent ($reference) {
   if (-d $reference) {
      my ($v, $dirs) = splitpath($reference, 'no-file');
      my @dirs = splitdir($dirs);
      pop @dirs;
      return catpath($v, catdir(@dirs));
   }
   my ($v, $dirs, undef) = splitpath($reference);
   return catpath($v, $dirs);
}

sub sibling ($reference, $name) {
   my ($v, $dirs, undef) = splitpath($reference);
   return catpath($v, $dirs, $name);
}



1;
