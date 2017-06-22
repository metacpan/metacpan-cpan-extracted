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
use Test::More tests => 84;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

require Perl::Critic::Policy::Documentation::RequireFilenameMarkup;


#------------------------------------------------------------------------------
my $want_version = 94;
is ($Perl::Critic::Policy::Documentation::RequireFilenameMarkup::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::RequireFilenameMarkup->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::RequireFilenameMarkup->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::RequireFilenameMarkup->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
diag "Perl::Critic version ",Perl::Critic->VERSION;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::RequireFilenameMarkup$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy RequireFilenameMarkup');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data
  (
   # multiple filenames
   [ 2, "=pod\n\n/usr\n/bin", [ "/usr", "/bin"] ],
   [ 2, "=pod\n\n/usr\t/bin", [ "/usr", "/bin"] ],
   [ 2, "=pod\n\n/usr /bin",  [ "/usr", "/bin"] ],
   [ 2, "=pod\n\n/dev/null\n/var/tmp", ["/dev/null","/var/tmp"] ],
   [ 2, "=pod\n\n/dev/null\t/var/tmp", ["/dev/null","/var/tmp"]  ],
   [ 2, "=pod\n\n/dev/null /var/tmp",  ["/dev/null","/var/tmp"]  ],
   [ 2, "=pod\n\n/tmp\n/dev",  ["/tmp","/dev"] ],

   # ok in verbatim block
   [ 0, "=pod\n\n    verbatim /usr/bin\n" ],

   # L<display text|link target name>
   [ 0, "=pod\n\nL<http://foo.org/index.html>" ],
   [ 0, "=pod\n\nL<displayed text|http://foo.org/index.html>" ],
   [ 1, "=pod\n\nL</usr/games/nethack|http://foo.org/index.html>",
     ["/usr/games/nethack"]  ],
   [ 1, "=pod\n\nL<E<sol>usrE<sol>share|http://foo.org/index.html>",
     ["/usr/share"] ],

   # E<> is bad too
   [ 1, "=pod\n\nE<sol>opt\n", ["/opt"] ],

   # //foo is not a filename, eg. http://dev.foo.org
   # perlcritic -s RequireFilenameMarkup /usr/share/perl5/Moo.pm
   [ 0, "=pod\n\nhttp://dev.perl.org/rfc/257.pod" ],
   [ 0, "=pod\n\nL<http://dev.perl.org/rfc/257.pod>" ],

   [ 1, "=pod\n\n(/usr", ["/usr"] ],
   [ 1, "=pod\n\n(/usr)", ["/usr"] ],
   [ 1, "=pod\n\n/usr)", ["/usr"] ],
   [ 0, "=pod\n\n[/usr" ],
   [ 0, "=pod\n\n{/usr}" ],
   [ 0, "=pod\n\n</usr>" ],

   [ 1, "=pod\n\n/usr", ["/usr"] ],
   [ 1, "=pod\n\n/usr\n", ["/usr"] ],
   [ 1, "=pod\n\nBlah /usr\n", ["/usr"] ],
   [ 1, "=pod\n\n/usr blah\n", ["/usr"] ],
   [ 0, "=pod\n\nF</usr>\n" ],
   [ 0, "=pod\n\nblah/blah/etcetera\n" ],

   [ 1, "=pod\n\n/usr/share", ["/usr/share"] ],
   [ 1, "=pod\n\n/usr/share blah", ["/usr/share"] ],
   [ 1, "=pod\n\nblah /usr/share", ["/usr/share"] ],

   [ 1, "=pod\n\n/bin\n", ["/bin"] ],
   [ 0, "=pod\n\nC</bin>\n" ],
   [ 1, "=pod\n\n/opt\n", ["/opt"] ],
   [ 1, "=pod\n\n/tmp\n", ["/tmp"] ],
   [ 1, "=pod\n\n/dev\n", ["/dev"] ],
   [ 1, "=pod\n\nC:\\\n", ["C:\\"] ],
   [ 1, "=pod\n\nC:\\blah\n", ["C:\\blah"] ],
   [ 1, "=pod\n\nc:\\blah\n", ["c:\\blah"] ],

   [ 0, "=for blah /dev/null\n" ],

   # Z<> is bad too
   [ 1, "=pod\n\n/dev/nullZ<>\n", ["/dev/null"] ],
   [ 1, "=pod\n\nZ<>/dev/null\n", ["/dev/null"] ],

  ) {
  my ($want_count, $str, $filenames) = @$data;
  if ($want_count) {
    unless ($filenames && @$filenames == $want_count) {
      die "Oops, wrong number of filenames in test data: $str";
    }
  } else {
    if (defined $filenames) {
      die "Oops, should be no filenames for want_count=0: $str";
    }
  }
  $str = "$str";

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: '$str'");

  foreach my $i (0 .. $#$filenames) {
    my $want_filename = $filenames->[$i];
    my $violation = $violations[$i];
    my $description = ($violation ? $violation->description : '');
    my $got_filename;
    if ($description =~ /.*\"(.*)\"/) {
      $got_filename = $1;
    }
    is ($got_filename, $want_filename, "description: $description\n" . $str);
  }

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ("violation: ", $_->description,
            "\nline_number=", $_->line_number);
    }
  }
}

exit 0;
