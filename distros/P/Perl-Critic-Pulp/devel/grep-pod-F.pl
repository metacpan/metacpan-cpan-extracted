#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014 Kevin Ryde

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


# Grep for filenames in POD which don't have F<> or other markup.
#
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

# my $str = File::Slurp::slurp('/down/el/monk-7/scripts/monk-cddb.pl');
# print zap_to_first_pod($str);
# exit 0;

my $l = MyLocatePerl->new (include_pod => 1,
                           exclude_t => 1,
                           # under_directory => '/usr/share/perl5',
                           # under_directory => '/usr/share/perl/5.14.2',
                          );
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }
  process_file ($filename, $str);
  ### exit: exit()
}



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
  while ($str =~ s/\n\n^[ \t].*/\n\n/m) {
  }
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
  $str = zap_pod_verbatim($str);
  ### $str

  {
    while ($str =~ m{(^|[\([:space:]])
                            (
                              /(bin|etc|dev|opt|proc|tmp|usr|var)($|[)[:space:]]|/\S*)
                            |[cC]:\\\S*
                            )
                         }mgx) {
      my $before = $1;
      my $match = $2;
      my $pos = $-[2];
      $match =~ s/[[:space:].,;]+$//;

      my ($linenum, $colnum) = MyStuff::pos_to_line_and_column($str, $pos);
      print "$filename:$linenum:$colnum: \"$match\"\n   ",
        MyStuff::line_at_pos($str, $pos);
    }
    return;
  }

  # if ($str =~ m{/opt}) {
  #   print $str;
  # }
  {
    while ($str =~ m{([CFBIL]<.*?)?
                     ((/usr
                       |(?<!\w)/bin
                       |(?<!\w)/tmp
                       |(?<!\w)/dev/
                       |(?<!\w)/opt # (?!ion)
                         #               |(?<!\w|\))/etc(?!etera)
                       |(?<!\w)[Cc]:\\\w
                       )
                       [^ \t\r\n\f>]*
                     )
                  }ogx) {
      my $markup = $1;
      my $match = $2;
      my $pos = $-[2];
      ### $markup
      if (defined $markup) {
        next unless $markup && $markup =~ />/;
      }
      # next if $match =~ /usr/;
      # next unless $match =~ /dev/;
      # next unless $match =~ /c:/i;
      # next unless $match =~ /tmp/;
      # next unless $match =~ /bin/;
      # next unless $match =~ /opt/;

      my ($linenum, $colnum) = MyStuff::pos_to_line_and_column($str, $pos);
      print "$filename:$linenum:$colnum: $match\n   ",
        MyStuff::line_at_pos($str, $pos);
    }
  }
}

exit 0;

=cut

my $x = '/usr';

=pod

Blah /usr/lib
Blah F</usr/bin/foo>

 verbatim /usr/lib

Common prefixes
to use are /usr/local and /opt/perl.

Under /proc
Under /proc blah.
Blah /tmp as blah.
Blah /tmp/foo.txt as blah.
