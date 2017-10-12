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
use Test::More tests => 135;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Modules::ProhibitPOSIXimport;


#-----------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::Modules::ProhibitPOSIXimport::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Modules::ProhibitPOSIXimport->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Modules::ProhibitPOSIXimport->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Modules::ProhibitPOSIXimport->VERSION($check_version); 1 }, "VERSION class check $check_version");
}



#-----------------------------------------------------------------------------
# _inc_exporter_imports_type()

require PPI::Document;
foreach my $data
  (
   [ 'no_import', "require Xyzzy" ],
   [ 'no_import', "no Xyzzy" ],

   [ 'default',   "use Xyzzy" ],
   [ 'default',   "use Xyzzy 1" ],
   [ 'no_import', "use Xyzzy 1 ()" ],
   [ 'explicit',  "use Xyzzy 1 'tzset'" ],
   [ 'explicit',  "use Xyzzy 1 ('tzset')" ],
   [ 'explicit',  "use Xyzzy 1 ('tzset'),()" ],

   [ 'explicit',  "use Xyzzy 'tzset'" ],
   [ 'explicit',  "use Xyzzy qw(tzset)" ],

   [ 'no_import', "use Xyzzy ()" ],
   [ 'default',   "use Xyzzy (),1" ],
   [ 'explicit',  "use Xyzzy (),1,'tzset'" ],
   [ 'explicit',  "use Xyzzy (),'tzset'" ],

   [ 'default',   "use Xyzzy 1.0" ],
   [ 'explicit',  "use Xyzzy 1.0, 'tzset'" ],
   [ 'default',   "use Xyzzy '1'" ],
   [ 'explicit',  "use Xyzzy '1', 'tzset'" ],
   [ 'default',   "use Xyzzy '1.0'" ],
   [ 'explicit',  "use Xyzzy '1.0', 'tzset'" ],

   [ 'default',   "use Xyzzy qw(1)" ],
   [ 'explicit',  "use Xyzzy qw(1 tzset)" ],

   [ 'no_import', "use Xyzzy (())" ],
   [ 'no_import', "use Xyzzy ((()))" ],
   [ 'default',   "use Xyzzy (((),()))" ],

   [ 'default',   "use Xyzzy ((((1))))" ],
   [ 'explicit',  "use Xyzzy ((((1)),'tzset'))" ],
   [ 'default',   "use Xyzzy (),()" ],
   [ 'default',   "use Xyzzy (),(),()" ],
   [ 'explicit',  "use Xyzzy (),('dup')" ],

  ) {
  my ($want, $base_str) = @$data;

  foreach my $str ($base_str,
                   $base_str . ';') {
    my $doc = PPI::Document->new(\$str);
    my $inc = $doc->schild(0);
    $inc->isa('PPI::Statement::Include')
      or die "Oops, didn't get Include: $str";

    ## no critic (ProtectPrivateSubs)
    my $got = Perl::Critic::Policy::Modules::ProhibitPOSIXimport::_inc_exporter_imports_type($inc);
    is ($got, $want, "str: $str");
  }
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Modules::ProhibitPOSIXimport$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitPOSIXimport');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data
  ([ 0, "use POSIX" ],
   [ 0, "package main; use POSIX" ],
   [ 1, "package Foo; use POSIX" ],

   [ 0, "use POSIX ()" ],
   [ 0, "package Foo; use POSIX ()" ],
   [ 0, "package Foo; use POSIX (())" ],
   [ 0, "package Foo; use POSIX ((()))" ],
   [ 1, "package Foo; use POSIX (),()" ],

   [ 1, "package Foo; use POSIX (),1" ],
   [ 1, "package Foo; use POSIX (1)" ],
   [ 1, "package Foo; use POSIX ((1))" ],
   [ 0, "package Foo; use POSIX (),1,'tzset'" ],
   [ 0, "package Foo; use POSIX (1),'tzset'" ],
   [ 0, "package Foo; use POSIX ((1)),'tzset'" ],
   [ 0, "package Foo; use POSIX (((1),'tzset'))" ],

   [ 1, "package Foo; use POSIX 1" ],
   [ 1, "package Foo; use POSIX 1.0" ],
   [ 1, "package Foo; use POSIX '1'" ],
   [ 1, "package Foo; use POSIX '1.0'" ],

   [ 0, "package Foo; use POSIX 'tzset'" ],
   [ 0, "package Foo; use POSIX qw(tzset)" ],

   [ 0, "package Foo; use POSIX 1 'tzset'" ],
   [ 0, "package Foo; use POSIX 1, 'tzset'" ],
   [ 0, "package Foo; use POSIX 1.0, 'tzset'" ],
   [ 0, "package Foo; use POSIX '123', 'tzset'" ],
   [ 0, "package Foo; use POSIX qw(1 tzset)" ],

   [ 0, "use POSIX (),('dup')" ],
   [ 0, "package Foo; use POSIX (),('dup')" ],

   [ 1, join ('; ', "package Foo; use POSIX", ("tzset()") x 2) ],
   [ 0, join ('; ', "package Foo; use POSIX", ("tzset()") x 20) ],
   [ 1, join ('; ', "package Foo; use POSIX", ("&dup()") x 2) ],
   [ 0, join ('; ', "package Foo; use POSIX", ("&dup()") x 20) ],
   [ 1, join ('; ', "package Foo; use POSIX", ("print \\&tzset") x 2) ],
   [ 0, join ('; ', "package Foo; use POSIX", ("print \\&tzset") x 20) ],

  ) {
  my ($want_count, $str) = @$data;

  foreach my $str ($str, $str . ';') {
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
