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
use Test::More tests => 47;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Compatibility::Gtk2Constants;


#-----------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::Compatibility::Gtk2Constants::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Compatibility::Gtk2Constants->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Compatibility::Gtk2Constants->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Compatibility::Gtk2Constants->VERSION($check_version); 1 }, "VERSION class check $check_version");
}


#-----------------------------------------------------------------------------
# _qualifier_and_basename()

foreach my $data ([ 'Foo',            undef,      'Foo' ],
                  [ '::Bar',          '',         'Bar' ],
                  [ 'Foo::Bar',       'Foo',      'Bar' ],
                  [ 'Foo::Bar::QUUX', 'Foo::Bar', 'QUUX' ],
                 ) {
  ## no critic (ProtectPrivateSubs)
  my ($str, $want_qualifier, $want_basename) = @$data;
  my ($got_qualifier, $got_basename)
    = Perl::Critic::Policy::Compatibility::Gtk2Constants::_qualifier_and_basename ($str);
  is ($want_qualifier, $got_qualifier, "qualifier of: $str");
  is ($want_basename,  $got_basename,  "basename of: $str");
}

#-----------------------------------------------------------------------------
# the policy

require Perl::Critic;
my $single_policy = 'Compatibility::Gtk2Constants';
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => $single_policy);
{ my @p = $critic->policies;
  is (scalar @p, 1,
      "single policy $single_policy");

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data
  (
   ## no critic (RequireInterpolationOfMetachars)
   [ 0, 'EVENT_PROPAGATE' ],
   [ 1, 'Gtk2::EVENT_PROPAGATE' ],
   [ 1, 'use Gtk2; Gtk2::EVENT_PROPAGATE' ],
   [ 1, 'use Gtk2 1.200; Gtk2::EVENT_PROPAGATE' ],
   [ 0, 'use Gtk2 1.211; Gtk2::EVENT_PROPAGATE' ],
   [ 0, 'use Gtk2 1.220; Gtk2::EVENT_PROPAGATE' ],

   # Exporter style numbers
   [ 1, 'use Gtk2 "1.000"; Gtk2::EVENT_PROPAGATE' ],
   [ 0, 'use Gtk2 "1.220"; Gtk2::EVENT_PROPAGATE' ],
   [ 1, 'use Gtk2 "v1.100"; Gtk2::EVENT_PROPAGATE' ],
   [ 0, 'use Gtk2 "v1.220"; Gtk2::EVENT_PROPAGATE' ],
   [ 1, "use Gtk2 'v1.100'; Gtk2::EVENT_PROPAGATE" ],
   [ 0, "use Gtk2 'v1.220'; Gtk2::EVENT_PROPAGATE" ],

   [ 1, 'Gtk2->EVENT_PROPAGATE' ],
   [ 0, 'Some::Other::Class->EVENT_PROPAGATE' ],
   [ 0, '$variable->EVENT_PROPAGATE' ],
   [ 0, '->EVENT_PROPAGATE' ],
   [ 1, 'use Gtk2 1.200; Gtk2->EVENT_PROPAGATE' ],
   [ 0, 'use Gtk2 1.211; Gtk2->EVENT_PROPAGATE' ],

   [ 1, 'Glib::SOURCE_REMOVE' ],
   [ 0, 'Foo::Bar::SOURCE_REMOVE' ],

   [ 0, 'my $hashref = { Glib::SOURCE_REMOVE => 123 }' ],
   [ 0, 'use Glib; sub SOURCE_REMOVE { print 123 }' ],

   [ 0, '*myalias = \&SOURCE_REMOVE' ],
   [ 1, '*myalias = \&Glib::SOURCE_REMOVE' ],
   [ 1, 'use Glib; *myalias = \&SOURCE_REMOVE' ],
   [ 0, 'use Glib 1.220; *myalias = \&SOURCE_REMOVE' ],

   [ 0, '&EVENT_PROPAGATE()' ],
   [ 1, '&Gtk2::EVENT_PROPAGATE()' ],
   [ 0, 'use Gtk2 1.220; &Gtk2::EVENT_PROPAGATE()' ],

   [ 0, '\&EVENT_PROPAGATE()' ],
   [ 1, '\&Gtk2::EVENT_PROPAGATE()' ],
   [ 0, 'use Gtk2 1.220; \&Gtk2::EVENT_PROPAGATE()' ],

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
