#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Test::More tests => 43;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref;


#-----------------------------------------------------------------------------
my $want_version = 97;
is ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitArrayAssignAref');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 1, '@a = [1,2]', 'Array' ],
                  [ 1, '@a = []',    'Array' ],
                  [ 0, '@a = (1,2)' ],

                  [ 1, '@$r = [1,2]', 'Array' ],
                  [ 0, '@$r = ([1,2])' ],
                  [ 1, '@{$r} = [1,2]', 'Array' ],
                  [ 0, '@{$r} = ([1,2])' ],

                  [ 1, '@a[1,2] = [1,2]', 'Array slice' ],
                  [ 0, '@a[1,2] = ()' ],

                  [ 1, '@a{"x","y"} = [1,2]', 'Hash slice' ],
                  [ 1, '@a{"x","y"} = []',    'Hash slice' ],
                  [ 0, '@a{"x","y"} = ()' ],

                  [ 1, '@{foo()}[1,2] = [1,2]',    'Array slice' ],
                  [ 1, '@{$r=foo()}[1,2] = [1,2]', 'Array slice' ],
                  [ 0, '@{foo()}[1,2] = (1,2)' ],

                  [ 1, '@{foo()}{"a","b"} = [1,2]',    'Hash slice' ],
                  [ 1, '@{$r=foo()}{"a","b"} = [1,2]', 'Hash slice' ],
                  [ 0, '@{foo()}{"a","b"} = (1,2)' ],

                  ## use critic
                 ) {
  my ($want_count, $str, $thing) = @$data;

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: $str");

  my $violation = $violations[0];
  my $description = $violation && $violation->description;
  if (! defined $thing) { $thing = 'Array'; }
  ok (! defined $description || $description =~ /^$thing assigned/,
      "str: $str\ndescription: "
      .(defined $description ? $description : 'undef'));


  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;
