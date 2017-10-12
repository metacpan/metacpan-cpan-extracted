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
use Test::More tests => 26;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Compatibility::PodMinimumVersion;


#------------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::Compatibility::PodMinimumVersion::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Compatibility::PodMinimumVersion->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Compatibility::PodMinimumVersion->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Compatibility::PodMinimumVersion->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Compatibility::PodMinimumVersion$');
my $policy;
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy PodMinimumVersion');

  $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

require version;
foreach my $data (
                  [ 2, "=pod\n\nC<< foo >>\n\n=for something\n", undef ],

                  [ 1, "=pod\n\nC<< foo >>" ],

                  [ 0, "=pod\n\nC<foo>" ],
                  [ 0, "=pod\n\nS<C<foo>C<bar>>" ],
                  [ 1, "=pod\n\nL< C<< foo >> >" ],
                  [ 1, "=pod\n\nL<foo|bar>" ],

                  [ 1, "use 5.004;\n\n=pod\n\nL<foo|bar>" ],
                  [ 0, "use 5.005;\n\n=pod\n\nL<foo|bar>" ],

                  [ 1, "=pod\n\nL<foo|bar>", version->new('5.004') ],
                  [ 0, "=pod\n\nL<foo|bar>", version->new('5.005') ],

                  [ 1, "use 5.004;\n\n=pod\n\nL<foo|bar>",
                    version->new('5.004') ],
                  [ 0, "use 5.004;\n\n=pod\n\nL<foo|bar>",
                    version->new('5.005') ],
                  [ 0, "use 5.005;\n\n=pod\n\nL<foo|bar>",
                    version->new('5.004') ],
                  [ 0, "use 5.005;\n\n=pod\n\nL<foo|bar>",
                    version->new('5.005') ],

                  [ 1, "=encoding utf-8" ],
                  [ 1, "=encoding utf-8\n\nuse 5.010;" ],
                  [ 0, "use 5.010;\n\n=encoding utf-8\n" ],
                  [ 1, "=encoding utf-8\n", version->new('5.8.9') ],
                  [ 0, "=encoding utf-8\n", version->new('5.10.0') ],

                 ) {
  my ($want_count, $str, $above_version, $want_minimum_version) = @$data;
  $str = "$str";
  local $policy->{'_above_version'} = $above_version;

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  my $name = "str: $str\nwith above_version "
    . (defined $above_version ? $above_version : '[undef]');
  is ($got_count, $want_count, $name);

  if (defined $want_minimum_version) {
    my $v = $violations[0];
    if (defined $v) { $v = $v->description; } else { $v = ''; }
    like ($v, /\Q$want_minimum_version/, "want_minimum_version");
  }

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;
