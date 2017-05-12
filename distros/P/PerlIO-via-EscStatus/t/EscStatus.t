#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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
use PerlIO::via::EscStatus;
use Test::More tests => 860;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

my $want_version = 11;
is ($PerlIO::via::EscStatus::VERSION, $want_version,
    'VERSION variable');
is (PerlIO::via::EscStatus->VERSION,  $want_version,
    'VERSION class method');
ok (eval { PerlIO::via::EscStatus->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval { PerlIO::via::EscStatus->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

## no critic (ProtectPrivateSubs)


sub printable {
  my ($str) = @_;
  $str =~ s{([^[:ascii:]])}
           {sprintf('\\x{%02X}',ord($1))}ge;
  return $str;
}

#------------------------------------------------------------------------------
# IsZero

## no critic (ProhibitEscapedCharacters)
my $_81_str = "\x{81}";
my $_9B_str = "\x{9B}";
my $_9F_str = "\x{9F}";
my $AD_str  = "\x{AD}";

diag 'IsZero';
ok ("\a"       =~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ("\r"       =~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ("\t"       !~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ("\e"       !~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ("X"        !~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ($_81_str   !~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ($_9B_str   !~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ($_9F_str   !~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ($AD_str    !~ /\p{PerlIO::via::EscStatus::IsZero}/);
ok ("\x{0300}" =~ /\p{PerlIO::via::EscStatus::IsZero}/); # Mn
ok ("\x{0488}" =~ /\p{PerlIO::via::EscStatus::IsZero}/); # Me
ok ("\x{1100}" !~ /\p{PerlIO::via::EscStatus::IsZero}/); # W
ok ("\x{FF10}" !~ /\p{PerlIO::via::EscStatus::IsZero}/); # F
ok ("\x{FEFF}" =~ /\p{PerlIO::via::EscStatus::IsZero}/); # BOM


#------------------------------------------------------------------------------
# IsDouble

diag 'IsDouble';
ok ("\a"       !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ("\r"       !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ("\t"       !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ("\e"       !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ("X"        !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ($AD_str    !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ($_81_str   !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ($_9B_str   !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ($_9F_str   !~ /\p{PerlIO::via::EscStatus::IsDouble}/);
ok ("\x{0300}" !~ /\p{PerlIO::via::EscStatus::IsDouble}/); # Mn
ok ("\x{0488}" !~ /\p{PerlIO::via::EscStatus::IsDouble}/); # Me
ok ("\x{1100}" =~ /\p{PerlIO::via::EscStatus::IsDouble}/); # W
ok ("\x{FF10}" =~ /\p{PerlIO::via::EscStatus::IsDouble}/); # F
ok ("\x{FEFF}" !~ /\p{PerlIO::via::EscStatus::IsDouble}/); # BOM


#------------------------------------------------------------------------------
# IsOther

diag 'IsOther';
ok ("\a"       !~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ("\r"       !~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ("\t"       !~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ("\e"       !~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ("X"        =~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ($AD_str    =~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ($_81_str   !~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ($_9B_str   !~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ($_9F_str   !~ /\p{PerlIO::via::EscStatus::IsOther}/);
ok ("\x{0300}" !~ /\p{PerlIO::via::EscStatus::IsOther}/); # Mn
ok ("\x{0488}" !~ /\p{PerlIO::via::EscStatus::IsOther}/); # Me
ok ("\x{1100}" !~ /\p{PerlIO::via::EscStatus::IsOther}/); # W
ok ("\x{FF10}" !~ /\p{PerlIO::via::EscStatus::IsOther}/); # F
ok ("\x{FEFF}" !~ /\p{PerlIO::via::EscStatus::IsOther}/); # BOM


#------------------------------------------------------------------------------
# _truncate

diag '_truncate';

foreach my $elem (
                  # singles
                  ["", 0, "", 0 ],
                  ["xyz", 0, "", 0 ],

                  ["x", 1, "x", 1 ],
                  ["xy", 2, "xy", 2 ],
                  ["xyz", 3, "xyz", 3 ],
                  ["xyz", 4, "xyz", 3 ],

                  # doubles
                  ["\x{1101}\x{1102}\x{1103}\x{1104}", 5,
                   "\x{1101}\x{1102}", 4 ],

                  ["\x{1101}\x{1102}\x{1103}\x{1104}\r", 8,
                   "\x{1101}\x{1102}\x{1103}\x{1104}\r", 8 ],

                  # tabs
                  [ "\tAB\a", 9, "\tA", 9 ],
                  [ "ZZ\tAB\a", 9, "ZZ\tA", 9 ],

                 ) {
  my ($str, $cols_limit, $want_trunc, $want_cols) = @$elem;

  my ($got_trunc, $got_cols) = PerlIO::via::EscStatus::_truncate
    ($str, $cols_limit);

  my $name = "on limit $cols_limit str ".printable($str);
  is ($got_trunc, $want_trunc, "string $name");
  is ($got_cols,  $want_cols,  "cols $name");
}

# ANSI
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("\e[34mfoo\e[0m", 3);
  is ($trunc, "\e[34mfoo\e[0m");
  is ($cols, 3);
}
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("\e[34mfoobar\e[0m", 3);
  is ($trunc, "\e[34mfoo\e[0m");
  is ($cols, 3);
}
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("\x{9B}35mfoobar\x{9B}30m", 3);
  is ($trunc, "\x{9B}35mfoo\x{9B}30m");
  is ($cols, 3);
}
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("\e[34m\e[0mfoobar", 3);
  is ($trunc, "\e[34m\e[0mfoo");
  is ($cols, 3);
}

# non-ANSI Esc, counted as width one
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("\eXYZ", 3);
  is ($trunc, "\eXY");
  is ($cols, 3);
}

# mixture
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("\x{1100}", 1);
  is ($trunc, "");
  is ($cols, 0);
}
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("\x{1100}", 2);
  is ($trunc, "\x{1100}");
  is ($cols, 2);
}
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("Z\x{1100}", 2);
  is ($trunc, "Z");
  is ($cols, 1);
}
{ my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ("Z\a", 1);
  is ($trunc, "Z\a");
  is ($cols, 1);
}
{ my $str = ("\x{FF10}\x{FF11}\x{FF12}\x{FF13}\x{FF14}"
             . "\x{FF15}\x{FF16}\x{FF17}\x{FF18}\x{FF19}") x 20;
  my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ($str, 79);
  is ($trunc, substr($str,0,39));
  is ($cols, 78);
}

require Unicode::Normalize;
foreach my $i (0x20 .. 0x7F, 0xA0 .. 0xFF) {
  my $str = chr($i); # byte, without utf8 flag
  {
    my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ($str, 1);
    is ($trunc, $str, "char $i passes");
    is ($cols, 1, "char $i col width 1");
  }
  $str = Unicode::Normalize::normalize('D',$str);
  {
    my $len = length($str);
    my ($trunc, $cols) = PerlIO::via::EscStatus::_truncate ($str, 1);
    is ($trunc, $str, "D normalized char $i passes (len $len)");
    is ($cols, 1, "D normalized char $i col width 1");
  }
}

#------------------------------------------------------------------------------
# FLUSH propagation

{
  package PerlIO::via::MyLowlevel;

  sub PUSHED {
    my ($class, $mode, $fh) = @_;
    return bless {}, $class;
  }

    my $saw_flush = 0;
    sub saw_flush { return $saw_flush; }
    sub reset_saw { $saw_flush = 0; }

    sub FLUSH {
      my ($self, $fh) = @_;
      # print STDERR "MyLowlevel: FLUSH\n";
      $saw_flush = 1;
      return 0; # success
    }

    sub WRITE {
      my ($self, $buf, $fh) = @_;
      # print STDERR "MyLowlevel: WRITE ",length($buf),"\n";
      return length ($buf);
    }
  }

diag 'flush';

require File::Spec;
my $devnull = File::Spec->devnull;

# the first two here just to make sure the test framework is doing what it
# should
{
  open (my $out, '> :via(MyLowlevel)', $devnull) or die;

  require IO::Handle;
  PerlIO::via::MyLowlevel::reset_saw();
  $out->flush;
  is (PerlIO::via::MyLowlevel::saw_flush(),
      1,
      'bare MyLowlevel sees flush() call');
  close $out or die;
}
{
  diag "with encoding";
  open (my $out, '> :via(MyLowlevel) :encoding(latin-1)', $devnull) or die;

  print $out "x";
  PerlIO::via::MyLowlevel::reset_saw();
  $out->flush;
  is (PerlIO::via::MyLowlevel::saw_flush(),
      1,
      'with encoding on top see flush() call');

  close $out or die;
}
{
  diag "with ttystatus";
  open (my $out, '> :via(MyLowlevel) :via(EscStatus)', $devnull) or die;

  print $out "x";
  PerlIO::via::MyLowlevel::reset_saw();
  $out->flush;
  is (PerlIO::via::MyLowlevel::saw_flush(),
      1,
      'with EscStatus on top see flush() call');
  close $out or die;
}


#------------------------------------------------------------------------------
# _term_width fd use

# return the next available file descriptor number, ie. the one which would
# be used by the next open() etc
sub next_fd {
  require POSIX;
  my $next_fd = POSIX::dup(0);
  POSIX::close ($next_fd);
  return $next_fd;
}

diag('_term_width');
foreach my $fh (\*STDOUT, \*STDERR) {
  my $fd1 = next_fd();
  PerlIO::via::EscStatus::_term_width ($fh);
  my $fd2 = next_fd();
  is ($fd1, $fd2,
     '_term_width leaves next_fd() unchanged');
}

#------------------------------------------------------------------------------
# close

# only testing that close succeeds (the sublayers are already closed)
diag('close clearing');
{
  open my $out, '>', $devnull or die;
  binmode ($out, ':via(EscStatus)') or die;
  print $out PerlIO::via::EscStatus::make_status('hello');
  ok (close $out,
      'close() with status showing');
}

diag('done');
exit 0;
