#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use PerlIO::via::EscStatus qw(ESCSTATUS_STR);
use PerlIO::via::EscStatus::ShowAll;
use PerlIO::via::EscStatus::ShowNone;
#use PerlIO::Util;
use charnames ':full';
use List::Util qw(min max);

{
  my $buf = '';
  # open my $out, '>', \$buf or die;
  open my $out, '> :via(EscStatus)', '/dev/tty' or die;
  #  binmode ($out, ':via(EscStatus)') or die;

  { my @l = PerlIO::get_layers ($out, details => 1);
    print STDERR "input side ", Dumper (\@l); }

  { my @l = PerlIO::get_layers ($out, output => 1, details => 1);
    print STDERR "output side ", Dumper (\@l); }

  $out->autoflush(0);
  print $out PerlIO::via::EscStatus::make_status('hello');
  # print $out PerlIO::via::EscStatus::make_status('');

  print "\nnow closing\n";
  close $out or die $!;
  print "buf: ", Dumper (\$buf);
  exit 0;
}

{
  binmode (STDOUT, ':via(EscStatus)') or die;

  { my @l = PerlIO::get_layers (STDOUT, details => 1);
    print STDERR "input side ", Dumper (\@l); }

  { my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
    print STDERR "output side ", Dumper (\@l); }

  STDOUT->autoflush(0);
  print STDOUT PerlIO::via::EscStatus::make_status('hello');
  # print STDOUT PerlIO::via::EscStatus::make_status('');
  close STDOUT or die $!;
  exit 0;
}

