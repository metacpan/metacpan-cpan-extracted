#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012, 2014 Kevin Ryde

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


# Look for __END__ without a pod =cut before it
#
# /usr/share/perl/5.14/ExtUtils/MM_BeOS.pm
# /usr/share/perl/5.14.2/IPC/Cmd.pm

use 5.005;
use strict;
use warnings;
use Perl6::Slurp;
use FindBin;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
use Smart::Comments;

my $verbose = 0;

{
  my $filename = File::Spec->catfile ($FindBin::Bin, $FindBin::Script);
  my $str = Perl6::Slurp::slurp($filename);
  my_grep ($filename, $str);
}
{
  my $filename = '/usr/share/perl/5.14/ExtUtils/MM_BeOS.pm';
  my $str = Perl6::Slurp::slurp($filename);
  my_grep ($filename, $str);
}
{
  my $l = MyLocatePerl->new (exclude_t => 1,
                            under_directory => '/usr/share/perl5');
  while (my ($filename, $str) = $l->next) {
    my_grep ($filename, $str);
  }
}

my $count_all = 0;
my $count_noend = 0;
my $count_cut = 0;

sub my_grep {
  my ($filename, $str) = @_;
  if ($verbose) { print "look at $filename\n"; }

  $count_all++;
  my $endpos = index($str, "\n__END__");
  unless ($endpos >= 0) {
    $count_noend++;
    return;
  }

  my $cmdpos = rindex($str, "\n=", $endpos+1);
  return unless $cmdpos >= 0;
  $cmdpos++;

  my $command = substr($str, $cmdpos, 4);
  if ($command !~ '=[a-z]') {
    # some "==" or "=>", not a pod directive
    return;
  }
  if ($command eq '=cut') {
    $count_cut++;
    return;
  }

  my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $cmdpos);
  print "$filename:$line:$col: __END__ within POD\n    $command\n";
}

print "files $count_all\n";
print "no __END__ $count_noend\n";
exit 0;


=pod

__END__
