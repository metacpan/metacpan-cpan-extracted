#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2014 Kevin Ryde

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


# various
# some DB<1> debugger prompts

use 5.005;
use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

my $verbose = 0;

my $l = MyLocatePerl->new (include_pod => 1);
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
  my ($self, $text, $linenum, $paraobj) = @_;
  ### verbatim

  while ($text =~ /([IBCLFSXZ]<)/g) {
    my $markup = $1;
    my $filename = $self->{_INFILE};
    print "$filename:$linenum:1: markup in verbatim: $markup\n";
  }
}
sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  return '';
}

exit 0;
