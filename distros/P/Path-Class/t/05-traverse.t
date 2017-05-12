#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use Test::More;
use File::Temp qw(tempdir);

plan tests => 4;

use_ok 'Path::Class';

my $cwd = getcwd;
my $tmp = dir(tempdir(CLEANUP => 1));

# Test recursive iteration through the following structure:
#     a
#    / \
#   b   c
#  / \   \
# d   e   f
#    / \   \
#   g   h   i
(my $abe = $tmp->subdir(qw(a b e)))->mkpath;
(my $acf = $tmp->subdir(qw(a c f)))->mkpath;
$acf->file('i')->touch;
$abe->file('h')->touch;
$abe->file('g')->touch;
$tmp->file(qw(a b d))->touch;

my $a = $tmp->subdir('a');

my $nnodes = $a->traverse(sub {
  my ($child, $cont) = @_;
  return sum($cont->(), 1);
});
is($nnodes, 9);

my $ndirs = $a->traverse(sub {
  my ($child, $cont) = @_;
  return sum($cont->(), ($child->is_dir ? 1 : 0));
});
is($ndirs, 5);

my $max_depth = $a->traverse(sub {
  my ($child, $cont, $depth) = @_;
  return max($cont->($depth + 1), $depth);
}, 0);
is($max_depth, 3);

sub sum { my $total = 0; $total += $_ for @_; $total }
sub max { my $max = 0; for (@_) { $max = $_ if $_ > $max } $max }
