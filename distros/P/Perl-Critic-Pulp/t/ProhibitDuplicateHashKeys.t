#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Test::More tests => 65;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys;

#-----------------------------------------------------------------------------
my $want_version = 94;
is ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys$');

{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitDuplicateHashKeys');

  my $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

my $policy = ($critic->policies)[0];

foreach my $data
  (## no critic (RequireInterpolationOfMetachars)

   [ 0, 'my %hash = (__LINE__.q{a}.q{b} => 1,
                     __LINE__.q{ab}     => 2);' ],
   [ 1, 'my %hash = (__LINE__ => 1, __LINE__ => 2);' ],
   [ 1, 'my %hash = (__LINE__ => 123,
                     1        => 456);' ],
   [ 1, '#line 123 "foo.pl"
         my %hash = (__LINE__ => 1, 123 => 2);' ],
   [ 0, '#line 123
         my %hash = (__LINE__ => 1, 124 => 2);' ],
   [ 0, '#
line 123
;
my %hash = (__LINE__ => 1, 124 => 2);' ],

   #------------------------------

   [ 1, 'my %hash = (__PACKAGE__.q{a}.q{b} => 1,
                     __PACKAGE__.q{ab}     => 2);' ],

   [ 1, 'my %hash = (__PACKAGE__ => 1,
                     main        => 2);' ],
   [ 0, 'my %hash = (__PACKAGE__ => 1,
                     xyzzy       => 2);' ],
   [ 1, 'package xyzzy;
         my %hash = (__PACKAGE__ => 1,
                     xyzzy       => 2);' ],
   [ 0, '{ package xyzzy; }
         my %hash = (__PACKAGE__ => 1,
                     xyzzy       => 2);' ],
   [ 0, 'package; # bogosity
         my %hash = (__PACKAGE__ => 1,
                     xyzzy       => 2);' ],
   [ 1, 'package; # bogosity
         my %hash = (__PACKAGE__ => 1,
                     main        => 2);' ],

   #------------------------------

   [ 1, 'my %hash = (__FILE__.q{a}.q{b} => 1,
                     __FILE__.q{ab}     => 2);' ],
   [ 1, '#line 1 "foo.pl"
         my %hash = (__FILE__ => 1,
                     "foo.pl" => 2);' ],
   [ 0, '#line 1 "foo.pl"
         my %hash = (__FILE__ => 1,
                     "bar.pl" => 2);' ],


   #------------------------------
   # from the pod
   [ 1, '
    my %hash = (blah()    => 1,  # guided by =>
                a         => 2,
                a         => 3); # bad
' ],
   [ 1, '
    my %hash = (blah(),
                a         => 2,
                a         => 3); # bad
' ],
   [ 1, '
    my %hash = (a => 1,
                %blah,       # recognised as even
                blah() => 1, # guided by =>
                a => 1);     # bad
' ],
   [ 1, '
    my %hash = (qw(foo 123
                   foo 123));  # bad
' ],
   [ 1, '
    my %hash = (a         => 1,
                %blah,            # recognised as even
                blah()    => 2,   # guided by =>
                $var      => 3,   # variables ignored
                "abc$var" => 3,   # variables ignored
                a         => 4); # bad, duplicate
' ],
   #------------------------------

   [ 0, 'map {; q{a},1, q{a},2 } 1 .. 2' ],
   [ 0, '@foo = map {; a => 1, a => 2 } 1 .. 2' ],
   [ 0, '$foo = map {; a => 1, a => 2 } 1 .. 2' ],

   [ 1, '%foo = (aa => 1, "a"."a" => 2)' ],
   [ 0, '%foo = (aa => 1, "a"."$a" => 2)' ],

   [ 0, '%foo = (a => 1, b => 2)' ],
   [ 0, '%foo = (a => 1, b => 2, )' ],
   [ 1, '%foo = (a => 1, a => 2)' ],
   [ 1, '%foo = (a => 1,, a => 2)' ],

   # FIXME: notice the value expression is not a function call etc,
   # [ 1, '%foo = (a => 1 => a => 2)' ],

   [ 1, '%foo = ("x" => 1, "x" => 2)' ],
   [ 1, '%foo = (x => 1, "x" => 2)' ],
   [ 1, '%foo = (x => 1, "x",2)' ],
   [ 1, '%foo = (\'x\' => 1, "x",2)' ],
   [ 1, '%foo = (q{x} => 1, x=>2)' ],
   [ 1, '%foo = (qq{x} => 1, x=>2)' ],

   [ 1, '%foo = (qw{x} => 1, x=>2)' ],
   [ 1, '%foo = (qw{x 1 x 2})' ],

   [ 1, '%$foo = { a => 1, a => 2 }' ],
   [ 1, '%$$foo = { a => 1, a => 2 }' ],
   [ 1, '%$$$foo = { a => 1, a => 2 }' ],
   [ 1, '%$$$$foo = { a => 1, a => 2 }' ],
   [ 1, '%$$$$$foo = { a => 1, a => 2 }' ],

   [ 0, '$foo = { }' ],
   [ 0, '$foo = { a => 1, }' ],
   [ 0, '$foo = { a => 1, b => 2 }' ],
   [ 1, '$foo = { a => 1, a => 2 }' ],

   [ 1, '$foo = \{ a => 1, a => 2 }' ],
   [ 1, '$foo = \ { a => 1, a => 2 }' ],
   [ 1, '$foo = \\{ a => 1, a => 2 }' ],
   [ 1, '$foo = \\\{ a => 1, a => 2 }' ],
   [ 1, '$foo = \\\\{ a => 1, a => 2 }' ],
   [ 1, '$foo = \ \ \ \ { a => 1, a => 2 }' ],

   [ 0, '%foo = (a => 1, b => 2, )' ],
   [ 1, '%foo = (a => 1, %zzz, a => 2)' ],
   [ 1, '%foo = (a => 1, %$zzz, a => 2)' ],
   [ 1, '%foo = (a => 1, %{$zzz}, a => 2)' ],

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
