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
use Test::More tests => 21;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Miscellanea::TextDomainUnused;


#-----------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::Miscellanea::TextDomainUnused::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Miscellanea::TextDomainUnused->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Miscellanea::TextDomainUnused->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Miscellanea::TextDomainUnused->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Miscellanea::TextDomainUnused$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy TextDomainUnused');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 1, "use Locale::TextDomain ('MyMessageDomain')" ],

                  [ 0, "use Locale::TextDomain ('MyMessageDomain');
                        print __('hello')" ],
                  [ 0, "use Locale::TextDomain ('MyMessageDomain');
                        print __x('hello')" ],
                  [ 0, "use Locale::TextDomain ('MyMessageDomain');
                        print __n('hello','hellos')" ],
                  [ 0, "use Locale::TextDomain ('MyMessageDomain');
                        print __xn('hello','hellos')" ],
                  [ 0, "use Locale::TextDomain ('MyMessageDomain');
                        print __p('context','hello')" ],

                  [ 0, "use Locale::TextDomain ('MyMessageDomain');
                        print N__('hello')" ],
                  [ 0, "use Locale::TextDomain ('MyMessageDomain');
                        print N__n('hello','hellos')" ],

                  # %__ hash
                  [ 0, 'use Locale::TextDomain ("MyMessageDomain");
                        print $__{hello};' ],

                  [ 0, 'use Locale::TextDomain ("MyMessageDomain");
                        print "$__{hello}";' ],
                  [ 0, 'use Locale::TextDomain ("MyMessageDomain");
                        print "<<< $__{hello} >>>";' ],

                  # $__ hashref
                  [ 0, 'use Locale::TextDomain ("MyMessageDomain");
                        print $__->{hello};' ],
                  [ 1, 'use Locale::TextDomain ("MyMessageDomain");
                        print "$__X";' ],
                  [ 0, 'use Locale::TextDomain ("MyMessageDomain");
                        print "*** $__->{hello} ***";' ],

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
