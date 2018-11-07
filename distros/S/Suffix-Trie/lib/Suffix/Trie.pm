#!/usr/bin/env perl

# Native perl Suffix Trie
# Code borrowed and modified from:
# https://rosettacode.org/wiki/Suffix_tree#Perl
# Author: Lee Katz <lkatz@cdc.gov>

package Suffix::Trie;
require 5.12.0;
our $VERSION=0.1;

use strict;
use warnings;

use File::Basename qw/basename fileparse dirname/;
use File::Temp qw/tempdir tempfile/;
use Data::Dumper qw/Dumper/;
use List::MoreUtils qw/uniq/;

use Exporter qw/import/;
our @EXPORT_OK = qw(
                     @fastqExt @fastaExt
           );

our @fastqExt=qw(.fastq.gz .fastq .fq .fq.gz);
our @fastaExt=qw(.fasta .fna .faa .mfa .fas .fa);

# TODO if 'die' is imported by a script, redefine
# sig die in that script as this function.
local $SIG{'__DIE__'} = sub { my $e = $_[0]; $e =~ s/(at [^\s]+? line \d+\.$)/\nStopped $1/; die("$0: ".(caller(1))[3].": ".$e); };

=pod

=head1 NAME

Suffix::Trie

=head1 SYNOPSIS

A module for pure Perl Suffix Trie. Core code taken from https://rosettacode.org/wiki/Suffix_tree#Perl

  use strict;
  use warnings;
  use Data::Dumper;
  use Suffix::Trie;

  my $trie = Suffix::Trie->new("mississippi");
  # Get all substrings into an array reference
  print Dumper $trie->suffixes();
  # Get the actual trie in a hash reference
  print Dumper $trie->trie;

=cut

sub new{
  my($class,$str,$settings)=@_;

  # Initialize the object and then bless it
  my $self={
    str        => $str,
    trie       => undef,
    suffixes   => undef,
  };

  bless($self);

  $self->_create_trie();

  return $self;
}

# Some getters
sub trie{
  my($self)=@_;
  return $self->{trie};
}
sub suffixes{
  my($self)=@_;
  if(defined $self->{suffixes}){
    return $self->{suffixes};
  }

  # recurse into the trie and get all keys
  my @keys;
  _nestedKeys($self->{trie},\@keys);
  @keys = sort {$a cmp $b} uniq(@keys);
  $self->{suffixes} = \@keys;
  return $self->{suffixes};
}
sub _nestedKeys{
  my($hashRef, $keys)=@_;
  $keys //= [];
  for my $key(keys(%$hashRef)){
    push(@$keys, $key);
    _nestedKeys($$hashRef{$key}, $keys);
  }
}

sub _create_trie{
  my($self)=@_;
  my $str = $self->{str};

  # ensure that the string ends in a $
  $str=~s/\$*$/\$/;
  
  # Test for extraneous $
  my $testStr=substr($str, 0, -1); # leaves out the last character
  die "ERROR: found a dollar sign in the string" if($testStr=~/\$/);
  $self->{trie} = _suffix_trie(_suffixHash($str));
}

# https://rosettacode.org/wiki/Suffix_tree#Perl
sub _classify{
  my $h = {};
  for (@_) { push @{$h->{substr($_,0,1)}}, $_ }
  return $h;
}
# https://rosettacode.org/wiki/Suffix_tree#Perl
# TODO expose this function
# TODO return list of strings or hash of strings
sub _suffixHash{
  my $str = shift;
  map { substr $str, $_ } 0 .. length($str) - 1;
}
# https://rosettacode.org/wiki/Suffix_tree#Perl
sub _suffix_trie {
  return +{} if @_ == 0;
  return +{ $_[0] => +{} } if @_ == 1;
  my $h = {};
  my $classif = _classify @_;
  for my $key (keys %$classif) {
    my $subtree = _suffix_trie(
      map { substr $_, 1 } @{$classif->{$key}}
    );
    my @subkeys = keys %$subtree;
    if (@subkeys == 1) {
      my ($subkey) = @subkeys;
      $h->{"$key$subkey"} = $subtree->{$subkey};
    } else { $h->{$key} = $subtree }
  }
  return $h;
}


1;
