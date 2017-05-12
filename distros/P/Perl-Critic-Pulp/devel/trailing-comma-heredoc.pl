#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

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

use strict;
use PPI::Document;
use PPI::Dumper;

my $whitespace = 1;
sub ppidump {
  my ($str) = @_;
  $str =~ s/\s*$//s;
  $str =~ s/^\s*//s;
  my $document  = PPI::Document->new(\$str)
    or die 'Could not parse code: ', PPI::Document::errstr(), "\n";
  my $dump = PPI::Dumper->new($document,
                              whitespace => $whitespace,
                              locations => 1 );
  $dump->print;
  print "\n";
  print $document->serialize;
  print "\n";
}

ppidump("
foo(<<HERE
123
HERE
);
");

ppidump("
foo(<<HERE);
123
HERE
");

ppidump("
print <<HERE
123
HERE
  ;
");

ppidump("
print <<HERE;
123
HERE
");
