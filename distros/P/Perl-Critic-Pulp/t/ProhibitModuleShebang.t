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
use Test::More tests => 15;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;


require Perl::Critic::Policy::Modules::ProhibitModuleShebang;

#-----------------------------------------------------------------------------
my $want_version = 94;
is ($Perl::Critic::Policy::Modules::ProhibitModuleShebang::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Modules::ProhibitModuleShebang->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Modules::ProhibitModuleShebang->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Modules::ProhibitModuleShebang->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'Modules::ProhibitModuleShebang');
my $policy;
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitModuleShebang');

  $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#-----------------------------------------------------------------------------

foreach my $data ([ 1, 't/ProhibitModuleShebang/UsrBin.pm' ],
                  [ 1, 't/ProhibitModuleShebang/MakeMaker.pm' ],

                  [ 0, 't/ProhibitModuleShebang/False.pm',
                    _allow_bin_false => 1 ],
                  [ 1, 't/ProhibitModuleShebang/False.pm',
                    _allow_bin_false => 0 ],

                  [ 0, 't/ProhibitModuleShebang/SomeCode.pm' ],
                  [ 0, 't/ProhibitModuleShebang/SomeCodeNewline.pm' ],
                  [ 0, 't/ProhibitModuleShebang/Script.pl' ],

                  ## use critic
                 ) {
  my ($want_count, $filename, %parameters) = @$data;
  %$policy = (%$policy,
              _allow_bin_false => 1,
              %parameters);
  ### $filename
  -e $filename or die "Oops, missing $filename";

  my @violations = $critic->critique ($filename);
  my $got_count = scalar @violations;
  is ($got_count, $want_count, "filename: $filename\n_allow_bin_false=$policy->{'_allow_bin_false'}");

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

#-----------------------------------------------------------------------------
exit 0;
