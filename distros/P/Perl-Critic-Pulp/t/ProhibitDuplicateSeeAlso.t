#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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
use Test::More tests => 15;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso;


#------------------------------------------------------------------------------
my $want_version = 99;
is ($Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
diag "Perl::Critic version ",Perl::Critic->VERSION;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitDuplicateSeeAlso');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data
  (
   [ 1, "
=head1 SEE ALSO

L<Foo::Bar>

L<Foo::Bar>
" ],

   [ 0, "
=head1 SEE ALSO

L<Foo::Bar>

=begin comment

L<Foo::Bar>

=end comment
" ],

   [ 0, "
=head1 SEE ALSO

L<Foo>, L<Bar>
" ],

   [ 1, "
=head1 SEE ALSO

L<Foo::Bar>, L<Foo::Bar>
" ],

   [ 0, "
=head1 SEE ALSO

L<Foo::Bar>, L<Foo::Bar/Advanced>
" ],

   [ 0, "
=head1 DESCRIPTION

Blah L<Foo::Bar>

=head1 SEE ALSO

L<Foo::Bar>
" ],

   [ 0, "
=head1 SEE ALSO

L<perlfunc/alarm>,
L<perlfunc/kill> 
" ],

   [ 0, "
=head1 SEE ALSO

L<Foo::One>, L<Foo::Two>
(C<Foo::Two> runs faster)
" ],

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
