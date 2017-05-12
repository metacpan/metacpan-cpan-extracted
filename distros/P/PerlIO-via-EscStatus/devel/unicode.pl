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


use strict;
use warnings;
use Data::Dumper;
use Encode qw(:fallbacks);
use PerlIO::via::EscStatus ('ESCSTATUS_STR');
use charnames ':full';

use PerlIO;
sub _fh_prints_wide {
  my ($fh) = @_;
  require PerlIO;
  return (PerlIO::get_layers($fh, output => 1, details => 1))[-1] # top flags
    & PerlIO::F_UTF8();
}

{
  local $Data::Dumper::Indent = 0;
  $|=1;

  require File::Spec;
  my $devnull = File::Spec->devnull;

  require Term::Size;
  open my $fh, '>', $devnull or die;
  print "$devnull size ", Dumper([Term::Size::chars($fh)]), "\n";

  my $width;
  my $fd = fileno($fh);
  if (defined $fd) {
    if (open my $tmp, '<&', $fd) {
      print "tmp fh $tmp, tmp fd ",Dumper([fileno($tmp)]), "\n";
      $width = Term::Size::chars($tmp);
      close $tmp;
    }
  }
  print "dup width ", Dumper(\$width);

  print STDERR "_term_width on fd=", (defined $fd ? $fd : 'undef'),"\n";
  print "null width ",PerlIO::via::EscStatus::_term_width($fh),"\n";
  exit 0;
}

{
  binmode (STDOUT, ':utf8') or die $!;
  print STDERR "prints wide ",_fh_prints_wide(\*STDOUT)?"yes":"no","\n";


  print STDERR "binmode ':via(EscStatus)'\n";
  binmode (STDOUT, ':via(EscStatus)') or die $!;
  print STDERR "binmode done\n";
print "\N{WHITE SMILING FACE}\n";

  binmode (STDOUT, ':bytes') or die $!;
  print STDERR "prints wide ",_fh_prints_wide(\*STDOUT)?"yes":"no","\n";
print "\N{WHITE SMILING FACE}\n";

  exit 0;
}
{
  require Term::Size;
  my $fh = \*STDOUT;
  print "tty size ", Term::Size::chars($fh), "\n";
  print "tty width ",PerlIO::via::EscStatus::_term_width($fh),"\n";
  exit 0;
}


{
  # binmode (STDOUT, ":utf8");

  no warnings 'once';
  $PerlIO::encoding::fallback = FB_PERLQQ;
  binmode (STDOUT, ":encoding(iso-8859-1)");

  print "\N{VULGAR FRACTION ONE QUARTER}\n";
  #   print "\x{263a}\n";
  #   print "\N{WHITE SMILING FACE}\n";
  #   STDOUT->flush;

  # binmode (STDOUT, ":encoding(ascii)");

  #  binmode (STDOUT, ':locale') or die $!;

  { my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
    print STDERR Dumper (\@l); }

  #   require Term::Size;
  #   print "tty width ", Term::Size::chars(\*STDOUT), "\n";
  #
  #   { my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
  #     print STDERR Dumper (\@l); }

  my $esc = ESCSTATUS_STR;
  #  $esc = '';
  print STDERR "binmode ':via(EscStatus)'\n";
  binmode (STDOUT, ':via(EscStatus)') or die $!;
  print STDERR "binmode done\n";

  { my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
    print STDERR Dumper (\@l); }

  sleep 1;
  print "$esc";
  print "\N{VULGAR FRACTION ONE QUARTER}\n";
  sleep 1;
  print "$esc";
  print "\N{WHITE SMILING FACE}\n";
  sleep 1;
  print "$esc";
  print "\N{DEGREE SIGN}\n";
  sleep 1;
  print "$esc";
  print "\N{LATIN SMALL LETTER A WITH CIRCUMFLEX}\n";
  sleep 1;
  #  print "${esc}ab\n";
  sleep 1;
  close STDOUT;

  exit 0;
}



{
  print "autoflush now $|\n";
  print "abc";
  PerlIO::via::EscStatus::_flush (\*STDOUT);
  print "autoflush now $|";
  sleep 5;
  exit 0;
}

{
  print "\x{FF41}\n";
  exit 0;
}

{
  my $in_range = 0;
  my $prev;
  foreach (0 .. 0xFFFF) {
    #     if (($_ >= 0xd800 && $_ <= 0xdFFF)
    #         || ($_ >= 0xfdd0 && $_ <= 0x)) { goto FALSE; }
    my $str = do { no warnings; chr ($_); };
    if (! eval { $str =~ /\pM/; 1 }) {
      goto FALSE;
    }

    utf8::upgrade ($str); # 128 to 255
    # if ($str =~ /[[:graph:]]/) { printf "%#X\n", $_; }
    if ($str =~ /\p{EastAsianWidth:W}/) {
      # if ($str =~ /\p{gc_sc_Copt}/) {
      if ($in_range) {
        # continue
      } else {
        printf "%#X", $_;
        $prev = $_;
        $in_range = 1;
      }
    } else {
    FALSE:
      if ($in_range) {
        if ($prev == $_-1) {
          print "\n";
        } else {
          printf "-%#X\n", $_-1;
        }
        $in_range = 0;
      } else {
        # nothing
      }
    }
  }
  exit 0;
}





{
  require POSIX;
  my $loc = POSIX::setlocale(POSIX::LC_CTYPE(), "en_US.UTF-8");
  print defined $loc ? $loc : 'undef',"\n";
  exit 0;
}

