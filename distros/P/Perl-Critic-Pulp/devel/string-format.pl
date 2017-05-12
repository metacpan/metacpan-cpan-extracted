#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2017 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use Devel::StackTrace;
use Perl::Critic;
$|=1;

my $critic = Perl::Critic->new;
#  (-verbose => "%f:%l:%c:\n %P\n %m\n %r\n");
# '-profile' => '',
#  '-single-policy' => 'ProhibitBadAproposMarkup');

# print "Policies:\n";
# foreach my $p ($critic->policies) {
#   print "  ",$p->get_short_name,"\n";
# }

my $filename = '../r5/tools/MyR5Dragon.pm';
$filename = '/tmp/x.pl';
$filename = '/so/pc/bug-string-format/foo.pl';
my @violations;

print "critique:\n";
@violations = $critic->critique ($filename);

$SIG{__WARN__} = sub {
  print "---------\n";
  print @_;
  print Devel::StackTrace->new->as_string;
  print "---------\n";
};

print "violations:\n";
Perl::Critic::Violation::set_format("%f:%l:%c:\n %P\n %m\n %r\n");
foreach my $violation (@violations) {
  print $violation;
  print "source: ",$violation->source//'[undef]',"\n";
}

if (my $exception = Perl::Critic::Exception::Parse->caught) {
  print "Caught exception in \"$filename\": $exception\n";
}
