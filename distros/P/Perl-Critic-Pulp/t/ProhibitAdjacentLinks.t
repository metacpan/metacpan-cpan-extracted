#!/usr/bin/perl -w

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
use Test::More tests => 26;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks;


#------------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
diag "Perl::Critic version ",Perl::Critic->VERSION;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitAdjacentLinks');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data
  (
   [ 0, ("=pod\n"
         . "\n"
         . "=begin comment\n"
         . "\n"
         . "L<One> L<Two>\n"
         . "\n"
         . "=end comment\n") ],

   [ 1, ("=pod\n"
         . "\n"
         . "=begin :text\n"
         . "\n"
         . "L<One> L<Two>\n"
         . "\n"
         . "=end :text\n") ],

   # RT#94318 (Mike O'Regan) was a warning when an internal adjacent to an
   # external link
   [ 1, "=pod\n\nL<File::Copy> L</Developer/Tools/GetFileInfo>\n" ],
   [ 1, "=pod\n\nL</internal> L<xyzzy|Two>\n" ],

   [ 0, "=pod\n\nL<One>\n\nL<Two>\n" ],
   [ 1, "=pod\n\nL<One> L<Two>\n" ],
   [ 0, "=pod\n\nL<One> and L<Two>\n" ],
   [ 2, "=pod\n\nL<One>\nL<Two>\nL<Three>\n" ],
   [ 1, "=pod\n\nblah blah L<One>\t\tL<Two> blah\n" ],

   [ 1, "=pod\n\nL<One> L<One>\n" ],
   [ 0, "=pod\n\nL<One> L<display|One>\n" ],
   [ 0, "=pod\n\nL<display|One> L<One>\n" ],
   [ 0, "=pod\n\nL<display|One> L<xyzzy|One>\n" ],
   [ 1, "=pod\n\nL<display|One> L<xyzzy|Two>\n" ],

   [ 0, "=pod\n\nS<< L<One>\n\nL<Two> >>\n" ],

   # from Template::Context, but the # separator is wrong
   # [ 0, "=pod\n\nL<Template> L<new()|Template#new()>\n" ],

   # from DBIx::Class::Storage::DBI
   [ 0,
     "=pod\n\nL<DBI|DBI/ATTRIBUTES_COMMON_TO_ALL_HANDLES> "
     . "L<connection|DBI/Database_Handle_Attributes>\n" ],
   [ 1,
     "=pod\n\nL<DBI/ATTRIBUTES_COMMON_TO_ALL_HANDLES>"
     . " L<DBI/Database_Handle_Attributes>\n" ],

   # from DhMakePerl::PodParser of dh-make-perl
   [ 0, "=pod\n\nL<Pod::Parser> L<command|Pod::Parser/command>" ],
   [ 1, "=pod\n\nL<Pod::Parser> L<Pod::Parser/command>" ],

  ) {

  my ($want_count, $str) = @$data;
  $str = "$str";

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: '$str'");

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;
