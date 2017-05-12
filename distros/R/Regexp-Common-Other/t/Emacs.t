#!/usr/bin/perl -w

# Copyright 2012, 2014, 2015 Kevin Ryde

# This file is part of Regexp-Common-Other.
#
# Regexp-Common-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Regexp-Common-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Regexp-Common-Other.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;
plan tests => 896;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Regexp::Common 'no_defaults', 'Emacs';
use Regexp::Common 'no_defaults', 'RE_Emacs_autosave';

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
{
  my $want_version = 14;
  ok ($Regexp::Common::Emacs::VERSION, $want_version,
      'VERSION variable');
  ok (Regexp::Common::Emacs->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Regexp::Common::Emacs->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  { my $check_version = $want_version + 1000;
    ok (! eval { Regexp::Common::Emacs->VERSION($check_version); 1 },
        1,
        "VERSION class check $check_version");
  }
}

#------------------------------------------------------------------------------
# $RE{}

foreach my $elem (['foo.c',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],

                  # bare ~ is not a backup of anything
                  ['~',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],

                  ['.',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],
                  ['..',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],
                  ['...',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],

                  #-----------------------------------------
                  # single backup

                  ['foo.c~',
                   [ ['backup'],                1, 'foo.c'],
                   [ ['backup','-single'],      1, 'foo.c'],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 1, 'foo.c'],
                   [ ['skipfile'],              1 ],
                  ],

                  ['.~123~',
                   [ ['backup'],                1, '.~123' ],
                   [ ['backup','-single'],      1, '.~123' ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 1, '.~123' ],
                   [ ['skipfile'],              1 ],
                  ],

                  ['fo\no.c~',
                   [ ['backup'],                1, 'fo\no.c'],
                   [ ['backup','-single'],      1, 'fo\no.c'],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 1, 'fo\no.c'],
                   [ ['skipfile'],              1 ],
                  ],

                  #-----------------------------------------
                  # numbered backup

                  ['foo.c.~123~',
                   [ ['backup'],                1, 'foo.c', '123'],
                   [ ['backup','-single'],      1, 'foo.c.~123'],
                   [ ['backup','-numbered'],    1, 'foo.c', '123'],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              1 ],
                  ],
                  ['foo.c.~9~',
                   [ ['backup'],                1, 'foo.c', '9'],
                   [ ['backup','-single'],      1, 'foo.c.~9'],
                   [ ['backup','-numbered'],    1, 'foo.c', '9'],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              1 ],
                  ],

                  ['foo.c~123~',
                   [ ['backup'],                1, 'foo.c~123'],
                   [ ['backup','-single'],      1, 'foo.c~123'],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 1, 'foo.c~123'],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              1 ],
                  ],
                  ['foo.c.9~',
                   [ ['backup'],                1, 'foo.c.9'],
                   [ ['backup','-single'],      1, 'foo.c.9'],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 1, 'foo.c.9'],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              1 ],
                  ],
                  ['foo.cx~9~',
                   [ ['backup'],                1, 'foo.cx~9'],
                   [ ['backup','-single'],      1, 'foo.cx~9'],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 1, 'foo.cx~9'],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              1 ],
                  ],

                  #-----------------------------------------
                  # autosave

                  ['#foo.c#',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              1, 'foo.c' ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              1 ],
                  ],
                  ['#z#',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              1, 'z' ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              1 ],
                  ],
                  ['##',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],
                  ['#',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],
                  ['#foo.c',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],

                  #-----------------------------------------
                  # lockfile

                  ['.#foo.c',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              1, 'foo.c' ],
                   [ ['skipfile'],              1 ],
                  ],
                  ['.#z',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              1, 'z' ],
                   [ ['skipfile'],              1 ],
                  ],
                  ['.#',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],

                  ['.foo.c',
                   [ ['backup'],                0 ],
                   [ ['backup','-single'],      0 ],
                   [ ['backup','-numbered'],    0 ],
                   [ ['backup','-notnumbered'], 0 ],
                   [ ['autosave'],              0 ],
                   [ ['lockfile'],              0 ],
                   [ ['skipfile'],              0 ],
                  ],

                 ) {
  my ($filename, @forms) = @$elem;
  foreach my $form (@forms) {
    my ($keys, $want, @want_match) = @$form;
    unshift @want_match, $filename;

    my $re = $RE{Emacs};
    foreach my $key (@$keys) {
      $re = $re->{$key};
    }
    my $name = join(',',@$keys);
    ### $name
    ### re: "$re"

    {
      my $got = ($filename =~ /$re/ ? 1 : 0);
      ok ($got, $want, "$name (no keep) $filename");
    }
    {
      my $got = ($filename =~ /$re->{-keep}/ ? 1 : 0);
      my @got_match;
      if ($filename =~ /$re->{-keep}/) {
        $got = 1;
        @got_match = ($1, $2, $3, $4);
      } else {
        $got = 0;
      }
      ok ($got, $want, "$name -keep $filename");

      if (! $want) {
        @got_match = @want_match;
      }
      foreach my $i (0 .. 3) {
        if (! defined $got_match[$i]) { $got_match[$i] = '[undef]' }
        if (! defined $want_match[$i]) { $want_match[$i] = '[undef]' }
      }

      ok ($got_match[0], $want_match[0], "$name \$1, $filename");
      ok ($got_match[1], $want_match[1], "$name \$2, $filename");
      ok ($got_match[2], $want_match[2], "$name \$3, $filename");
      ok ($got_match[3], $want_match[3], "$name \$4, $filename");
    }
  }
}


#------------------------------------------------------------------------------
# RE_Emacs_autosave()

{
  ok (('#foo.c#' =~ RE_Emacs_autosave() ? 1 : 0),
      1);
  ok (('#foo.c' =~ RE_Emacs_autosave() ? 1 : 0),
      0);
  ok (('.#foo.c' =~ RE_Emacs_autosave() ? 1 : 0),
      0);
  ok (('foo.c#' =~ RE_Emacs_autosave() ? 1 : 0),
      0);
}

#------------------------------------------------------------------------------

exit 0;
