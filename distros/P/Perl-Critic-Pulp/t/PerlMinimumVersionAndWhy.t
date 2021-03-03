#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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


# Tests with or without Perl::MinimumVersion available.


use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy;


#------------------------------------------------------------------------------
{
  my $want_version = 99;
  is ($Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy::VERSION,
      $want_version, 'VERSION variable');
  is (Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy->VERSION,
      $want_version, 'VERSION class method');

  ok (eval { Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
my $critic;
eval {
  $critic = Perl::Critic->new
    ('-profile' => '',
     '-single-policy' => '^Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy$',
    );
  1;
} or diag "cannot create Critic object -- $@";

SKIP: {
  $critic
    or skip 'no Critic object created', 1;

  my @policies = $critic->policies;
  ### got policy count: scalar(@policies)
  is (scalar(@policies), 1, '1 policy');
}

exit 0;
