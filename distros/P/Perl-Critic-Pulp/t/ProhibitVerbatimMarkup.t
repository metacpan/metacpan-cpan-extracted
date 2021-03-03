#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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
use Test::More tests => 20;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup;


#------------------------------------------------------------------------------
my $want_version = 99;
is ($Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
diag "Perl::Critic version ",Perl::Critic->VERSION;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitVerbatimMarkup');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  [ 0, "=begin comment\n\n    Some C<markup>" ],
                  [ 1, "=begin :comment\n\n    Some C<markup>" ],

                  [ 0, "=pod\n\n=for ProhibitVerbatimMarkup allow next\n\n    Some C<markup>" ],
                  [ 1, "=pod\n\n=for ProhibitVerbatimMarkup allow next\n\n    Some C<markup>\n\n    But not B<more>\n" ],

                  [ 0, "=pod\n\n=for ProhibitVerbatimMarkup allow next 2\n\n    Some C<markup>\n\nSome more C<markup>" ],
                  [ 1, "=pod\n\n=for ProhibitVerbatimMarkup allow next 2\n\n    Some C<markup>\n\nSome more C<markup>\n\n    But not B<a third>\n" ],


                  [ 1, "=pod\n\n    Some C<markup>" ],
                  [ 1, "=pod\n\n    E<gt>" ],
                  [ 1, "=pod\n\n    J<< something >>" ],
                  [ 1, "=pod\n\n    I<italic>" ],
                  [ 1, "=pod\n\n    bold\n\n    B<bold>" ],

                  [ 0, "\n## no critic (ProhibitVerbatimMarkup)\n\n=pod\n\n    bold\n\n    B<bold>\n\n=cut\n\nprint 'pod not last thing'\n" ],

                  # annotations in Perl::Critic::Annotation only act past an
                  # __END__ in P::C 1.112
                  [ 0, "\n## no critic (ProhibitVerbatimMarkup)\n\n__END__\n\n=pod\n\n    bold\n\n    B<bold>\n\nBlah\n\n=cut\n\n# pod not last thing\n",
                    1.112 ],

                 ) {
  my ($want_count, $str, $pcver) = @$data;
  $str = "$str";

 SKIP: {
    if (defined $pcver && !eval{Perl::Critic->VERSION($pcver);1}) {
      skip "Perl-Critic before $pcver doesn't support \"no critic\" after __END__", 1;
      next;
    }

    my @violations = $critic->critique (\$str);

    my $got_count = scalar @violations;
    is ($got_count, $want_count, "str: '$str'");

    if ($got_count != $want_count) {
      foreach (@violations) {
        diag ($_->description);
      }
    }
  }
}

exit 0;
