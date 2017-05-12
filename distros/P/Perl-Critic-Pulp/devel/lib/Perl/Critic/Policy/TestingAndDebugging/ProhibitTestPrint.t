#!/usr/bin/perl

# Copyright 2008, 2010, 2011, 2013 Kevin Ryde

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


use strict;
use warnings;
use Test::More tests => 32;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::TestingAndDebugging::inprogressProhibitTestPrint;

#------------------------------------------------------------------------------
# my $want_version = 28;
# is ($Perl::Critic::Policy::TestingAndDebugging::inprogressProhibitTestPrint::VERSION,
#     $want_version,
#     'VERSION variable');
# is (Perl::Critic::Policy::TestingAndDebugging::inprogressProhibitTestPrint->VERSION,
#     $want_version,
#     'VERSION class method');
# {
#   ok (eval { Perl::Critic::Policy::TestingAndDebugging::inprogressProhibitTestPrint->VERSION($want_version); 1 },
#       "VERSION class check $want_version");
#   my $check_version = $want_version + 1000;
#   ok (! eval { Perl::Critic::Policy::TestingAndDebugging::inprogressProhibitTestPrint->VERSION($check_version); 1 }, "VERSION class check $check_version");
# }


#------------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'TestingAndDebugging::inprogressProhibitTestPrint');
{ my @p = $critic->policies;
  is (scalar @p, 1, 'single policy inprogressProhibitTestPrint');

  # my $policy = $p[0];
  # ok (eval { $policy->VERSION($want_version); 1 },
  #     "VERSION object check $want_version");
  # my $check_version = $want_version + 1000;
  # ok (! eval { $policy->VERSION($check_version); 1 },
  #     "VERSION object check $check_version");
}

foreach my $data ([ 1, 'print {*STDOUT} 123;' ],
                  [ 0, 'print {*FOO} 123;' ],
                  [ 1, 'print {\\*STDOUT} 123;' ],
                  [ 0, 'print {\\*FOO} 123;' ],

                  [ 1, 'print "hello"' ],
                  [ 0, 'print "#ok"' ],
                  [ 0, 'print "#not ok"' ],
                  [ 1, 'print STDOUT "hello"' ],
                  [ 1, 'print STDERR "hello"' ],
                  [ 1, 'print {STDOUT} "hello"' ],
                  [ 1, 'print {STDERR} "hello"' ],
                  [ 1, 'print { STDOUT } "hello"' ],
                  [ 1, 'print { # comment
                                STDOUT } "hello"' ],

                  [ 0, 'print MYHANDLE "hello"' ],
                  [ 0, 'print $myfh "hello"' ],
                  [ 0, 'print $myfh # comment
                              "hello"' ],
                  [ 0, 'print {$myfh} "hello"' ],

                  [ 1, 'print $myvar' ],
                  [ 1, 'print $myvar, "hello"' ],
                  [ 1, 'print $myvar , "hello"' ],
                  [ 1, 'print $myvar' ],
                  [ 1, 'print $x+$y' ],
                  [ 1, 'print $x->method' ],
                  [ 1, 'print $myvar;' ],

                  [ 1, 'print myfunc();' ],
                  [ 0, 'print MYHANDLE (1+2);' ],

                  [ 1, 'print MYFUNC' ],
                  [ 1, 'print STDOUT' ],
                  [ 1, 'print STDERR' ],
                  [ 0, 'print ARGV' ],
                 ) {
  my ($want_count, $str) = @$data;

  $str = 'use Test::Simple; ' . $str;
  {
    my @violations = $critic->critique (\$str);
    my $got_count = scalar @violations;
    is ($got_count, $want_count, $str);
  }

}

exit 0;
