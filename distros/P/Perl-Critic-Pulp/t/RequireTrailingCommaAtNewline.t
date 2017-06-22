#!/usr/bin/perl

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
use Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline;
use Test::More tests => 52;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }


#-----------------------------------------------------------------------------
my $want_version = 94;
is ($Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline->VERSION($check_version); 1 }, "VERSION class check $check_version");
}


#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'CodeLayout::RequireTrailingCommaAtNewline');
my $policy;
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy RequireTrailingCommaAtNewline');

  $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 0, 'foo()' ],
                  [ 0, '$obj->foo()' ],
                  [ 0, '@array=()' ],
                  [ 0, 'return()' ],

                  [ 1, '
foo(<<HERE,
some text
HERE
   <<HERE
some text
HERE
   );' ],

                  [ 1, '
@a =(<<HERE
some text
HERE
   ,
   <<HERE
some text
HERE
   );' ],

                  [ 0, '
foo($str . <<HERE
some text
HERE
   );' ],
                  [ 0, '
foo($str . <<HERE);
some text
HERE' ],

                  [ 0, '
@array = (<<HERE
some text
HERE
);' ],
                  [ 0, '
@array = (<<HERE);
some text
HERE' ],

                  [ 1, 'return (123,
                                456
                                );' ],
                  [ 0, 'return (123
                                );' ],

                  [ 0, '@foo = (     # empty
                               )' ],

                  [ 0, '$foo = (1
                               )' ],
                  [ 0, '$foo[1] = (1
                                   )' ],
                  [ 0, '$foo{a} = (1
                                   )' ],
                  [ 1, '@foo = (1
                               )' ],
                  [ 1, '@foo[1,2] = (1  # array slice
                                    )' ],
                  [ 1, '@foo{a,b} = (1  # hash slice
                                    )' ],
                  [ 1, '@$foo = (1
                                )' ],
                  [ 1, '@{$foo} = (1
                                   )' ],


                  [ 1, '@array = (1
                            )', _except_function_calls => 1 ],


                  # function calls
                  [ 1, 'foo(1
                            )' ],
                  [ 1, 'foo(1
                            )', _except_function_calls => 0 ],
                  [ 0, 'foo(1
                            )', _except_function_calls => 1 ],

                  # method calls
                  [ 0, '$obj->foo(1,
                                  )' ],
                  [ 1, '$obj->foo(1
                                  )' ],
                  [ 0, '$obj->foo(1
                                  )', _except_function_calls => 1 ],
                  [ 0, '$obj->foo(1,
                                  2,
                                  )' ],
                  [ 1, '$obj->foo(1,
                                  2
                                  )' ],
                  [ 0, '$obj->foo(1,
                                  2
                                  )', _except_function_calls => 1 ],


                  [ 1, '@array = (1,2
                                 )' ],
                  [ 1, '@array = (1,2,3
                                 )' ],
                  [ 0, '@array = (1,2,3)' ],
                  [ 0, '@array = (1,2,3,)' ],
                  [ 0, '@array = (1,2,3,
                                 )' ],
                  [ 0, '@array = (1=>2,
                                 )' ],
                  [ 1, '@array = (1=>2
                                 )' ],

                  [ 0, '$hashref = {1,2,3,4}' ],
                  [ 0, '$hashref = {1,2,3,4,}' ],
                  [ 0, '$hashref = {1,2,3,4,
                                 }' ],
                  [ 1, '$hashref = {1,2,3,4
                                 }' ],
                  [ 0, '$hashref = {1=>2,
                                 }' ],
                  [ 1, '$hashref = {1=>2
                                 }' ],

                  ## use critic
                 ) {
  my ($want_count, $str, @options) = @$data;

  delete $policy->{'_except_function_calls'};
  %$policy = (%$policy, @options);

  my @violations = $critic->critique (\$str);
  my $got_count = scalar @violations;

  my $name = "str: $str";
  if (@options) {
    $name .= "\n" . join('=>',@options);
  }
  is ($got_count, $want_count, $name);

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;
