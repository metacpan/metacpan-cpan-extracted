#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
use Test::More tests => 82;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens;


#------------------------------------------------------------------------------
my $want_version = 93;
is ($Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
diag "Perl::Critic version ",Perl::Critic->VERSION;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitUnbalancedParens');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  # =begin non-text
                  [ 0, "=begin comment\n\n(\n" ],
                  [ 1, "=begin :comment\n\n(\n" ],

                  # L<> link with markup in display part
                  [ 0, "=pod\n\nL<< display C<(>|/Section >>\n" ],
                  [ 1, "=pod\n\nL<display (|/Section>\n" ],

                  # mathematical range, not yet special
                  [ 1, "=pod\n\n[0,1)\n" ],

                  # smiley faces
                  [ 0, "=pod\n\n(blah :-) blah)\n" ],
                  [ 1, "=pod\n\n[ :-)\n" ],  # mismatched optional close
                  [ 0, "=pod\n\n( :-)\n" ],
                  [ 0, "=pod\n\n:-)\n" ],
                  [ 0, "=pod\n\n:) :-)\n" ],
                  [ 0, "=pod\n\nYou have been warned:-)" ],

                  # misc
                  [ 1, "=pod\n\nBlah C<som\ncode> blah (and B<something>\nfdfdsjkf sdjk sdk" ],
                  [ 0, "=pod\n\nF(n+1)=F(n)+A*[G(n+1)-F(n)]\n" ],
                  
                  # not an "item a) etc"
                  [ 0, "=pod\n\n(a) item\n" ],
                  [ 0, "=pod\n\nblah (s) item\n" ],
                  [ 0, "=pod\n\nblah(s) blah\n" ],
                  [ 0, "=pod\n\nbefore method(s) => sub { ... }\n" ],

                  # item 1) optional close
                  [ 0, "=pod\n\na) item\n" ],
                  [ 0, "=pod\n\n1) item\n" ],
                  [ 0, "=pod\n\n123) item\n" ],
                  [ 0, "=pod\n\nin middle a) one or b) two\n" ],
                  [ 0, "=pod\n\nin middle 1) one or 2) two\n" ],

                  # ${ not special
                  [ 1, "=pod\n\n\${\n" ],
                  [ 0, "=pod\n\n\${}\n" ],
                  [ 0, "=pod\n\n\${foo}\n" ],

                  # perl var $) optional close
                  [ 0, "=pod\n\n\$)\n" ],
                  [ 0, "=pod\n\n( \$)\n" ],
                  [ 0, "=pod\n\n(foo\$)\n" ],
                  [ 1, "=pod\n\n\$\$)\n" ],   # $$ not $)

                  # Bad link in Config::IniFiles 2.66.
                  # Display and section parts are the wrong way around,
                  # but the parens are ok.
                  [ 0, "=pod\n\nL</Section|display(-foo=E<gt>1)>\n" ],

                  [ 1, "=pod\n\n(\n" ],
                  [ 1, "=pod\n\n[\n" ],
                  [ 1, "=pod\n\n{\n" ],

                  [ 0, "=pod\n\n()\n" ],
                  [ 0, "=pod\n\n[]\n" ],
                  [ 0, "=pod\n\n{}\n" ],

                  [ 1, "=pod\n\n(blah\nblah\n" ],
                  [ 0, "=pod\n\n(blah\nblah)\n" ],

                  [ 1, "=pod\n\n(blah ( blah)\n" ],
                  [ 0, "=pod\n\n(blah () blah)\n" ],

                  # C<> markup
                  [ 0, "=pod\n\nC<\$(>\n" ],
                  [ 0, "=pod\n\nC<\$[>\n" ],
                  [ 0, "=pod\n\nC<[>\n" ],
                  [ 0, "=pod\n\nC<(>\n" ],
                  [ 1, "=pod\n\n( C<)>\n" ],

                  # quoted "(" etc
                  [ 0, "=pod\n\n\"(\"\n" ],
                  [ 0, "=pod\n\n\"[\"\n" ],
                  [ 1, "=pod\n\n[ \"]\"\n" ],
                  [ 1, "=pod\n\n( \")\"\n" ],
                  [ 0, "=pod\n\n'('\n" ],
                  [ 0, "=pod\n\n'['\n" ],
                  [ 0, "=pod\n\n'[['\n" ],
                  [ 0, "=pod\n\n'[{'\n" ],
                  [ 0, "=pod\n\n'[{(}])'\n" ],
                  [ 0, "=pod\n\n'[{]'\n" ],
                  [ 1, "=pod\n\n[ ']'\n" ],
                  [ 1, "=pod\n\n( ')'\n" ],
                  [ 0, "=pod\n\nabout \"(\" blah\n" ],

                  # perl vars $[ etc
                  [ 0, "=pod\n\n\$(\n" ],
                  [ 0, "=pod\n\n\$[\n" ],
                  [ 1, "=pod\n\n[ $]\n" ],

                  # perl var $$
                  [ 0, "=pod\n\n(\$\$)\n" ],
                  [ 0, "=pod\n\n[\$\$]\n" ],
                  [ 0, "=pod\n\n{\$\$}\n" ],
                  [ 1, "=pod\n\n\$\$(\n" ],
                  [ 1, "=pod\n\n\$\$[\n" ],
                  [ 1, "=pod\n\n\$\$]\n" ],

                  # sad faces
                  [ 0, "=pod\n\n:-(\n" ],
                  [ 0, "=pod\n\n:(\n" ],
                  [ 0, "=pod\n\n:-( :(\n" ],


                  # no critic override, but only works if not the last
                  # PPI::Element in the document, or something
                  [ 0,
                    "\n"
                    . "## no critic (ProhibitUnbalancedParens)\n"
                    . "\n"
                    . "=pod\n\n(\n"
                    . "\n"
                    . "=cut\n"
                    . "\nfoo()\n" ],

                  [ 0, "=pod\n\n=for ProhibitUnbalancedParens allow next\n\nAn ( unclosed.\n" ],
                  [ 1, "=pod\n\n=for ProhibitUnbalancedParens allow next\n\nAn ( unclosed.\n\nBut not a [ second one.\n" ],

                  [ 0, "=pod\n\n=for ProhibitUnbalancedParens allow next 2\n\nAn ( unclosed\n\nAnd a second [one.\n" ],
                  [ 1, "=pod\n\n=for ProhibitUnbalancedParens allow next 2\n\nAn ( unclosed\n\nAnd a second [one.\n\nBut not ( a third.\n" ],

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
        diag ("wrong violation: ", $_->description,
              "\nline_number=", $_->line_number);
      }
    }
  }
}

exit 0;
