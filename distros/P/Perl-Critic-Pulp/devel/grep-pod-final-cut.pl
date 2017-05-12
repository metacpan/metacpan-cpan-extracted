#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012, 2014, 2016 Kevin Ryde

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
# /usr/share/perl/5.24/ExtUtils/MM_BeOS.pm
# /usr/share/perl/5.24/IPC/Cmd.pm

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

my $verbose = 1;
my $count_all = 0;
my $count_pod = 0;
my $count_code = 0;
my $count_cut = 0;
my $count_nocut = 0;

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
                            # under_directory => '/usr/share/perl5',
                             under_directory => '/usr/share/perl/5.14/',
                            );
  while (my ($filename, $str) = $l->next) {
    my_grep ($filename, $str);
  }
}

sub last_pod_command {
  my ($str) = @_;
  my $pos = length($str);
  for (;;) {
    $pos = rindex($str, "\n=", $pos-1);
    if ($pos < 0) {
      last;
    }
    pos($str) = $pos + 1;
    if ($str =~ /\G(=[a-z]+)/mg) {
      return ($pos, $1);
    }
    # some "==" or "=>", not a pod directive, keep looking
  }
  if ($str =~ /^(=[a-z]+)/) {
    return (0, $1);
  }
  return;
}

sub my_grep {
  my ($filename, $str) = @_;
  $count_all++;

  my ($podpos, $command) = last_pod_command ($str)
    or return;
  $count_pod++;

  if ($verbose) {
    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $podpos);
    print "$filename:$line: $command\n";
  }

  pos($str) = $podpos;
  my $endpodpos = index ($str, "\n\n", $podpos);
  if ($endpodpos < 0) {
    $endpodpos = length($str);
  }

  if ($command ne '=cut') {
    $count_nocut++;
    return;
  }

  my $trailing = substr($str, $endpodpos);
  if ($trailing =~ /\S/) {
    if ($verbose) { print "  code after pod\n"; }
    # code after pod
    $count_code++;
    return;
  }

  $count_cut++;
}

print "total         $count_all\n";
print "contains pod  $count_pod\n";
print "end non-cut   $count_nocut\n";
print "end with code $count_code\n";
print "end with cut  $count_cut\n";
exit 0;


=pod

__END__
