# Copyright 2014, 2015 Kevin Ryde

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


# Look for perl files with #!perl 

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
                           # under_directory => '/usr/share/perl5',
                           #  under_directory => '/usr/share/perl/5.14/',
                           # under_directory => "$ENV{HOME}/p/",
                           # under_directory => "/usr/share/perl5/Wx/DemoHints/",
                           # under_directory => '/usr/share/doc',
                          );
my $count;

{
  while (my ($filename, $content) = $l->next) {
    file ($filename, $content);
  }
}

sub file {
  my ($filename, $str) = @_;

  if ($verbose) {
    print "$filename\n";
  }

  if (-x $filename
      && $str =~ /^(#!perl.*)/) {
    my $shebang = $1;

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, 0);
    print "$filename:1:1: $shebang\n",
  }
}

exit 0;
