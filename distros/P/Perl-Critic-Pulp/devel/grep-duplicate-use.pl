#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

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


# Usage: perl grep-duplicate-use.pl
#

use 5.010;
use strict;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;



my $verbose = 0;
my $l = MyLocatePerl->new (exclude_t => 1,
                            under_directory => '/usr/share/perl5',
                           #  under_directory => '/usr/share/perl/5.14/',
                           # under_directory => "$ENV{HOME}/p/",
                           # under_directory => "/usr/share/perl5/Wx/DemoHints/",
                          );
my $count;

{
  while (my ($filename, $content) = $l->next) {
    file ($filename, $content);
  }
  exit 0;
}

sub file {
  my ($filename, $str) = @_;

  if ($verbose) {
    print "$filename\n";
  }

  # ([A-Za-z0-9_:]*)/mg) {
  # [ \t]*

  my %seen;
  my $package = 'main';
  while ($str =~ /^(__END__)|^(use|no|package)[ \t\r\n]+([^;]*)/mg) {
    last if $1;
    my $type = $2;
    my $module = $3;
    my $pos = pos($str)-length($module);
    $module =~ s/[ \t\r\n]+/ /g;
    $module =~ s/^[ \t\r\n]+//g;
    $module =~ s/[ \t\r\n]+$//g;
    # next if $module eq 'integer'; # pragma

    if ($type eq 'package') {
      $package = $module;
      next;
    }
    if ($type eq 'no') {
      delete $seen{$package}->{$module}; #  = 'pragma';
      next;
    }

    if ($seen{$package}->{$module}) {
      if ($seen{$package}->{$module} eq 'pragma') { next; }

      my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
      print "$filename:$line:$col: (package $package)\n",
        MyStuff::line_at_pos($str, $pos);

    } else {
      $seen{$package}->{$module} = 1;
    }
  }
}

exit 0;