{
  print prototype('CORE::open'),"\n";
  print prototype('CORE::print'),"\n";
  PerlIO::via::EscStatus::print_status ("foo");
  exit 0;
}
{
  print STDERR "binmode\n";
  binmode (STDOUT, ':via(EscStatus)') or die $!;
  # binmode (STDOUT, ':via(EscStatus::Transparent)') or die $!;
  print STDERR "binmode done\n";

  my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
  print Dumper (\@l);

  my $esc = ESCSTATUS_STR;

  print "${esc}abcdefghijk\n";
  print "${esc}abcdef\n";
  print "Download error has occ\n";

  print "" or die;
  print "hello" or die;
  print " world\n" or die;
  print "${esc}blah\n";
  print "${esc}zz\n";
  print "he\n" or die;
  print " world\n" or die;
  print "he " or die;
  print "${esc}xjkdfs\n";
  print "world\n" or die;

  print "${esc}ab";
  print "cd\n";

  binmode STDOUT;
  exit 0;
}




{
  my $tt = PerlIO::via::EscStatus->new;

  print STDERR "binmode\n";
  # binmode (STDOUT, ':via(PerlIO::via::EscStatus)') or die $!;
  binmode (STDOUT, $tt->layer_string) or die $!;
  print STDERR "binmode done\n";

  my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
  print Dumper (\@l);

  print STDOUT "" or die;
  print STDOUT "hello" or die;
  print STDOUT " world\n" or die;
  $tt->set_status ('blah');
  print STDOUT "he\n" or die;
  print STDOUT " world\n" or die;

  binmode STDOUT;
  my $weak_tt = $tt;
  Scalar::Util::weaken ($weak_tt);
  $tt = undef;
  print $weak_tt,"\n";

  require Devel::FindRef;
  print STDERR Devel::FindRef::track (\$weak_tt);
  exit 0;
}

{
  my $tt = PerlIO::via::EscStatus->new;
  binmode (STDOUT, $tt->layer_string) or die $!;
  binmode STDOUT;

  my $weak_tt = $tt;
  Scalar::Util::weaken ($weak_tt);
  $tt = undef;
  print $weak_tt,"\n";
  require Devel::FindRef;
  print STDERR Devel::FindRef::track (\$weak_tt);
  exit 0;
}

{
  my $tt = PerlIO::via::EscStatus->new;

  open OUT, '>', '/tmp/xx' or die $!;
  #  open OUT, '>', '/dev/tty3' or die $!;
  # open OUT, '>:via(PerlIO::via::EscStatus)', '/dev/tty' or die;
  #  open OUT, '>:via(PerlIO::via::EscStatus)', '/dev/tty' or die $!;

  print STDERR "binmode\n";
  binmode (OUT, $tt->layer_string) or die $!;
  print STDERR "binmode done\n";

  #   print STDERR "binmode\n";
  #   binmode (OUT, $tt->layer_string) or die $!;
  #   print STDERR "binmode done\n";

  #   print STDERR "push\n";
  #   OUT->push_layer (via => 'PerlIO::via::EscStatus');
  #   print STDERR "push done\n";

  my @l = PerlIO::get_layers (OUT, output => 1, details => 1);
  print Dumper (\@l);

  print OUT "" or die;
  print OUT "hello" or die;
  print OUT " world\n" or die;
  $tt->set_status ('blah');
  print OUT "he\n" or die;
  print OUT " world\n" or die;

  binmode OUT;
  exit 0;
}





{
  print STDERR "binmode\n";
  binmode (STDOUT, ':via(PerlIO::via::EscStatus)') or die $!;
  print STDERR "binmode done\n";

  #   PerlIO::via::EscStatus::obj_from_handle (STDOUT);
  #   PerlIO::via::EscStatus::obj_from_handle (STDOUT);

  #   print STDERR "push\n";
  #   STDOUT->push_layer (via => 'PerlIO::via::EscStatus');
  #   print STDERR "push done\n";

  #  print Dumper ($x);

  my @l = PerlIO::get_layers (STDOUT, output => 1, details => 1);
  print Dumper (\@l);

  print STDOUT "" or die;
  print STDOUT "hello" or die;
  print STDOUT " world\n" or die;
  PerlIO::via::EscStatus->set_status ('blah');
  print STDOUT "he\n" or die;
  print STDOUT " world\n" or die;

  # binmode STDOUT;
  exit 0;
}

{
  open OUT, '>', '/tmp/xx' or die $!;
#  open OUT, '>', '/dev/tty3' or die $!;
  # open OUT, '>:via(PerlIO::via::EscStatus)', '/dev/tty' or die;
  #  open OUT, '>:via(PerlIO::via::EscStatus)', '/dev/tty' or die $!;

  print STDERR "binmode\n";
  binmode (OUT, ':via(PerlIO::via::EscStatus)') or die $!;
  print STDERR "binmode done\n";

#   print STDERR "push\n";
#   OUT->push_layer (via => 'PerlIO::via::EscStatus');
#   print STDERR "push done\n";

  #  print Dumper ($x);

    my @l = PerlIO::get_layers (OUT, output => 1, details => 1);
    print Dumper (\@l);


  print OUT "" or die;
  print OUT "hello" or die;
  print OUT " world\n" or die;
  PerlIO::via::EscStatus->set_status ('');
  print OUT "he\n" or die;
  print OUT " world\n" or die;

  # binmode OUT;
  close OUT or die;
  exit 0;
}
__END__
{
  open OUT, '> :via(PerlIO::via::EscStatus)', '/dev/tty'
    or die;
  print OUT "" or die;
  print OUT "hello" or die;
  print OUT " world\n" or die;
  print OUT "he\n" or die;
  print OUT " world\n" or die;
  close OUT or die;
  exit 0;
}
