#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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

package PerlIO::via::MyLowlevel;
use strict;
use warnings;

sub PUSHED {
  my ($class, $mode, $fh) = @_;
  return bless {}, $class;
}

sub UTF8 {
  my ($self, $belowFlag, $fh) = @_;
  print STDERR "UTF8: ",$belowFlag?"yes":"no","\n";
  return ($self->{'utf8'} = $belowFlag);
}

sub FLUSH {
  my ($self, $fh) = @_;
  if ($fh) {
    return $fh->flush;
  } else {
    return 0; # success
  }
}

sub WRITE {
  my ($self, $buf, $fh) = @_;
  my $ret_ok = length ($buf);

  print STDERR "WRITE\n";
  # my $str = "\N{VULGAR FRACTION ONE QUARTER}\n";
  #my $str = "\x{263a}\n";
  # my $str = "\x{00BC}\n";
  # my $str = "\x{BC}\n";
  my $str = "\N{WHITE SMILING FACE}\n";

  #Encode::_utf8_off ($str);

  print $fh $str;
  return $ret_ok;
}

package main;
use strict;
use warnings;
use Data::Dumper;

$Data::Dumper::Useqq = 1;
{ my $str = "\N{VULGAR FRACTION ONE QUARTER}\n";
  Encode::_utf8_off ($str);
  print Dumper(\$str);
  print "  utf8=",utf8::is_utf8($str)?"yes":"no","\n";
}
{ my $str = "\x{BC}\n";
  print Dumper(\$str);
  print "  utf8=",utf8::is_utf8($str)?"yes":"no","\n";
}

{
  binmode (STDOUT, ':encoding(latin-1)') or die;

  binmode (STDOUT, ':via(MyLowlevel)') or die;

  print "x\n";
  # print $out "x";
  # $out->flush;
  exit 0;
}

{
  #open (my $out, '>', '/tmp/x') or die;
  my $out = \*STDOUT;

  $PerlIO::encoding::fallback = FB_PERLQQ;
  binmode ($out, ':encoding(latin-1)') or die;

  binmode ($out, ':via(MyLowlevel)') or die;

  print $out "x\n";
  # print $out "x";
  # $out->flush;
  close $out or die;
exit 0;
}


