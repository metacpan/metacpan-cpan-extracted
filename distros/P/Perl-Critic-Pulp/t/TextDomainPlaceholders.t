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
use Test::More tests => 60;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;


#-----------------------------------------------------------------------------
my $want_version = 96;
is ($Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders->VERSION($check_version); 1 }, "VERSION class check $check_version");
}


#-----------------------------------------------------------------------------
# string_any_vars()

foreach my $data (## no critic (RequireInterpolationOfMetachars)
                  [ '', 0 ],
                  [ 'foo', 0 ],
                  [ '$foo', 1 ],
                  [ '\\$foo', 0 ],
                  [ '\\\\$foo', 1 ],

                  [ 'zz @foo', 1 ],
                  [ 'zz \\@foo', 0 ],
                  [ 'zz \\\\@foo', 1 ],

                 ) {
  my ($str, $want) = @$data;

  my $got = Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::_string_any_vars($str) ? 1 : 0;
  is ($got, $want, "str: \"$str\"");
}

#-----------------------------------------------------------------------------

require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy TextDomainPlaceholders');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 0, '__x("")' ],
                  [ 0, '__x(\'\')' ],
                  [ 0, '__x(\'{foo}\', foo => 123)' ],
                  [ 0, '__x(\'{foo}\', \'foo\' => 123)' ],
                  [ 0, '__x(\'{foo}\', "foo" => 123)' ],

                  [ 1, '__x(\'{foo}\')' ],
                  [ 1, '__x(\'\', foo => 123)' ],
                  [ 2, '__x(\'{foo}\', bar => 123)' ],

                  [ 1, '__x(\'$x\', foo => 123)' ],

                  # $x in the format is an interpolation, can't be sure foo
                  # arg is unused; but backslashed $ is not an interpolation
                  # and can tell unused
                  [ 0, '__x("$x", foo => 123)' ],
                  [ 1, '__x("\\$x", foo => 123)' ],
                  [ 0, '__x("\\\\$x", foo => 123)' ],
                  [ 1, '__x("\\\\\\$x", foo => 123)' ],

                  [ 0, '__x(\'{foo}\', $x => 123)' ],
                  [ 1, '__x(\'{foo}\', $x => 123, bar => 456)' ],

                  [ 0, '__x(<<HERE, foo => 123)
{foo}
HERE' ],
                  [ 1, '__x(<<HERE, foo => 123)
  {foo} {bar}
HERE' ],
                  [ 0, '__x(<<HERE, foo => 123)
  $x
  HERE' ],
                  [ 1, '__x(<<\'HERE\', foo => 123)
  $x
  HERE' ],

                  [ 0, '__x(\'{foo}\' . \'{bar}\',
                            foo => 123, bar => 456)' ],

                  [ 1, 'Locale::TextDomain::__x(\'{foo}\')' ],
                  [ 0, '__x(\'{foo}\', @args)' ],
                  [ 1, '__x(\'{foo}\', bar => 123, @args)' ],

                  [ 0, '__nx(\'{foo}\', \'{foo}s\', $n, foo => 123)' ],
                  [ 0, '__nx(\'{foo}\', \'{foo}s\', $n, "foo", $foo)' ],
                  [ 0, '__nx(\'{foo}\', \'{foo}s\', 123, "foo", $foo)' ],
                  [ 0, '__nx(\'{foo}\', \'{foo}s\', -1, "foo", $foo)' ],
                  [ 1, '__nx(\'{foo}\', \'{bar}\',  $n, foo => 123)' ],
                  [ 2, '__nx(\'{foo}\', \'{bar}\',  $n)' ],
                  [ 3, '__nx(\'{foo}\', \'{bar}\',  $n, quux => 123)' ],

                  # forgotten count argument
                  [ 3, '__nx(\'{foo}\', \'{foo}s\')' ],
                  [ 1, '__nx(\'{foo}\', \'{foo}s\', foo=>$foo)' ],
                  [ 1, '__nx(\'{foo}\', \'{foo}s\', foo=>$foo, bar=>$bar)' ],
                  [ 4, '__nx(\'{foo}\', \'{foo}s\', foo => 123)' ],
                  [ 5, '__nx(\'{foo}\', \'{foo}s\', foo => 123, bar => 456)' ],
                  # from the POD
                  [ 3, "print __nx('Read one file',
                                   'Read {numfiles} files',
                                   numfiles => 123);     # bad" ],

                  [ 0, '__xn(\'{foo}\', \'{foo}s\', $n, foo => 123)' ],
                  [ 3, '__xn(\'{foo}\', \'{foo}s\')' ],

                  [ 0, '__px(\'context\', \'{foo}\', foo => 123)' ],
                  [ 1, '__px(\'context\', \'{foo}\')' ],

                  [ 0, '__npx(\'context\', \'{foo}\', \'{foo}s\',
                              $n, foo => 123)' ],
                  [ 3, '__npx(\'context\', \'{foo}\', \'{foo}s\')' ],

                  # not function calls
                  [ 0, '
  my %funcs = (__x   => 1,
               __nx  => 1,
               __xn  => 1,

               __px  => 1,
               __npx => 1);
' ],
                  [ 0, 'print $obj->__x' ],
                  [ 0, 'print My::Class->__x' ],

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
