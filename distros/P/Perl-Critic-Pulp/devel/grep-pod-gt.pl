#!/usr/bin/perl -w

# Copyright 2009, 2010, 2013, 2014 Kevin Ryde

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


# /usr/share/perl/5.10.1/Dumpvalue.pm            ->
# /usr/share/perl/5.10.1/Test/Builder/Tester.pm  C<<Test>>

use 5.005;
use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new (under_directory => '/usr/share/perl5',
                           # under_directory => '/usr/share/perl/5.14/',
                          );
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  if ($str =~ /^__END__/m) {
    substr ($str, $-[0], length($str), '');
  }

  my $parser = MyParser->new;
  $parser->errorsub(sub{1}); # no error prints
  $parser->parse_from_string ($str, $filename);
}

package MyParser;
use strict;
use warnings;
use base 'Pod::Parser';

sub parse_from_string {
  my ($self, $str, $filename) = @_;

  require IO::String;
  my $fh = IO::String->new ($str);
  $self->{_INFILE} = $filename;
  return $self->parse_from_filehandle ($fh);
}

sub command {
  return '';
}
sub verbatim {
  return '';
}
sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock

  #   while ($text =~ /->[^[:space:]]/g) {
  #     my $pos = pos($text);
  #     my ($line, $col) = MyStuff::pos_to_line_and_column ($text, $pos);
  #     $line += $linenum - 1;
  #
  #     my $filename = $self->{_INFILE};
  #     print "$filename:$line:$col: bad -> markup\n",
  #       MyStuff::line_at_pos($text, $pos);
  #   }
  #   return '';

  my $tree = $self->parse_text ($text, $linenum);

  my @pending = reverse $tree->children;
  my $prev = '';
  my $next = '';
  for ( ; @pending; $prev = $next) {
    $next = pop @pending;
    if (ref $next && $next->isa('Pod::ParseTree')) {
      push @pending, reverse $next->children;
      next;
    }
    next if ref $next;

    {
      while ($next =~ /([IBCLFSX]<<+[^ \n])/g) {
        my $bad = $1;
        my $filename = $self->output_file;
        print "$filename:$linenum:1: no space after << markup\n$bad\n";
      }
    }

    {
      ref $prev or next;
      $prev->isa('Pod::InteriorSequence') or next;
      my $prev_text = $prev->raw_text;

      $prev_text =~ /->$/ or next;
      $next =~ /^[_[:alpha:]]/ or next;

      my ($filename, $line) = $prev->file_line;

      my $pos = length($prev_text);
      my ($offset_line, $col)
        = MyStuff::pos_to_line_and_column ($prev_text, $pos);
      $line += $offset_line - 1;
      $col = 1; # col not right if $prev not at start of line

      my $str = $prev_text . $next;
      print "$filename:$line:$col: probable unescaped -> markup\n",
        MyStuff::line_at_pos($str, $pos);

      print "prev ",$prev_text,"\n";
      print "next ",$next,"\n";
    }
  }

  return '';
}

exit 0;
