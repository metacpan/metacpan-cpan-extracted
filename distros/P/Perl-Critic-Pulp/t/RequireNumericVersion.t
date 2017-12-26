#!/usr/bin/perl

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Test::More tests => 33;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion;

#-----------------------------------------------------------------------------
my $want_version = 96;
is ($Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion::VERSION,
    $want_version,
    'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion->VERSION,
    $want_version,
    'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ValuesAndExpressions::RequireNumericVersion');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy RequireNumericVersion');

  my $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 1, 'package Foo; our $VERSION = qq{1e6}' ],
                  [ 1, 'package Foo; use 5.008; $VERSION = qq{1e6}' ],
                  [ 1, 'package Foo; use 5.010; $VERSION = qq{1e6}' ],

                  [ 0, 'package Foo::Bar;
                        $VERSION = "1.002_003";
                        $VERSION = eval $VERSION' ],
                  [ 1, 'package Foo::Bar;
                        $VERSION = "1.002_003";
                        package Elsewhere;
                        $VERSION = eval $VERSION' ],
                  [ 1, 'package Foo::Bar;
                        $VERSION = "1.002_003";
                        $VERSION = eval "something else"' ],
                  [ 1, 'package Foo::Bar;
                        $VERSION = "1.002_003";
                        $VERSION = $VERSION' ],

                  [ 0, 'package Foo::Bar;
                        $Foo::Bar::VERSION = "1.002_003";
                        $VERSION = eval $VERSION' ],

                  [ 0, 'package Foo::Bar;
                        $Foo::Bar::VERSION = "1.002_003";
                        $Foo::Bar::VERSION = eval $Foo::Bar::VERSION' ],

                  [ 0, '$main::VERSION = "abc"' ],
                  [ 0, '$::VERSION = "abc"' ],
                  [ 1, '$Foo::Bar::VERSION = "abc"' ],

                  [ 0, 'package Foo; $VERSION = 1' ],
                  [ 0, 'package Foo; $VERSION = 0.123456789' ],

                  [ 1, 'package Foo; $VERSION = "1.2alpha"' ],
                  [ 0, '              $VERSION = "1.2alpha"' ],
                  [ 0, 'package main; $VERSION = "1.2alpha"' ],
                  [ 1, 'package Foo; use 5.008; $VERSION = "1.2alpha"' ],
                  [ 1, 'package Foo; use 5.010; $VERSION = "1.2alpha"' ],

                  [ 1, 'package Foo; our $VERSION = "1.123_456"' ],
                  [ 1, 'package Foo; use 5.008; $VERSION = "1.123_456"' ],
                  [ 0, 'package Foo; use 5.010; $VERSION = "1.123_456"' ],

                  [ 1, 'package Foo; our $VERSION = q{1.123.456}' ],
                  [ 1, 'package Foo; use 5.008; $VERSION = q{1.123.456}' ],
                  [ 0, 'package Foo; use 5.010; $VERSION = q{1.123.456}' ],

                  ## use critic
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

#-----------------------------------------------------------------------------
# version.pm

# Have seen version.pm 0.88 running its "vpp" form on perl 5.10 accept 1e6.
# Skip this test until decide whether that's good or bad or right or wrong.

{
  require version;
  diag "version.pm VERSION ", version->VERSION,
    "  \@ISA=", join(',',@version::ISA);
  diag "version::vxs VERSION ", version::vxs->VERSION;
  diag "version::vpp VERSION ", version::vpp->VERSION;

  my $warn;
  my $ret = eval {
    local $SIG{'__WARN__'} = sub { $warn = $_[0] };
    version->new('1e6')
  };
  my $err = $@;

  my $version_if_valid = Perl::Critic::Pulp::Utils::version_if_valid('1e6');

  # is ($version_if_valid, undef,
  #     'version.pm rejects 1e6, as claimed in RequireNumericVersion pod');

  if ($version_if_valid) {
    diag "version.pm on 1e6: ", $ret;
    diag "version.pm err: ",$err;
    diag "version.pm warn: ",$warn;
  }
}

exit 0;
