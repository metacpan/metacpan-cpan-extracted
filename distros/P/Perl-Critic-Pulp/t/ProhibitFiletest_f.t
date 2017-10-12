#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Test::More tests => 19;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f;


#-----------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f->VERSION($check_version); 1 }, "VERSION class check $check_version");
}



#-----------------------------------------------------------------------------
# policy

{
  require Perl::Critic;
  my $critic = Perl::Critic->new
    ('-profile' => '',
     '-single-policy' => '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f$');
  { my @p = $critic->policies;
    is (scalar @p, 1, 'single policy ProhibitFiletest_f');

    my $policy = $p[0];
    ok (eval { $policy->VERSION($want_version); 1 },
        "VERSION object check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { $policy->VERSION($check_version); 1 },
        "VERSION object check $check_version");
  }

  foreach my $data
    ([ 1, 'if (-f FH) { print }' ],
     [ 0, 'if (-e FH) { print }' ],
     [ 1, '-f FH' ],
     [ 0, '-e FH' ],
     [ 1, '-f $fh' ],
     [ 0, '-e $fh' ],

    ) {
    my ($want_count, $str) = @$data;

    foreach my $str ($str, $str . ';') {
      my @violations = $critic->critique (\$str);

      # foreach my $violation (@violations) {
      #   diag $violation->description;
      # }

      my $got_count = scalar @violations;
      require Data::Dumper;
      my $testname = Data::Dumper->new([$str],['str'])->Useqq(1)->Dump;
      is ($got_count, $want_count, $testname);
    }
  }
}

exit 0;
