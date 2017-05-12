#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015 Kevin Ryde

# This file is part of Regexp-Common-Other.
#
# Regexp-Common-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Regexp-Common-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Regexp-Common-Other.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;
plan tests => 976;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Regexp::Common 'no_defaults', 'ANSIescape';


#------------------------------------------------------------------------------
{
  my $want_version = 14;
  ok ($Regexp::Common::ANSIescape::VERSION, $want_version,
      'VERSION variable');
  ok (Regexp::Common::ANSIescape->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Regexp::Common::ANSIescape->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  { my $check_version = $want_version + 1000;
    ok (! eval { Regexp::Common::ANSIescape->VERSION($check_version); 1 },
        1,
        "VERSION class check $check_version");
  }
}

#------------------------------------------------------------------------------
## no critic (ProhibitEscapedCharacters)

{ my $count = 0;
  foreach my $i (0x40 .. 0x5F) {
    my $str = "\e".chr($i);
    if ($str =~ Regexp::Common::ANSIescape::C1_ALL_7BIT) {
      $count++;
    }
  }
  ok ($count, 31, 'C1_ALL_7BIT');
}
{ my $count = 0;
  foreach my $i (0x80 .. 0x9F) {
    my $str = chr($i);
    if ($str =~ Regexp::Common::ANSIescape::C1_ALL_8BIT) {
      $count++;
    }
  }
  ok ($count, 31, 'C1_ALL_8BIT');
}
{ my $s_count = 0;
  my $n_count = 0;
  foreach my $i (0x40 .. 0x5F) {
    my $str = "\e".chr($i);
    my $s = ($str =~ Regexp::Common::ANSIescape::C1_STR_7BIT);
    my $n = ($str =~ Regexp::Common::ANSIescape::C1_NST_7BIT);
    ok (! ($s && $n),
        1,
        'C1_STR_7BIT and C1_NST_7BIT mutually exclusive');
    if ($s) { $s_count++; }
    if ($n) { $n_count++; }
  }
  ok ($s_count, 5,  'C1_STR_7BIT');
  ok ($n_count, 26, 'C1_NST_7BIT');
}
{ my $s_count = 0;
  my $n_count = 0;
  foreach my $i (0x80 .. 0x9F) {
    my $str = chr($i);
    my $s = ($str =~ Regexp::Common::ANSIescape::C1_STR_8BIT);
    my $n = ($str =~ Regexp::Common::ANSIescape::C1_NST_8BIT);
    ok (! ($s && $n),
        1,
        'C1_STR_8BIT and C1_NST_8BIT mutually exclusive');
    if ($s) { $s_count++; }
    if ($n) { $n_count++; }
  }
  ok ($s_count, 5,  'C1_STR_8BIT');
  ok ($n_count, 26, 'C1_NST_8BIT');
}

{ my $name = 'SGR';
  my $str = "zz\e[34mmm";
  ok ($str =~ $RE{ANSIescape}{-keep}, 1, "$name -- match");
  ok ($1, "\e[34m", "$name -- capture 1");
  ok ($2, "34", "$name -- capture 2");
  ok ($3, "m", "$name -- capture 3");
}
{ my $name = 'SGR with space flag';
  my $str = "zz\e[0 mzz";
  ok ($str =~ $RE{ANSIescape}{-keep}, 1, "$name -- match");
  ok ($1, "\e[0 m", "$name -- capture 1");
  ok ($2, "0", "$name -- capture 2");
  ok ($3, " m", "$name -- capture 3");
}
{ my $name = 'DECSCNM private param to SM';
  my $str = "zz\e[?5hzz";
  ok ($str =~ $RE{ANSIescape}{-keep}, 1, "$name -- match");
  ok ($1, "\e[?5h", "$name -- capture 1");
  ok ($2, "?5", "$name -- capture 2");
  ok ($3, "h", "$name -- capture 3");
}
{ my $name = 'SGR with crazy flags';
  my $str = "zz\e[1;2;3\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2A\x2B\x2C\x2D\x2E\x2F"."mmm";
  ok ($str =~ $RE{ANSIescape}{-keep}, 1, "$name -- match");
  ok ($1, "\e[1;2;3\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2A\x2B\x2C\x2D\x2E\x2F"."m", "$name -- capture 1");
  ok ($2, "1;2;3", "$name -- capture 2");
  ok ($3, "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2A\x2B\x2C\x2D\x2E\x2F"."m", "$name -- capture 3");
}
{ my $name = 'SGR with crazy parameter string';
  my $str = "zz\e[\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3A\x3B\x3C\x3D\x3E\x3F\x30"."mmm";
  ok ($str =~ $RE{ANSIescape}{-keep}, 1, "$name -- match");
  ok ($1, "\e[\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3A\x3B\x3C\x3D\x3E\x3F\x30"."m", "$name -- capture 1");
  ok ($2, "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3A\x3B\x3C\x3D\x3E\x3F\x30", "$name -- capture 2");
  ok ($3, "m", "$name -- capture 3");
}


my @seven = ("zz\e\@zz",    # C1
             "zz\e[34mmm",  # SGR
             "zz\e[0m\e\e", # SGR
             "zz\e[0 mzz",  # SGR with space flag
             "zz\e[0/mzz",  # SGR with / flag
             "zz\e\\aa",    # ST
            );
my @seven_with_string;
my @seven_without_string;

my @eight = ("zz\x80"."zz",    # C1
             "zz\x9B"."30maa", # SGR
             "zz\x9C"."aa",    # ST
            );
my @eight_with_string;
my @eight_without_string;

my @mixed_with_string = ();

# C1 forms taking a string: DCS,SOS,OSC,PM,APC
my @with_string = (0x50,0x58,0x5D,0x5E,0x5F);

# C1 forms not taking a string, and not SGR
my @without_string = do { my %without;
                          @without{0x40 .. 0x5F} = 1;
                          delete @without{@with_string, 0x5B};
                          sort keys %without;
                        };

foreach my $s (@with_string) {
  push @seven_with_string, "zz\e".chr($s)."STRI\nNG\e\\zz";
  push @eight_with_string, "zz".chr($s+0x40)."STRI\nNG\x9C"."zz";

  push @seven_without_string, "zz\e".chr($s)."zz";
  push @eight_without_string, "zz".chr($s+0x40)."zz";

  push @mixed_with_string, "zz\e]STRI\nNG\x9C"."zz";    # 7/8 mixed
  push @mixed_with_string, "zz\x9D"."STRI\nNG\e\\zz";   # 8/7 mixed
}
foreach my $s (@without_string) {
  push @seven, "zz\e".chr($s)."zz";
  push @eight, "zz".chr($s+0x40)."zz";
}


foreach my $elem ([$RE{ANSIescape}{-sepstring}{-only8bit}, 'sep8',
                   [ @eight, @eight_without_string ]],

                  [$RE{ANSIescape}{-sepstring}{-only7bit}, 'sep7',
                   [ @seven, @seven_without_string ]],

                  [$RE{ANSIescape}{-sepstring}, 'sep7+8',
                   [ @seven, @seven_without_string,
                     @eight, @eight_without_string ]],

                  [$RE{ANSIescape}, '7+8',
                   [ @seven, @seven_with_string,
                     @eight, @eight_with_string,
                     @mixed_with_string ]],

                  [$RE{ANSIescape}{-only7bit}, 'only7',
                   [ @seven, @seven_with_string ]],

                  [$RE{ANSIescape}{-only8bit}, 'only8',
                   [ @eight, @eight_with_string ]]) {

  my ($re, $name, $strs) = @$elem;
  require Data::Dumper;
  # diag "$re";

  foreach my $str (@$strs) {
    my $printstr = Data::Dumper->new([$str],['str'])->Useqq(1)->Dump;
    $printstr =~ s/\n+$//; # no trailing newlines in test name

    my $got_count = ($str =~ /$re/g);
    my $got_match = $&;
    my $got_before = $`;
    my $got_after = $';
    my $got_startpos = length($got_before);
    my $got_endpos = length($str) - length($got_after);

    ok ($got_count, 1,          "$name matches $printstr");
    ok (length($got_before), 2, "$name begin pos of $printstr");
    ok (length($got_after),  2, "$name end pos of $printstr");
  }
}

exit 0;
