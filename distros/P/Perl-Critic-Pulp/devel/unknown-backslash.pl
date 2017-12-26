#!/usr/bin/perl -w

# Copyright 2009, 2010, 2017 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use warnings;

# uncomment this to run the ### lines
use Smart::Comments;

{
  require PPI::Tokenizer;
  foreach my $c (0 .. 127) {
    my $str = chr($c);

    # $str =~ s/[^[:print:]\t\n\v\f\r]/ /g;

    my $tokenizer = PPI::Tokenizer->new(\$str);
    my $ok = eval { $tokenizer->get_token; 1 };
    my $error = $@;
    if (! $ok) {
      print "$c   ",ref $error,"\n";
    }
  }
  exit 0;
}

{
  require Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash;
  my $str = "\$who is a \N{SMILE}\\n";

  require PPI::Tokenizer;
  my $tokenizer = PPI::Tokenizer->new(\$str);
  # Or we can use it as an iterator
  for (;;) {
    print "get_token\n";
    my $token;
    my $ok = eval { $token = $tokenizer->get_token; 1 };
    my $error = $@;
    ### error ref: ref $error
    ### $error
    ### $token
    if ($ok) {
      print "token: $token\n";
    } else {
      my $message = $error->message;
      print "message: $message\n";
      last;
    }
    # PPI::Exception
  }

  # my $tokens;
  # $tokens = $tokenizer->all_tokens;
  exit 0;


  require PPI::Document;
  my $doc = PPI::Document->new(\$str);
  print PPI::Document->errstr(\$str),"\n";
  exit 0;
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash::_pos_after_interpolate_variable($str);
  exit 0;
  ;
}
{
  # "\v";
  exit 0;
}

{
  require Encode;
  binmode STDOUT, ':utf8' or die;
  foreach my $s ('*', 'z',
                 chr(128),
                 chr(255),
                 Encode::decode('latin-1',chr(255)),
                 chr(0x1234),
                 chr(0x2022), # bullet
                 chr(0x2297), # circle times
                ) {
    my $q = quotemeta($s);
    print ord($s), " ", ($s eq $q ? "unchanged" : "changed"), " $s $q",
      " ",(utf8::is_utf8($s) ? "utf8" : "bytes"), "\n";
  }
  exit 0;
}
