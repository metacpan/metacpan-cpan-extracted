#!/usr/bin/perl -w

# Copyright 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Test::More tests => 52;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

require Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings;


#-----------------------------------------------------------------------------
my $want_version = 94;
is ($Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings->VERSION($check_version); 1 }, "VERSION class check $check_version");
}


#-----------------------------------------------------------------------------

{
  require Perl::Critic;
  my $critic = Perl::Critic->new
    ('-profile' => '',
     '-single-policy' => '^Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings$');
  my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitDuplicateHeadings');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#-----------------------------------------------------------------------------

{
  my %critic;

  # return a Perl::Critic object which has a single policy
  # ProhibitDuplicateHeadings with the given $uniqueness parameter
  sub make_critic {
    my ($uniqueness) = @_;
    return ($critic{$uniqueness} ||= do {
      ### make new critic for: $uniqueness
      require Perl::Critic;
      my $critic = Perl::Critic->new ('-profile' => '', -only => 1);

      $critic->add_policy
        (-policy => 'Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings',
         -params => { uniqueness => $uniqueness });

      my @p = $critic->policies;
      scalar(@p)==1 or die "oops, policy count ",scalar(@p);
      ### made _uniqueness: $p[0]->{'_uniqueness'}
      $critic
    });
  }
}

foreach my $data (
#------------------------------------
                  [ [ all      => 1,
                      adjacent => 1,
                      ancestor => 0,
                      sibling  => 1,
                      default  => 1,
                    ], '

=head1 CLASS     METHODS

=head1  CLASS METHODS

=cut

=head1 MORE

' ],

#------------------------------------
                  [ [ all      => 1,
                      adjacent => 1,
                      ancestor => 0,
                      sibling  => 1,
                      default  => 1,
                    ], '
=head1 NAME

=head1  NAME
' ],

#------------------------------------
                  [ [ all      => 3,
                      adjacent => 2,
                      ancestor => 0,
                      sibling  => 0,
                      default  => 2,
                    ], '
=head1 One

=head4 Descend

=head3 Descend

=head2 Descend

=head1 Two

=head4 Descend

' ],

#------------------------------------
                  [ [ all      => 1,
                      adjacent => 1,
                      ancestor => 0,
                      sibling  => 1,
                      default  => 1,
                    ], '
=head1 NAME

=head1 NAME
' ],

#------------------------------------
                  [ [ all      => 1,
                      adjacent => 1,
                      ancestor => 1,
                      sibling  => 0,
                      default  => 1,
                    ], '
=head1 NAME

=head2 NAME
' ],

#------------------------------------
                  [ [ all      => 1,
                      adjacent => 0,
                      ancestor => 0,
                      sibling  => 0,
                      default  => 0,
                    ], '
=head1 Top One

=head2 Details

=head1 Top Two

=head2 Details

As per the POD, second "Details" ok for default style.
' ],

#------------------------------------
                  [ [ all      => 1,
                      adjacent => 1,
                      ancestor => 0,
                      sibling  => 0,
                      default  => 1,
                    ], '
=head1 TOP ONE

=head2 TOP TWO

=head1 TOP TWO
' ],

#------------------------------------
                  [ [ all      => 1,
                      adjacent => 0,
                      ancestor => 0,
                      sibling  => 1,
                      default  => 1,
                    ], '
=head1 TOP

=head2 Subheading

=head1 TOP
' ],

#------------------------------------
                  [ [ all      => 2,
                      ancestor => 1,
                      sibling  => 1,
                      'ancestor,sibling'  => 2,
                      default  => 2,
                    ], '
=head1 TOP

=head2 TOP

=head1 TOP
' ],

#------------------------------------
                 ) {
  my ($want_aref, $str) = @$data;

  while (@$want_aref) {
    my $uniqueness = shift @$want_aref;
    my $want_count = shift @$want_aref;
    ### $want_count
    ### $uniqueness

    my $critic = make_critic($uniqueness);
    my @violations = $critic->critique (\$str);
    
    my $got_count = scalar @violations;
    is ($got_count, $want_count, "uniqueness=$uniqueness str: $str");
    
    if ($got_count != $want_count) {
      foreach (@violations) {
        diag ($_->description);
      }
    }
  }
}

exit 0;
