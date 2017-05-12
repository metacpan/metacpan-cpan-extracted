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


# Churn ProhibitPOSIXimport over all .pm files.

use 5.006;
use strict;
use warnings;
use Getopt::Long;
use Perl::Critic;
use Perl::Critic::Utils;
use Perl::Critic::Violation;

use Perl6::Slurp;
use Iterator::Simple qw(igrep);
use Iterator::Simple::Locate;
use lib::abs '.';
use MyUniqByMD5;

my $it = Iterator::Simple::Locate->new (globs => [ '*.pm' ]);
{
  my $uniq = MyUniqByMD5->new;
  $it = igrep { $uniq->uniq_file($_) } $it;
}

my $critic = Perl::Critic->new ('-profile' => '',
                                '-single-policy' => 'ProhibitPOSIXimport');
print "Policies:\n";
foreach my $p ($critic->policies) {
  print "  ",$p->get_short_name,"\n";
}

# "%f:%l:%c:" is good for emacs compilation-mode
Perl::Critic::Violation::set_format ("%f:%l:%c:\n %P\n %m\n %r\n");

while (my $filename = $it->next) {
  my $content = eval { Perl6::Slurp::slurp ($filename) } || next;
  ($content =~ /^(use POSIX.*)/m) || next;
  print "\n$filename\n$1\n";

  my @violations;
  if (! eval { @violations = $critic->critique ($filename); 1 }) {
    print "Died in \"$filename\": $@\n";
    next;
  }
  print @violations;
  if (my $exception = Perl::Critic::Exception::Parse->caught) {
    print "Caught exception in \"$filename\": $exception\n";
  }
}

exit 0;


# $it = igrep {filename_has_use_posix($_)} $it;
# sub filename_has_use_posix {
#   my ($filename) = @_;
#   my $content = do { Perl6::Slurp::slurp ($filename) } || return 0;
#   return ($content =~ /^use POSIX.*/m)
# }