# {
#   # no layers support on IO::String
#   require IO::String;
#   my $buf = '';
#   my $out = IO::String->new (\$buf);
#   my @l = PerlIO::get_layers ($out, output => 1, details => 1);
#   print STDERR Dumper (\@l);
#   use PerlIO::via::QuotedPrint;
#   binmode ($out, ':via(QuotedPrint)'); # or die $!;
#   print $out PerlIO::via::EscStatus::make_status('hello');
#   $out->close or die;
#   exit 0;
# }
# 
# {
#   my $str = "Job \N{VULGAR FRACTION ONE QUARTER} finished";
#   print utf8::is_utf8($str) ? "yes\n" : "no\n";
#   exit 0;
# }
# 
# {
#   my $x = ('X' x 512);
#   my $y = $x;
#   my $z = substr ($x, 0, 512);
#   require Devel::Peek;
#   Devel::Peek::Dump ($x);
#   Devel::Peek::Dump ($y);
#   Devel::Peek::Dump ($z);
#   exit 0;
# }
# 
# {
#   my ($str, $len) = PerlIO::via::EscStatus::_truncate
#     ("\x{9B}35mfoobar\x{9B}30m", 3);
#   print "$len: \"$str\"\n";
#   exit 0;
#   # "\e[55mx\x{300} y\tAbCdEfGhIjKlMn"
# }
# 
# binmode (STDOUT, ":utf8");
# 
# # use unicore::lib::gc_sc::OtherMat;
# 
# {
#   #  binmode (STDOUT, ':locale') or die $!;
# 
#   print STDERR "binmode\n";
#   binmode (STDOUT, ':via(EscStatus)') or die $!;
# 
#   # binmode (STDOUT, ':bytes') or die $!;
#   # binmode (STDOUT, ':utf8') or die $!;
# 
#   # binmode (STDOUT, ':via(EscStatus):utf8') or die $!;
#   # binmode (STDOUT, ':via(EscStatus::ShowAll)') or die $!;
#   # binmode (STDOUT, ':via(EscStatus::Transparent)') or die $!;
# 
#   print STDERR "binmode done\n";
# 
#   my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
#   print STDERR Dumper (\@l);
# 
#   print ESCSTATUS_STR()."\x{e2}\x{98}\x{ba}\n";
#   # print ESCSTATUS_STR()."\x{263a}\n";
#   #print ESCSTATUS_STR()."\N{DEGREE SIGN}\n";
#   print ESCSTATUS_STR()."ab\n";
#   close STDOUT or die;
# 
# #  binmode STDOUT or die;
#   exit 0;
# }
# 
# 
# 
# {
#   print "autoflush now $|\n";
#   print "abc";
#   PerlIO::via::EscStatus::_flush (\*STDOUT);
#   print "autoflush now $|";
#   sleep 5;
#   exit 0;
# }
# 
# {
#   print "\x{FF41}\n";
#   exit 0;
# }
# 
# {
#   my $in_range = 0;
#   my $prev;
#   foreach (0 .. 0xFFFF) {
#     #     if (($_ >= 0xd800 && $_ <= 0xdFFF)
#     #         || ($_ >= 0xfdd0 && $_ <= 0x)) { goto FALSE; }
#     my $str = do { no warnings; chr ($_); };
#     if (! eval { $str =~ /\pM/; 1 }) {
#       goto FALSE;
#     }
# 
#     utf8::upgrade ($str); # 128 to 255
#     # if ($str =~ /[[:graph:]]/) { printf "%#X\n", $_; }
#     if ($str =~ /\p{EastAsianWidth:W}/) {
#       # if ($str =~ /\p{gc_sc_Copt}/) {
#       if ($in_range) {
#         # continue
#       } else {
#         printf "%#X", $_;
#         $prev = $_;
#         $in_range = 1;
#       }
#     } else {
#     FALSE:
#       if ($in_range) {
#         if ($prev == $_-1) {
#           print "\n";
#         } else {
#           printf "-%#X\n", $_-1;
#         }
#         $in_range = 0;
#       } else {
#         # nothing
#       }
#     }
#   }
#   exit 0;
# }
# 
# 
# 
# 
# 
# {
#   require POSIX;
#   my $loc = POSIX::setlocale(POSIX::LC_CTYPE(), "en_US.UTF-8");
#   print defined $loc ? $loc : 'undef',"\n";
#   exit 0;
# }
# 
# {
#   print prototype('CORE::open'),"\n";
#   print prototype('CORE::print'),"\n";
#   PerlIO::via::EscStatus::print_status ("foo");
#   exit 0;
# }
# {
#   print STDERR "binmode\n";
#   binmode (STDOUT, ':via(EscStatus)') or die $!;
#   # binmode (STDOUT, ':via(EscStatus::Transparent)') or die $!;
#   print STDERR "binmode done\n";
# 
#   my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
#   print Dumper (\@l);
# 
#   print ESCSTATUS_STR()."abcdefghijk\n";
#   print ESCSTATUS_STR()."abcdef\n";
#   print "Download error has occ\n";
# 
#   print "" or die;
#   print "hello" or die;
#   print " world\n" or die;
#   print ESCSTATUS_STR()."blah\n";
#   print ESCSTATUS_STR()."zz\n";
#   print "he\n" or die;
#   print " world\n" or die;
#   print "he " or die;
#   print ESCSTATUS_STR()."xjkdfs\n";
#   print "world\n" or die;
# 
#   print ESCSTATUS_STR()."ab";
#   print "cd\n";
# 
#   binmode STDOUT;
#   exit 0;
# }
# 
# 
# 
# 
# {
#   my $tt = PerlIO::via::EscStatus->new;
# 
#   print STDERR "binmode\n";
#   # binmode (STDOUT, ':via(PerlIO::via::EscStatus)') or die $!;
#   binmode (STDOUT, $tt->layer_string) or die $!;
#   print STDERR "binmode done\n";
# 
#   my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
#   print Dumper (\@l);
# 
#   print STDOUT "" or die;
#   print STDOUT "hello" or die;
#   print STDOUT " world\n" or die;
#   $tt->set_status ('blah');
#   print STDOUT "he\n" or die;
#   print STDOUT " world\n" or die;
# 
#   binmode STDOUT;
#   my $weak_tt = $tt;
#   Scalar::Util::weaken ($weak_tt);
#   $tt = undef;
#   print $weak_tt,"\n";
# 
#   require Devel::FindRef;
#   print STDERR Devel::FindRef::track (\$weak_tt);
#   exit 0;
# }
# 
# {
#   my $tt = PerlIO::via::EscStatus->new;
#   binmode (STDOUT, $tt->layer_string) or die $!;
#   binmode STDOUT;
# 
#   my $weak_tt = $tt;
#   Scalar::Util::weaken ($weak_tt);
#   $tt = undef;
#   print $weak_tt,"\n";
#   require Devel::FindRef;
#   print STDERR Devel::FindRef::track (\$weak_tt);
#   exit 0;
# }
# 
# {
#   my $tt = PerlIO::via::EscStatus->new;
# 
#   open OUT, '>', '/tmp/xx' or die $!;
#   #  open OUT, '>', '/dev/tty3' or die $!;
#   # open OUT, '>:via(PerlIO::via::EscStatus)', '/dev/tty' or die;
#   #  open OUT, '>:via(PerlIO::via::EscStatus)', '/dev/tty' or die $!;
# 
#   print STDERR "binmode\n";
#   binmode (OUT, $tt->layer_string) or die $!;
#   print STDERR "binmode done\n";
# 
#   #   print STDERR "binmode\n";
#   #   binmode (OUT, $tt->layer_string) or die $!;
#   #   print STDERR "binmode done\n";
# 
#   #   print STDERR "push\n";
#   #   OUT->push_layer (via => 'PerlIO::via::EscStatus');
#   #   print STDERR "push done\n";
# 
#   my @l = PerlIO::get_layers (OUT, output => 1, details => 1);
#   print Dumper (\@l);
# 
#   print OUT "" or die;
#   print OUT "hello" or die;
#   print OUT " world\n" or die;
#   $tt->set_status ('blah');
#   print OUT "he\n" or die;
#   print OUT " world\n" or die;
# 
#   binmode OUT;
#   exit 0;
# }
# 
# 
# 
# 
# 
# {
#   print STDERR "binmode\n";
#   binmode (STDOUT, ':via(PerlIO::via::EscStatus)') or die $!;
#   print STDERR "binmode done\n";
# 
#   #   PerlIO::via::EscStatus::obj_from_handle (STDOUT);
#   #   PerlIO::via::EscStatus::obj_from_handle (STDOUT);
# 
#   #   print STDERR "push\n";
#   #   STDOUT->push_layer (via => 'PerlIO::via::EscStatus');
#   #   print STDERR "push done\n";
# 
#   #  print Dumper ($x);
# 
#   my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
#   print Dumper (\@l);
# 
#   print STDOUT "" or die;
#   print STDOUT "hello" or die;
#   print STDOUT " world\n" or die;
#   PerlIO::via::EscStatus->set_status ('blah');
#   print STDOUT "he\n" or die;
#   print STDOUT " world\n" or die;
# 
#   # binmode STDOUT;
#   exit 0;
# }
# 
# {
#   open OUT, '>', '/tmp/xx' or die $!;
# #  open OUT, '>', '/dev/tty3' or die $!;
#   # open OUT, '>:via(PerlIO::via::EscStatus)', '/dev/tty' or die;
#   #  open OUT, '>:via(PerlIO::via::EscStatus)', '/dev/tty' or die $!;
# 
#   print STDERR "binmode\n";
#   binmode (OUT, ':via(PerlIO::via::EscStatus)') or die $!;
#   print STDERR "binmode done\n";
# 
# #   print STDERR "push\n";
# #   OUT->push_layer (via => 'PerlIO::via::EscStatus');
# #   print STDERR "push done\n";
# 
#   #  print Dumper ($x);
# 
#     my @l = PerlIO::get_layers (OUT, output => 1, details => 1);
#     print Dumper (\@l);
# 
# 
#   print OUT "" or die;
#   print OUT "hello" or die;
#   print OUT " world\n" or die;
#   PerlIO::via::EscStatus->set_status ('');
#   print OUT "he\n" or die;
#   print OUT " world\n" or die;
# 
#   # binmode OUT;
#   close OUT or die;
#   exit 0;
# }
# __END__
# {
#   open OUT, '> :via(PerlIO::via::EscStatus)', '/dev/tty'
#     or die;
#   print OUT "" or die;
#   print OUT "hello" or die;
#   print OUT " world\n" or die;
#   print OUT "he\n" or die;
#   print OUT " world\n" or die;
#   close OUT or die;
#   exit 0;
# }
