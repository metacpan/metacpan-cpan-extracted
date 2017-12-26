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
use Test::More tests => 46;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

require Perl::Critic::Policy::Documentation::RequireLinkedURLs;


#------------------------------------------------------------------------------
my $want_version = 96;
is ($Perl::Critic::Policy::Documentation::RequireLinkedURLs::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::RequireLinkedURLs->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::RequireLinkedURLs->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::RequireLinkedURLs->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
diag "Perl::Critic version ",Perl::Critic->VERSION;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::RequireLinkedURLs$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy RequireLinkedURLs');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  [ 1, "use 5.008;

=begin :hidden

http://perl.org/index.html

=end :hidden
" ],


                  # nested begins
                  [ 1, "use 5.008;

=begin comment

=begin comment

http://perl.org/index.html

=end comment

http://perl.org/index.html

=end comment

http://perl.org/index.html
" ],

                  [ 0, "use 5.008;

=begin comment

http://perl.org/index.html
" ],

                  # wikidoc
                  [ 0, "use 5.008;

=begin wikidoc

[http://perl.org/index.html home]
" ],

                  # empty begin
                  [ 1, "use 5.008;

=begin

http://perl.org/index.html
" ],

                  # html
                  [ 0, "use 5.008;

=begin html

<a href=\"http://perl.org/index.html\">perl home</a>

=end html
" ],
                  [ 0, "use 5.008;

=begin html blahblah blah

<a href=\"http://perl.org/index.html\">perl home</a>

=end html\n" ],

                  # no critic override, but only works if not the last
                  # PPI::Element in the document, or something
                  [ 0,
                    "\n## no critic (RequireLinkedURLs)\n"
                    . "use 5.008;\n"
                    . "\n=pod\n\nhttp://tuxfamily.org\n\n=cut\n\nmore_code()\n" ],

                  # in plain text
                  [ 0, "=pod\n\nhttp://tuxfamily.org\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nhttp://tuxfamily.org\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nC<http://tuxfamily.org>\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nS<C<http://tuxfamily.org>>\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nI<http://tuxfamily.org>\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nC<< http://tuxfamily.org >>\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nC<<< S<<< http://tuxfamily.org >>> >>>\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nZ<>http://tuxfamily.org\n" ],
                  [ 0, "use 5.008;\n\n=pod\n\nL<http://tuxfamily.org>\n" ],

                  # in X<> index
                  [ 1, "use 5.008;\n\n=pod\n\nX<http://tuxfamily.org>\n" ],

                  # other schemas
                  [ 1, "use 5.008;\n\n=pod\n\nnews://localhost/alt.possessive.its.has.no.apostrophe\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nnntp://localhost/alt.possessive.its.has.no.apostrophe\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nhttps://tuxfamily.org\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nftp://tuxfamily.org\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nsftp://tuxfamily.org\n" ],

                  # two adjacent or in sep paras
                  [ 2, "use 5.008;\n=pod\n\nBlah blah http://tuxfamily.org http://www.gnu.org.\n" ],
                  [ 2, "use 5.008;\n=pod\n\nBlah blah http://tuxfamily.org.\n\nBlah blah http://www.gnu.org\n" ],


                  # in =item
                  [ 0, "=item http://tuxfamily.org\n" ],
                  [ 1, "use 5.008;\n\n=item http://tuxfamily.org\n" ],
                  [ 0, "use 5.008;\n\n=item L<http://tuxfamily.org>\n" ],

                  # in verbatim
                  [ 0, "=pod\n\n    http://tuxfamily.org\n" ],
                  [ 0, "=pod\n\n    http://tuxfamily.org\nhttp://gnu.org\n" ],

                  # with display text
                  [ 0, "use 5.008;\n\n=pod\n\nL<display text|http://tuxfamily.org>\n" ],

                  # bogus URLs
                  [ 0, "use 5.008;\n\n=pod\n\nhttp://...\n" ],
                  [ 0, "use 5.008;\n\n=pod\n\nhttp://foo.org\n" ],
                  [ 0, "use 5.008;\n\n=pod\n\nhttp://bar.com\n" ],
                  [ 0, "use 5.008;\n\n=pod\n\nhttp://quux.co.nz\n" ],
                  [ 0, "use 5.008;\n\n=pod\n\nhttp://xyzzy.co.uk\n" ],
                  [ 0, "use 5.008;\n\n=pod\n\nhttp://example.com\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nhttp://not-an-example.com\n" ],
                  [ 1, "use 5.008;\n\n=pod\n\nhttp://not-an-example.com\n" ],

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
