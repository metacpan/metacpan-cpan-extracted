#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Test::More tests => 36;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots;


#------------------------------------------------------------------------------
my $want_version = 96;
is ($Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
diag "Perl::Critic version ",Perl::Critic->VERSION;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitParagraphTwoDots');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  [ 0, "=pod\n\n=begin comment\n\n..\n" ],
                  [ 1, "=pod\n\n=begin :man\n\n..\n" ],

                  [ 1, "=pod\n\n..\n" ],
                  [ 1, "=pod\n\nX..\n" ],
                  [ 0, "=pod\n\n...\n" ],

                  [ 0, "=pod\n\n:-(.\n" ],
                  [ 0, "=pod\n\n:-).\n" ],
                  [ 0, "=pod\n\nsome_code();.\n" ],

                  [ 0, "=pod\n\nA paragraph\n" ],
                  [ 0, "=pod\n\nA paragraph.\n" ],
                  [ 1, "=pod\n\nA paragraph..\n" ],
                  [ 0, "=pod\n\nA paragraph...\n" ],

                  [ 1, "=pod\n\nA S<paragraph..>\n" ],
                  [ 1, "=pod\n\nA I<paragraph..>\n" ],
                  [ 1, "=pod\n\nA B<paragraph.>.\n" ],
                  [ 0, "=pod\n\nA Some thing.X<index..>\n" ],

                  [ 0, "=head1 A heading\n" ],
                  [ 0, "=head1 A heading.\n" ],
                  [ 1, "=head1 A heading..\n" ],
                  [ 0, "=head1 A heading...\n" ],

                  [ 0, "=item An item\n" ],
                  [ 0, "=item An item.\n" ],
                  [ 1, "=item An item..\n" ],
                  [ 0, "=item An item...\n" ],

                  [ 0, "=pod\n\nA L<perlfunc>.\n" ],
                  [ 1, "=pod\n\nA L<blah..|perlfunc>\n" ],
                  [ 1, "=pod\n\nA L<blah.|perlfunc>.\n" ],

                  [ 0, "=pod\n\nMiddle .. of paragraph.\n" ],

                  [ 2, "=pod\n\nA paragraph..\n\nSecond paragraph..\n" ],
                 ) {
  my ($want_count, $str) = @$data;
  $str = "$str";

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: '$str'");

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ("violation: ", $_->description,
            "\nline_number=", $_->line_number);
    }
  }
}

exit 0;
