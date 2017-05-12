#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

# /usr/share/perl/5.14.2/pod/perlfaq9.pod
# "How do I find out my hostname, domainname"

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

sub zap_to_first_pod {
  my ($str) = @_;

  if ($str =~ /^=/) {
    return $str;
  }

  my $pos = index ($str, "\n\n=");
  if ($pos < 0) {
    return $str;
  }
  my $pre = substr($str,0,$pos);
  my $post = substr($str,$pos);
  $pre =~ tr/\n//cd;

  ### $pre
  return $pre.$post;
}
### zap: zap_to_first_pod("blah\nblah\n\n\n=pod")

sub zap_pod_verbatim {
  my ($str) = @_;
  $str =~ s/^ .*//mg;
  return $str;
}

my $X_re = qr/X<+([^>]|E<[^>]*>)*?>/;  # $1=contained text

sub grep_X_newline {
  my ($filename, $str) = @_;
  $str = zap_to_first_pod($str);
  $str = zap_pod_verbatim($str);
  ### $str

  while ($str =~ /($X_re)/osg) {
    my $pos = pos($str);
    my $X = $1;
    if ($X =~ /\n/) {
      my ($linenum, $colnum) = MyStuff::pos_to_line_and_column
        ($str, $pos-length($X));
      print "$filename:$linenum:$colnum: $X\n",
        MyStuff::line_at_pos($str, $pos);
    }
  }
}

if (1) {
  require File::Slurp;
  my $filename = "$FindBin::Bin/$FindBin::Script";
  $filename = "$ENV{HOME}/p/path/lib/Math/PlanePath/SquareSpiral.pm";
  $filename = "/usr/share/perl/5.14.2/pod/perltoc.pod";
  my $str = Perl6::Slurp::slurp($filename);
  grep_X_newline ($filename, $str);
  exit 0;
}

my $l = MyLocatePerl->new (include_pod => 1,
                           exclude_t => 1);
while (my ($filename, $str) = $l->next) {
#  next if $filename =~ m{/perltoc\.pod$};
  if ($verbose) { print "look at $filename\n"; }
  grep_X_newline ($filename, $str);
}

exit 0;

#  X<Y

=head1 SEE ALSO

X<Foo,
Bar>,
X<Foo>
