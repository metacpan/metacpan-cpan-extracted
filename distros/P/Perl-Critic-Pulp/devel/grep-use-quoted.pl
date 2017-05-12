#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


# Look for "use" statements with quoted version numbers, like
#
#    use Foo '1.5';
#

use 5.006;
use strict;
use warnings;
use Perl6::Slurp;

my @files = ($0, split /\n/, `locate \\*.t \\*.pm \\*.pl`);

print scalar(@files),"\n";
foreach my $filename (@files) {
  my $str = eval { Perl6::Slurp::slurp ($filename) }
    || do { # print "Cannot read $filename: $!\n";
      next;
    };

  while ($str =~ /((use|no)[ \t]+
                    [A-Za-z0-9_:]+[ \t]+
                    (['"]|qq?.?])
                    (v?[0-9][0-9._e]*)
                    ['"}][ \t]*
                    ;.*

                    # [^-a-zA-Z.$:][^\n]*
                  )/gx) {
    my $line = $1;
    my $pos = pos($str);
    # $3 =~ /[0-9]/ or next; # not '..' for use lib etc
    my $tmp = substr ($str, 0, $pos);
    my $count = ($tmp =~ tr/\n//) + 1;
    print "$filename:$count:1:  $line\n";
  }
}

__END__

use foo '123';
use Foo::Bar '123';
{ no Foo::Bar '123'; }
use foo 'v1.5';
