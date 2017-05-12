#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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


=pod

C<foo>>

Foo <F<foo@bar.org>>

CE<lt>>

C<<k>>

=cut

use 5.005;
use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
# use Smart::Comments;

my $verbose = 0;

{
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
    my ($self, $command, $text, $linenum) = @_;
    if ($command eq 'begin') {
      $self->{'in_begin'} = $text;
    }
    if ($command eq 'end') {
      $self->{'in_begin'} = '';
    }
    $self->textblock($text, $linenum);
    return '';
  }
  sub verbatim {
    return '';
  }
  sub textblock {
    my ($self, $text, $linenum, $paraobj) = @_;
    ### textblock(): $text

    if ($self->{'in_begin'} eq 'html') {
      return '';
    }

    my $tree = $self->parse_text ($text, $linenum);

    my @pending = reverse $tree->children;
    my $prev = 'text';
    while (@pending) {
      ### $prev
      my $elem = pop @pending;
      if (ref $elem && $elem->isa('Pod::ParseTree')) {
        push @pending, reverse $elem->children;
        next;
      }

      if (ref $elem) {
        ### obj: ref $elem
        $prev = $elem->cmd_name;
        (undef, $linenum) = $elem->file_line;
      } else {
        ### text: $elem
        if (($elem =~ /^(>)/ && $prev ne 'text')
            || ($elem =~ /^(<)/ && $prev ne 'text' && $prev ne 'Z')) {
          print "$self->{'filename'}:$linenum: $prev $1\n";
        }
        if (length($elem)) {
          $prev = 'text';
        }
      }
    }
    return '';
  }
}


my $l = MyLocatePerl->new (under_directory => '/usr/share/perl5',
                           # under_directory => '/usr/share/perl/5.14/',
                           include_pod => 1,
                          );
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  my $parser = MyParser->new;
  $parser->{'filename'} = $filename;
  $parser->{'str'} = $str;
  $parser->{'in_begin'} = '';
  $parser->parse_from_string($str);
}

exit 0;
