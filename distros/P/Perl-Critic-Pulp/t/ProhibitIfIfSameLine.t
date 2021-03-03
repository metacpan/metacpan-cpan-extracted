#!/usr/bin/perl

# Copyright 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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
use Perl::Critic::Policy::CodeLayout::ProhibitIfIfSameLine;
use Test::More tests => 24;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }


#-----------------------------------------------------------------------------
my $want_version = 99;
is ($Perl::Critic::Policy::CodeLayout::ProhibitIfIfSameLine::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::CodeLayout::ProhibitIfIfSameLine->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::CodeLayout::ProhibitIfIfSameLine->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::CodeLayout::ProhibitIfIfSameLine->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'CodeLayout::ProhibitIfIfSameLine');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitIfIfSameLine');

  my $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  [ 0, "unless (1) { } unless (2) { }" ],




                  [ 1, "
if (1) {
} if (2) {
}
" ],
                  [ 1, "
if (1) {
} else {
} if (2) {
}" ],
                  [ 1, "unless (1) { } if (2) { }" ],

                  # secret undocumented allow semicolon as separator too
                  [ 0, "if (1) { } ; ; ; if (2) { }" ],

                  # doesn't apply when second statement is an "unless", only
                  # when it's an "if"
                  [ 0, "if (1) { } unless (2) { }" ],
                  [ 0, "unless (1) { } unless (2) { }" ],
                  [ 0, "do { } if (2);" ],

                  [ 0, "while (0) {} if (2) {}" ],
                  [ 0, "until (1) {} if (2) {}" ],
                  [ 0, "for (1) {} if (2) {}" ],
                  [ 0, "foreach (1) {} if (2) {}" ],

                  [ 0, "if (1) {} while (0) {}" ],
                  [ 0, "if (1) {} until (1) {}" ],
                  [ 0, "if (1) {} for (1) {}" ],
                  [ 0, "if (1) {} foreach (1) {}" ],
                 ) {
  my ($want_count, $str) = @$data;

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: $str");

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;
