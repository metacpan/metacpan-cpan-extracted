#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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


# /usr /opt /tmp /etc c:\
# exclude NAME section for apropos



use 5.006;
use strict;
use warnings;
use FindBin;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
# use Smart::Comments;


my $verbose = 0;
### verbose on: $verbose=1

sub keep_only_newlines {
  my ($str) = @_;
  $str =~ tr/\n//cd;
  return $str;
}

sub zap_to_first_pod {
  my ($str) = @_;

  if ($str =~ /^=/) {
    return $str;  # starts with pod
  }

  my $pos = index ($str, "\n\n=");
  if ($pos < 0) {
    # no pod at all
    return keep_only_newlines($str);
  }

  my $pre = substr($str,0,$pos);
  my $post = substr($str,$pos);
  return keep_only_newlines($pre) . $post;
}
### zap: zap_to_first_pod("blah\nblah\n\n\n=pod")

sub zap_after_last_pod {
  my ($str) = @_;
  ### zap_after_last_pod: $str

  my $pos;
  my $command = '';
  while ($str =~ /\n\n=([^\n]*)\n?/sg) {
    $command = $1;
    $pos = $+[0];
  }
  ### $pos
  if ($command eq 'cut') {
    return substr($str,0,$pos);
  } else {
    return $str;
  }
}
### zap: zap_to_first_pod("blah\nblah\n\n\n=pod")

sub zap_pod_verbatim {
  my ($str) = @_;
  $str =~ s{((^.+\n)+)}
          {substr($1,0,1) eq ' ' || substr($1,0,1) eq "\t"
            ? keep_only_newlines($1) : $1}mge;
  return $str;
}

sub zap_non_pod {
  my ($str) = @_;
  $str = zap_to_first_pod($str);
  $str = zap_after_last_pod($str);
  $str =~ s{(\n\n=cut.*\n)((.*\n)*)(\n^=)}
    {$1 . keep_only_newlines($2) . $4}emg;
  return $str;
}

sub process_file {
  my ($filename, $str) = @_;
  $str = zap_non_pod($str);
  $str =~ s/[ \t]+$//mg;  # zap trailing whitespace
  $str = zap_pod_verbatim($str);
  ### $str

  while ($str =~ m{((^.+\n)+)}mg) {
    my $para = $1;
    my $pos = $-[0];
    ### $para
    next if $para =~ /^[ \t]/;

    if ($para =~ /\n[ \t]/) {
      $pos += $-[0] + 1;
      my ($linenum, $colnum) = MyStuff::pos_to_line_and_column($str, $pos);
      print "$filename:$linenum:$colnum: indent within plain para\n   ",
        MyStuff::line_at_pos($str, $pos);
    }
  }
}

my $l = MyLocatePerl->new (include_pod => 1,
                           exclude_t => 1,
                            under_directory => '/usr/share/perl5',
                          # under_directory => '/usr/share/perl/5.14.2',
                          );
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }
  process_file ($filename, $str);
  ### exit: exit()
}

exit 0;

=pod

Plain para
Plain para
 with indent

   Verbatim
and/or
   more verbatim


