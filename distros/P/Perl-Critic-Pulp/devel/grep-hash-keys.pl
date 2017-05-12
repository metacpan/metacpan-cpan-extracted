#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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


# @foo{1..10} hash slice keys
#

use 5.006;
use strict;
use Getopt::Long;
use Perl::Critic;
use Perl::Critic::Utils;
use Perl::Critic::Violation;

use PPI::Document;
use Perl6::Slurp;
use lib::abs '.';
use MyLocatePerl;

# uncomment this to run the ### lines
#use Smart::Comments;


my %zzz;
my $zzz = {};
my %dup = (
           x => 1,
           ,
           %zzz,
           %$zzz,
           x => 2);


my $verbose = 0;
my $l = MyLocatePerl->new (exclude_t => 1);
my $count;

{
  my $filename = 'devel/grep-hash-keys.pl';
  my $content = eval { Perl6::Slurp::slurp ($filename) } || next;
  file ($filename, $content);
}
{
  while (my ($filename, $content) = $l->next) {
    file ($filename, $content);
  }
  exit 0;
}

{
  my $filename = '/usr/share/perl5/CPAN/Meta/Validator.pm';
  my $content = eval { Perl6::Slurp::slurp ($filename) } || next;
  file ($filename, $content);
  exit 0;
}


sub file {
  my ($filename, $content) = @_;

  if ($verbose) {
    print "$filename\n";
  }

  my $doc = PPI::Document->new (\$content);
  if (! $doc) {
    print "$filename:1: cannot parse: $PPI::Document::errstr\n";
    return;
  }

  $count = 0;
  $doc->find_first (sub {
                      my ($doc, $elem) = @_;
                      examine($elem, $filename);
                      return 0;
                    });
  if ($verbose) {
    print "  looked at $count\n";
  }
}

sub examine {
  my ($elem, $filename) = @_;

  if ($elem->isa('PPI::Structure::Constructor')) {
    return if (substr($elem,0,1) eq '[');

    my $prev = $elem->sprevious_sibling;
    return if ($prev && $prev->isa('PPI::Token::Word') && $prev eq 'do');

  } elsif ($elem->isa('PPI::Structure::List')) {
    my $prev = $elem->sprevious_sibling || return;
    return unless $prev->isa('PPI::Token::Operator') && $prev eq '=';
    ### elem: "$elem"
    $prev = $prev->sprevious_sibling || return;
    while ($prev->isa('PPI::Structure::Subscript')) {
      $prev = $prev->sprevious_sibling || return;
    }
    ### prev: (ref $prev)."  $prev"
    ### symbol: $prev->symbol_type
    return unless ($prev->isa('PPI::Token::Symbol')
                   && $prev->symbol_type eq '%');

  } else {
    return;
  }

  ### examine: (ref $elem)."  $elem"
  $elem = $elem->schild(0) || return;
  if ($elem->isa('PPI::Statement::Expression')) {
    $elem = $elem->schild(0) || return;
  }
  $count++;


  my @nodes = _elem_and_ssiblings ($elem);
  my @arefs = Perl::Critic::Utils::split_nodes_on_comma(@nodes);
  ### @nodes
  ### @arefs

  # ignore empty commas
  @arefs = grep {defined} @arefs;

  my %seen;
  for (;;) {
    my $aref = shift @arefs || return;  # key
    my $value_aref = shift @arefs; # value

    ### key: $aref
    ### value: $value_aref

    $elem = $aref->[0];
    ### key: (ref $elem)."  $elem"

    # %$foo is an even number of things
    if ($elem->isa('PPI::Token::Cast')
        && $elem eq '%') {
      unshift @arefs, $value_aref;
      next;
    }

    my $str;
    if (@$aref == 1) {
      # %foo is an even number of things
      if ($elem->isa('PPI::Token::Symbol')
          && $elem->symbol_type eq '%') {
        unshift @arefs, $value_aref;
        next;
      }

      if ($elem->isa('PPI::Token::Word')) {
        $str = $elem;
      } elsif ($elem->isa('PPI::Token::Quote')) {
        $str = $elem->string;
      }
    }
    ### $str

    if (defined $str && $seen{$str}++) {
      my $linenum = $elem->line_number;
      print "$filename:$linenum: duplicate key $str\n";
    }
  }
}

sub _elem_and_ssiblings {
  my ($elem) = @_;
  my @ret;
  while ($elem) {
    push @ret, $elem;
    $elem = $elem->snext_sibling;
  }
  return @ret;
}

sub elem_is_comma_operator {
  my ($elem) = @_;
  return ($elem->isa('PPI::Token::Operator')
          && $Perl::Critic::Pulp::Utils::COMMA{$elem});
}
exit 0;










    # my $comma = $elem->snext_sibling;
    # if ($comma && ! elem_is_comma_operator($comma)) {
    #   my $linenum = $comma->line_number;
    #   print "$filename:$linenum: stop at unknown comma $comma\n";
    #   return;
    # }
    # 
    # $elem = $comma || return;
    # do {
    #   $elem = $elem->snext_sibling || return;
    #   ### value: (ref $elem)."  $elem"
    # } until (elem_is_comma_operator($elem));
    # $elem = $elem->snext_sibling || return;
