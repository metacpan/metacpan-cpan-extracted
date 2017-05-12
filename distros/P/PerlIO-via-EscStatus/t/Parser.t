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

use strict;
use warnings;
use Test::More tests => 40;
use charnames ':full';

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use PerlIO::via::EscStatus::Parser;

my $want_version = 11;
is ($PerlIO::via::EscStatus::Parser::VERSION, $want_version,
    'VERSION variable');
is (PerlIO::via::EscStatus::Parser->VERSION,  $want_version,
    'VERSION class method');
ok (eval { PerlIO::via::EscStatus::Parser->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval { PerlIO::via::EscStatus::Parser->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}


require PerlIO::via::EscStatus;
my $ESS = PerlIO::via::EscStatus::ESCSTATUS_STR();
my $EPART = PerlIO::via::EscStatus::Parser::ESCSTATUS_STR_PARTIAL_REGEXP();

## no critic (ProhibitEscapedCharacters)

{ my $str = 'abc';
  ok ($str !~ $EPART);
}
{ my $str = "\e";
  ok ($str =~ $EPART);
  is ($-[0], 0);
}
{ my $str = "abc\e_";
  ok ($str =~ $EPART);
  is ($-[0], 3);
}
{ require PerlIO::via::EscStatus;
  my $str = $ESS;
  ok ($str =~ $EPART);
  is ($-[0], 0);
}
{ require PerlIO::via::EscStatus;
  my $str = 'ab' . $ESS;
  ok ($str =~ $EPART);
  is ($-[0], 2);
}

{
  my $parser = PerlIO::via::EscStatus::Parser->new;

  { my ($status, $ordinary) = $parser->parse ("abc\n");
    is ($status, undef);
    is ($ordinary, "abc\n");
  }

  require PerlIO::via::EscStatus;
  { my ($status, $ordinary) = $parser->parse
      ($ESS . "abc\n");
    is ($status, "abc");
    is ($ordinary, "");
  }
  { my ($status, $ordinary) = $parser->parse
      ($ESS. "ab");
    is ($status, undef);
    is ($ordinary, "");
  }
  { my ($status, $ordinary) = $parser->parse ("cd\n");
    is ($status, "abcd");
    is ($ordinary, "");
  }
  { my ($status, $ordinary) = $parser->parse
      ($ESS ."abc\n" . $ESS ."def\n");
    is ($status, "def");
    is ($ordinary, "");
  }
  { my ($status, $ordinary) = $parser->parse
      ("1"
       . $ESS ."abc\n"
       . "2" . $ESS ."def\n"
       . "3");
    is ($status, "def");
    is ($ordinary, "123");
  }

  { my ($status, $ordinary) = $parser->parse ("x\e");
    ok (! defined $status);
    is ($ordinary, "x");

    ($status, $ordinary) = $parser->parse ("_");
    ok (! defined $status);
    is ($ordinary, "");

    ($status, $ordinary) = $parser->parse ("Z");
    ok (! defined $status);
    is ($ordinary, "\e_Z");
  }

  { my $str = "\x{263A}";
    my ($status, $ordinary) = $parser->parse ($str);
    ok (! defined $status);
    is ($ordinary, $str);
  SKIP: {
      if (! defined &utf8::is_utf8) { skip 'no utf8::is_utf8', 1; }
      is (utf8::is_utf8($ordinary), utf8::is_utf8($str));
    }
  }

  { my $smiley = "\x{263A}";
    my $str = $ESS . "$smiley\n";
    my ($status, $ordinary) = $parser->parse ($str);
    is ($status, $smiley);
    is ($ordinary, '');
  SKIP: {
      if (! defined &utf8::is_utf8) { skip 'no utf8::is_utf8', 1; }
      is (utf8::is_utf8($status), utf8::is_utf8($smiley));
    }
  }

  { my $quarter = "\N{VULGAR FRACTION ONE QUARTER}";
    my $str = $ESS . "$quarter\n";
    my ($status, $ordinary) = $parser->parse ($str);
    is ($status, $quarter);
    is ($ordinary, '');
  SKIP: {
      if (! defined &utf8::is_utf8) { skip 'no utf8::is_utf8', 1; }
      is (utf8::is_utf8($status), utf8::is_utf8($quarter));
    }
  }
}

exit 0;
