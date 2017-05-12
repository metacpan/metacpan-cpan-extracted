#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scope::Upper qw<yield HERE SCOPE>;

# @_[0 .. $#_] also ought to work, but it sometimes evaluates to nonsense in
# scalar context on perl 5.8.5 and below.

sub list { wantarray ? @_ : $_[$#_] }

my @blocks = (
 [
   'do {',
   '}'
 ],
 [
   '(list map {', # map in scalar context yields the number of elements
   '} 1)'
 ],
 [
   'sub {
     my $next = shift;',
   '}->($next, @_)'
 ],
 [
   'eval {',
   '}'
 ],
);

my @contexts = (
 [ '',        '; ()', 'v' ],
 [ 'scalar(', ')',    's' ],
 [ 'list(',   ')',    'l' ],
);

sub linearize { join ', ', map { defined($_) ? $_ : '(undef)' } @_ }

our @stack;
our @pre;

# Don't put closures in empty pads on 5.6.

my $dummy;
my $capture_outer_pad = "$]" < 5.008 ? "++\$dummy;" : '';

my @test_frames;

for my $block (@blocks) {
 for my $context (@contexts) {
  my $source = <<"FRAME";
   sub {
    my \$next = shift; $capture_outer_pad
    $block->[0]
     unshift \@stack, HERE;
     $context->[0]
      (\@{shift \@pre}, \$next->[0]->(\@_))
     $context->[1]
    $block->[1]
   }
FRAME
  my $code;
  {
   local $@;
   $code = do {
    no warnings 'void';
    eval $source;
   };
   my $err = $@;
   chomp $err;
   die "$err. Source was :\n$source\n" if $@;
  }
  push @test_frames, [ $code, $source, $context->[2] ];
 }
}

my @targets = (
 [ sub {
  my $depth = pop;
  unshift @stack, HERE;
  yield(@_ => $stack[$depth]);
 }, 'target context from HERE' ],
 [ sub {
  my $depth = pop;
  yield(@_ => SCOPE($depth == 0 ? 0 : (2 * ($depth - 1) + 1)));
 }, 'target context from SCOPE' ],
);

my $seed = 0;

for my $args ([ ], [ 'A' ], [ qw<B C> ]) {
 my @args = @$args;
 for my $frame0 (@test_frames) {
  for my $frame1 (@test_frames) {
   for my $frame2 (@test_frames) {
    my $max_depth = 3;
    $seed += 5; # Coprime with $max_depth
    my @prepend;
    for (1 .. $max_depth) {
     ++$seed;
     my $i = $seed + $_;
     my $l = $seed % $max_depth - 1;
     push @prepend, [ $i .. ($i + $l) ];
    }
    my $prepend_str = join ' ', map { '[' . join(' ', @$_) . ']' } @prepend;
    for my $depth (0 .. $max_depth) {
     my $exp = do {
      my @cxts = map $_->[2], $frame0, $frame1, $frame2;
      my @exp  = @args;
      for (my $i = $depth + 1; $i <= $max_depth; ++$i) {
       my $c = $cxts[$max_depth - $i];
       if ($c eq 'v') {
        @exp = ();
       } elsif ($c eq 's') {
        @exp = @exp ? $exp[-1] : undef;
       } else {
        unshift @exp, @{$prepend[$max_depth - $i]};
       }
      }
      linearize @exp;
     };
     for my $target (@targets) {
      local @stack;
      local @pre = @prepend;
      my @res = $frame0->[0]->($frame1, $frame2, $target, @args, $depth);
      my $got = linearize @res;
      if ($got ne $exp) {
       diag <<DIAG;
=== This testcase failed ===
$frame0->[1]
$frame1->[1]
$frame2->[1]
$target->[1]
==== vvvvv Errors vvvvvv ===
DIAG
      }
      is $got, $exp, "yield to depth $depth with args [@args] and prepending $prepend_str";
     }
    }
   }
  }
 }
}
