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
use Test::More tests => 20;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup;

#------------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

require Perl::Critic;
diag "Perl::Critic version ", Perl::Critic->VERSION;


my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitBadAproposMarkup');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  [ 0,
                    "=head1 NAME\n"
                    . "\n"
                    . "=begin text\n"
                    . "\n"
                    . "foo - C<bar>\n"
                    . "\n"
                    . "=end text\n"
                    . "\n"
                    . "=begin comment\n"
                    . "\n"
                    . "foo - C<bar>\n"
                    . "\n"
                    . "=end comment\n"
                    . "\n"
                    . "=for blah C<bar>\n"
                  ],

                  [ 1,
                    "=head1 NAME\n"
                    . "\n"
                    . "=begin text\n"
                    . "\n"
                    . "foo - C<bar>\n"
                    . "\n"
                    . "=end text\n"
                    . "\n"
                    . "foo - C<bar>\n"
                  ],

                  [ 1,
                    "=head1 NAME\n"
                    . "\n"
                    . "=begin :text\n"
                    . "\n"
                    . "foo - C<bar>\n"
                    . "\n"
                    . "=end :text\n" ],

                  # unterminated C< quietly ignored
                  [ 0, "=head1 SOMETHING\n\nC<" ],

                  [ 1, "=head1 NAME\n\nfoo - like C<bar>" ],
                  [ 1, "=head1 NAME \n\nfoo - like C<bar>" ],
                  [ 1, "=head1 \tNAME\t \n\nfoo - like C<bar>" ],

                  [ 0,
                    "\n## no critic (ProhibitBadAproposMarkup)\n"
                    . "\n"
                    . "=head1 NAME\n"
                    . "\n"
                    . "foo - like C<bar>\n\n"
                    . "=cut\n\n"
                    . "more_code();" ],

                  [ 0, "=head1 NAME\n\nfoo - like B<bar>" ],
                  [ 0, ("=head1 NAME\n\nfoo - like bar\n\n"
                        . "=head1 NEWSECT\n\nfoo - like C<bar>\n\n") ],

                  [ 0, "=head1 NAME OTHER\n\nfoo - like C<bar>\n" ],

                  # the offending pod can't be the last thing or "no critic"
                  # doesn't recognise it, or some such
                  #
                  [ 0, "## no critic (ProhibitBadAproposMarkup)\n\n=head1 NAME\n\nfoo - like C<bar>\n\n=cut\n\nfoo()\n" ],
                  #
                  [ 0, "## no critic (ProhibitBadAproposMarkup)\n\n__END__\n\n=head1 NAME\n\nfoo - like C<bar>\n\n=cut\n\nfoo()\n",
                    1.112 ],

                 ) {
  my ($want_count, $str, $pcver) = @$data;
  $str = "$str";

 SKIP: {
    if (defined $pcver && !eval{Perl::Critic->VERSION($pcver);1}) {
      skip "Perl-Critic before $pcver doesn't support \"no critic\" after __END__", 1;
      next;
    }

    my @violations = $critic->critique (\$str);

    my $got_count = scalar @violations;
    is ($got_count, $want_count, "str: '$str'");

    if ($got_count != $want_count) {
      foreach (@violations) {
        diag ($_->description);
      }
    }
  }
}

exit 0;
