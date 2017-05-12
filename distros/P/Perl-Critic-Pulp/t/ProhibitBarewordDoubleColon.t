#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
use Test::More tests => 31;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon;

#-----------------------------------------------------------------------------
my $want_version = 93;
is ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon$');

{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitBarewordDoubleColon');

  my $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

my $policy = ($critic->policies)[0];

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 1, 'my $x = Foo::' ],
                  [ 1, 'my $x = Foo::Bar::' ],
                  [ 0, 'my $x = FooBar' ],
                  [ 0, 'my $x = Foo::Bar' ],

                  [ 0, 'my $x = "Foo::"' ],
                  [ 0, 'my $x = \'Foo::\'' ],

                  # barewords in hash keys are subject to the same rules
                  [ 1, '$x{Foo::}' ],

                  # indirect calls
                  [ 0, 'new Foo::', {_allow_indirect_syntax => 1} ],
                  [ 1, 'new Foo::', {_allow_indirect_syntax => 0} ],
                  [ 0, 'new Foo:: 1,2,3', {_allow_indirect_syntax => 1} ],
                  [ 1, 'new Foo:: 1,2,3', {_allow_indirect_syntax => 0} ],

                  [ 1, 'my $x = Foo::',      {_allow_indirect_syntax => 1} ],
                  [ 0, 'my $x = Foo',        {_allow_indirect_syntax => 1} ],
                  [ 1, 'my $x = Foo::Bar::', {_allow_indirect_syntax => 1} ],
                  [ 0, 'my $x = Foo::Bar',   {_allow_indirect_syntax => 1} ],

                  [ 1, 'Foo::', ],
                  [ 0, 'Foo',   ],
                  [ 1, 'Foo::', {_allow_indirect_syntax => 1} ],
                  [ 0, 'Foo',   {_allow_indirect_syntax => 1} ],

                  [ 1, 'return Foo::', ],
                  [ 0, 'return Foo',   ],
                  [ 1, 'return Foo::', {_allow_indirect_syntax => 1} ],
                  [ 0, 'return Foo',   {_allow_indirect_syntax => 1} ],

                  ## use critic
                 ) {
  my ($want_count, $str, $options) = @$data;
  $policy->{'_allow_indirect_syntax'} = 0; # default

  my $name = "str: '$str'";
  foreach my $key (keys %$options) {
    $name .= " $key=$options->{$key}";
    $policy->{$key} = $options->{$key};
  }

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  is ($got_count, $want_count, $name);

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;
