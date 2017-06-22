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
use Test::More tests => 116;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare;


#------------------------------------------------------------------------------
my $want_version = 94;
is ($Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare->VERSION($check_version); 1 }, "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
     'single policy NotWithCompare');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (## no critic (RequireInterpolationOfMetachars)
                  [ 0, '! foo' ],
                  [ 0, '$foo = ! $foo if $bar < 123' ],

                  # examples in the POD
                  [ 0, '!$x == !$y' ],
                  [ 0, '!$x != !$y' ],
                  [ 1, '! $x == $y   # bad' ],
                  [ 0, '!$x || $y || !$z   # ok' ],
                  [ 0, '(!$x) + 1 == $y   # ok' ],
                  [ 0, '(!$x)+1 == $y   # ok' ],
                  [ 1, '! $x+1 == $y    # not ok' ],
                  [ 1, '! time == 1' ],
                  [ 1, 'use constant FIVE => 5;
                        ! FIVE == 1' ],
                  [ 1, 'sub name () { "foo" }
                            ! name =~ /bar/' ],

                  [ 1, '! ($x ~= /x/) + 1 >= 0' ],
                  [ 0, '! $x + $y =~ /y/' ],  # "+" below "=~"
                  [ 1, '! $x ** $y =~ /y/' ], # "**" above "=~"
                  [ 0, '! $x && $y >= 123' ],
                  [ 0, '! $x xor $y >= 123' ],
                  [ 0, '! $x // $y >= 123' ],

                  [ 0, '! <STDIN>' ],
                  [ 0, 'if (! <STDIN>) { blah(); }' ],
                  [ 0, '! <STDIN> && ! <ALTIN>' ],

                  [ 0, '! print <STDIN>' ],
                  #
                  # very dodgy, but allowed on the basis of print being
                  # definitely a varargs
                  [ 0, '! print < STDIN' ],
                  #
                  [ 0, '! userfunc' ],
                  [ 0, '! userfunc <STDIN>' ],
                  [ 1, '! userfunc < CONST' ],
                  [ 0, '! &userfunc <STDIN>' ],
                  [ 0, '! &userfunc < STDIN' ], # eating all stuff

                  [ 0, '! userfunc <*.c>' ],
                  [ 0, '! userfunc *STDIN' ],
                  [ 0, '! &userfunc' ],
                  [ 0, '! &userfunc <*.c>' ],
                  [ 0, '! &userfunc *STDIN' ],
                  [ 1, '! &userfunc() == 1' ],
                  [ 1, '! &userfunc(123) == 1' ],

                  [ 1, '! \\$x == 123' ],
                  [ 1, '! \\ \\ $x == 123' ],
                  [ 1, '! \\ \\ \\ $x == 123' ],
                  [ 1, '! \\ &func == 123' ],
                  [ 1, '! \\ \\ &func == 123' ],
                  [ 1, '! \\ \\ \\ &func == 123' ],

                  [ 1, '! -$x == 1' ],
                  [ 1, '! +$x == 1' ],
                  [ 0, '-!$x == 1' ],
                  [ 0, '+!$x == 1' ],
                  [ 0, '! $x && $y' ],
                  [ 0, '! $x || -$y' ],
                  [ 0, '! $x and -$y' ],
                  [ 0, '! $x or -$y' ],
                  [ 0, '$x && ! $y' ],
                  [ 1, '$x && ! $y == 123' ],
                  [ 1, '$x || ! $y == 123' ],

                  [ 0, '! $y ? +1 : 0' ],
                  [ 0, '$x ? !$y : +0' ],
                  [ 0, '1 + !$x == 1' ], # taken as being arithmetic

                  [ 1, '! $x == 1' ],
                  [ 1, '! ++$x == 1' ],
                  [ 1, '! $x =~ /xx/' ],
                  [ 0, '! foo() + 1' ],
                  [ 0, '! ($x+$y) + 1' ],
                  [ 0, '! -f $x + 1' ],
                  [ 1, '! ($x) == 1' ],
                  [ 1, '! ($x+$y) == 1' ],

                  # builtin no args
                  [ 0, '! time() + 1' ],
                  [ 0, '! time + 1' ],  # builtin
                  [ 0, '! (time)' ],
                  [ 0, '(! time)' ],

                  # builtin one arg
                  # not handled yet
                  # [ 1, '! fileno FH == 1' ],

                  # "**" is higher precedence
                  [ 0, '! 2**32 + 1' ],
                  [ 0, '! 2**32 && 1' ],
                  [ 1, '! 2**32 > 123' ],

                  [ 1, '! time < 123' ],
                  [ 1, '! $x++ == 2' ],
                  [ 1, '! ($x+$y) == 2' ],
                  [ 1, '! $x->foo == 2' ],
                  [ 1, '! $x->foo() == 2' ],
                  [ 1, '! $x->foo->bar == 2' ],
                  [ 1, '! $x->foo->bar < 2' ],

                  # Perl parses these parse as < operator, so the ! is bad
                  [ 1, '! $x->foo->bar <*.c>' ],
                  [ 1, '! $x->foo->bar <STDIN>' ],

                  # some bad bits seen in the wild
                  #
                  [ 1, 'if (!$data =~ /^"/) { blah(); }' ],
                  [ 1, '!$data =~ /^"/' ],
                  #
                  [ 1, '(! $Config{\'archname\'} =~ /RM\d\d\d-svr4/)' ],
                  #
                  [ 1, 'grep !_type($_) eq \'ARRAY\', $a1, $a2' ],
                  [ 1, '! _type($_) eq \'ARRAY\'' ],
                  #
                  [ 1, '(! $opts{exclude} || ! $File::Find::name =~ /$opts{exclude}/)' ],
                  [ 1, '! $File::Find::name =~ /$opts{exclude}/' ],

                  # report about the first only
                  [ 0, '! ! $x + 1' ],
                  [ 1, '! ! $x >= 1' ],
                  [ 0, '! ! -f $x + 1' ],
                  [ 0, '! ! -f $x && 1' ],
                  [ 0, '-f ! $x + 1' ],
                  [ 1, '! -f ne 1' ],

                  [ 1, '! FOO > 100' ],
                  [ 1, '! FOO < 100' ],
                  [ 1, 'use constant FOO => 123;
                        ! FOO > 100' ],
                  [ 1, 'use constant FOO => 123;
                        ! FOO < 100 || $bar > 200' ],
                  [ 1, 'sub FOO () { 123 }
                        ! FOO < 100 || $bar > 200' ],

                  [ 0, '! $x' ],
                  [ 0, '! $x && $y' ],
                  [ 0, '! $x || $y' ],
                  [ 0, '! $x and $y' ],
                  [ 0, '! $x or $y' ],
                  [ 0, '! $x**$y or $y' ],
                  [ 0, '! grep $_ < 123' ],
                  [ 0, '$foo = ! $foo if $bar < 123' ],
                  [ 0, '$foo = ! $foo unless $bar < 123' ],
                  [ 0, '$foo = ! $foo while $bar < 123' ],

                  [ 0, 'FOO' ],  # invalid, but not an error
                  [ 0, '$foo !' ],  # invalid, but not an error
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

exit 0;
