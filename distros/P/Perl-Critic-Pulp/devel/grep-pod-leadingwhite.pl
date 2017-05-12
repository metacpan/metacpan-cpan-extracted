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

use strict;
use warnings;
use Perl6::Slurp;
use FindBin;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;


my $verbose = 0;

my $p = MyParser->new;
my $count = 0;
my $filename;

{
  $filename = File::Spec->catfile ($FindBin::Bin, $FindBin::Script);
  my $str = Perl6::Slurp::slurp($filename);
  my_grep ($filename, $str);
}
{
  my $l = MyLocatePerl->new (include_pod => 1,
                             exclude_t => 1);
  while (($filename, my $str) = $l->next) {
    my_grep ($filename, $str);
  }
}

sub my_grep {
  my ($filename, $str) = @_;
  if ($verbose) { print "parse $filename\n"; }
  $p->parse_from_string ($str, $filename);
}
print "total $count\n";

exit 0;

package MyParser;
use base 'Perl::Critic::Pulp::PodParser';

sub begin_pod {
  my ($self) = @_;
  $self->{'in_begin'} = 0;
}
sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  ### command: $command
  ### $text

  $self->{'in_begin'} = ($command eq 'begin');
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### $text

  return if $self->{'in_begin'};

  while ($text =~ m{^\s+(?!$)}mg) {
    my $pos = pos($text);
    my ($line_offset, $col) = MyStuff::pos_to_line_and_column ($text, $pos);
    $linenum += $line_offset - 1;

    print "$filename:$linenum:$col: leading whitespace in text para\n",
      MyStuff::line_at_pos($text, $pos);
    $count++;
  }
  return '';
}

=pod

=head1 HELLO

Blah fjdks fjksd jfksd fjkds jfksd jfksd jfksd jfksd jfks dfjks djkf sdjkf
sdkjf sdkf jsdk fjskd fjksd
   blah

Blah fjdks fjksd jfksd fjkds jfksd jfksd jfksd jfksd jfks dfjks djkf sdjkf
