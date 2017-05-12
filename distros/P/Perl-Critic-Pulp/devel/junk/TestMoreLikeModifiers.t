#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

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


use strict;
use warnings;
use Perl::Critic::Policy::Compatibility::ProhibitTestMoreLikeModifiers;
use Test::More tests => 13;
use Perl::Critic;

my $single_policy = 'Compatibility::ProhibitTestMoreLikeModifiers';
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => $single_policy);
{ my @p = $critic->policies;
  is (scalar @p, 1,
     "single policy $single_policy");
}

ok ($Perl::Critic::Policy::Compatibility::ProhibitTestMoreLikeModifiers::VERSION >= 11,
    'VERSION variable');
ok (Perl::Critic::Policy::Compatibility::ProhibitTestMoreLikeModifiers->VERSION  >= 11,
    'VERSION method');

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 1, 'Test::More::like ($x, qr/y/i)' ],
                  [ 1, 'Test::More::like ($x, \'/y/i\')' ],
                  [ 1, 'Test::More::like ($x, "/y/i")' ],
                  [ 1, 'Test::More::like ($x, q{/y/i})' ],

                  [ 1, 'use Test::More; like ($x, \'/^y$/m\')' ],
                  [ 1, 'use Test::More; like ($x, "/^y$/m")' ],
                  [ 1, 'use Test::More; like ($x, qq{/^y$/m})' ],

                  [ 0, 'Test::More::like ($x, qr/y/)' ],
                  [ 0, 'Test::More::like ($x, "/y/")' ],
                  [ 0, 'Test::More::like ($x, qr/y/, "desc")' ],

                  ## use critic
                 ) {
  my ($want_count, $str) = @$data;

  my @violations = $critic->critique (\$str);
  foreach (@violations) {
    diag ($_->description);
  }
  my $got_count = scalar @violations;
  is ($got_count, $want_count, $str);
}

exit 0;
