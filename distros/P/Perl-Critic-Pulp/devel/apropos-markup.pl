#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Perl::Critic;

use FindBin;
my $progname = $FindBin::Script;

my $filename = "$FindBin::Bin/$FindBin::Script";
print "filename $filename\n";

my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ProhibitBadAproposMarkup');
print "Policies:\n";
foreach my $p ($critic->policies) {
  print "  ",$p->get_short_name,"\n";
}

# "%f:%l:%c:" is good for emacs compilation-mode
Perl::Critic::Violation::set_format ("%f:%l:%c:\n %P\n %m\n %r\n");

foreach my $file ($filename) {
  print "$file\n";
  my @violations;
  if (! eval { @violations = $critic->critique ($file); 1 }) {
    print "Died in \"$file\": $@\n";
    next;
  }
  print @violations;
  if (my $exception = Perl::Critic::Exception::Parse->caught) {
    print "Caught exception in \"$file\": $exception\n";
  }
}
exit 0;

__END__

## no critic (ProhibitBadAproposMarkup)

=pod

blah

=cut

=head1 NAME

Foo - some C<markup> blah

=cut

