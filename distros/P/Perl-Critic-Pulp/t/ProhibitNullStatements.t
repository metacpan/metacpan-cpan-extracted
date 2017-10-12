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
use Test::More tests => 30;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements;


#-----------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements$');
my @policies = $critic->policies;
is (scalar @policies, 1, 'single policy ProhibitNullStatements');

my $policy = $policies[0];
ok (eval { $policy->VERSION($want_version); 1 },
    "VERSION object check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { $policy->VERSION($check_version); 1 },
    "VERSION object check $check_version");

foreach my $data
  (## no critic (RequireInterpolationOfMetachars)

   # more stuff afterwards
   [ 0, 'use TryCatch; try { attempt() } 1;' ],
   [ 0, 'use TryCatch; try { attempt() } exit 1;' ],
   [ 1, 'use TryCatch; try { attempt() } catch { foo() } finally { bar () };' ],

   # this one mis-detected as not a "for" loop
   # [ 1, 'use TryCatch; try { attempt() } catch { foo() } for (1..10) { };' ],

   [ 1, 'use Try;               sub foo { try { attempt() } catch { recover() }; }' ],
   [ 1, 'use TryCatch;          sub foo { try { attempt() } catch { recover() }; }' ],
   [ 1, 'use syntax "try";      sub foo { try { attempt() } catch { recover() }; }' ],
   [ 0, 'use Try::Tiny;         sub foo { try { attempt() } catch { recover() }; }' ],
   [ 0, 'use Try::Tiny::Except; sub foo { try { attempt() } catch { recover() }; }' ],

   [ 1, ';' ],
   [ 1, 'use Foo;;' ],
   [ 1, 'if (1) {};' ],
   [ 0, 'for (;;) { }' ],
   [ 0, 'map {; $_, 123} @some_list;' ],
   [ 0, 'map { ; $_, 123} @some_list;' ],
   [ 0, 'map { # fdjks
                              ; $_, 123} @some_list;' ],
   [ 1, 'map {;; $_, 123} @some_list;' ],
   [ 1, 'map { ; ; $_, 123} @some_list;' ],
   [ 1, 'map { ; # fjdk
                              ; $_, 123} @some_list;' ],
   [ 0, 'grep {# this is a block
                              ;
                              length $_ and $something } @some_list;' ],
   ## use critic
  ) {
  my ($want_count, $str) = @$data;
  {
    my @violations = $critic->critique (\$str);

    my $got_count = scalar @violations;
    is ($got_count, $want_count, "str: $str");

    if ($got_count != $want_count) {
      foreach (@violations) {
        diag ($_->description);
      }
    }
  }
}


$policy->{'_allow_perl4_semihash'} = 1;

foreach my $data ([ 0, ';# a comment' ],
                  [ 0, "\n;# a comment" ],
                  [ 1, '  ;# but only at the start of a line' ],
                  [ 1, '; # no whitespace between' ],
                 ) {
  my ($want_count, $str) = @$data;
  {
    my @violations = $critic->critique (\$str);

    my $got_count = scalar @violations;
    is ($got_count, $want_count, "str: $str");

    if ($got_count != $want_count) {
      foreach (@violations) {
        diag ($_->description);
      }
    }
  }
}


exit 0;
