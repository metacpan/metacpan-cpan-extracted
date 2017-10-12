#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Test::More tests => 422;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull;

#------------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull->VERSION($check_version); 1 }, "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# _DEV_NULL_RE matching

{
  ## no critic (ProhibitUnixDevNull)
  my $have_dev_null = (-e '/dev/null');

  foreach my $data ([ 1, '', '/dev/null' ],
                    [ 1, '<', '/dev/null' ],
                    [ 1, '>', '/dev/null' ],
                    [ 1, '>>', '/dev/null' ],
                    [ 1, '+<', '/dev/null' ],
                    [ 1, '+>', '/dev/null' ],
                    [ 1, '+>>', '/dev/null' ],
                    [ 0, '>&', '/dev/null' ],
                   ) {
    my ($want_match, $mode, $filename) = @$data;

    for my $pre_space ('', ' ', "\t\r\n\f") {
      for my $mid_space ('', ' ', "\t\r\n\f") {
        for my $post_space ('', ' ', "\t\r\n\f") {

          my $oname = $pre_space . $mode . $mid_space . $filename . $post_space;

          if ($want_match) {
          SKIP: {
              $have_dev_null
                or skip "no /dev/null file exists", 1;
              my $open_ok = open FH,$oname;
              ok ($open_ok, "can in fact open '$oname'");
              if ($open_ok) {
                close FH or die "oops, cannot close '$oname'";
              }
            }
          }

          ## no critic (ProtectPrivateSubs)
          my $got_match = ($oname =~ Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull::_DEV_NULL_RE()
                           ? 1 : 0);
          is ($got_match, $want_match, "_DEV_NULL_RE match $oname");
        }
      }
    }
  }
}

#------------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull$');
{ my @p = $critic->policies;
  is (scalar @p, 1, 'single policy ProhibitUnixDevNull');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 1, 'open FH, "</dev/null"' ],
                  [ 1, "open FH, '/dev/null'" ],
                  [ 1, 'open FH, qq{>/dev/null}' ],
                  [ 1, 'open FH, q!>> /dev/null!' ],
                  [ 0, 'print "flames to /dev/null"' ],
                  [ 1, 'foreach (qw(/tmp /dev/null /foo)) { }' ],
                  [ 0, 'foreach (qw(/tmp/null)) { }' ],

                  [ 0, 'system("echo hi >/dev/null")' ],
                  [ 0, 'if ($f eq "/dev/null") { }' ],
                  [ 0, 'return (q{</dev/null} ne $f);' ],
                 ) {
  my ($want_count, $str) = @$data;

  my @violations = $critic->critique (\$str);
  my $got_count = scalar @violations;
  is ($got_count, $want_count, "critique: $str");
}

exit 0;
