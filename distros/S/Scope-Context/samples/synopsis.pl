#!perl

use strict;
use warnings;

use blib;

use Scope::Context;

local $" = ', ';

for my $run (1 .. 2) {
 my @values = sub {
  local $@;

  eval {
   # Create Scope::Context objects for different upper frames :
   my ($block, $eval, $sub, $loop);
   {
    $block = Scope::Context->new;
    $eval  = $block->eval;   # == $block->up
    $sub   = $block->sub;    # == $block->up(2)
    $loop  = $sub->up;       # == $block->up(3)
   }

   eval {
    # This throws an exception, since $block has expired :
    $block->localize('$x' => 1);
   };
   print "Caught an error at run $run: $@" if $@;

   # This will print "End of eval scope..." when the current eval block ends :
   $eval->reap(sub { print "End of eval scope at run $run\n" });

   # Ignore warnings just for the loop body :
   $loop->localize_elem('%SIG', __WARN__ => sub { });
   # But for now they are still processed :
   warn "This is a warning at run $run\n";

   # Execute the callback as if it ran in place of the sub :
   my @values = $sub->uplevel(sub {
    return @_, 2;
   }, 1);
   print "After uplevel, \@values contains (@values) at run $run\n";

   # Immediately return (1, 2, 3) from the sub, bypassing the eval :
   $sub->unwind(@values, 3);

   # Not reached.
   return 'XXX';
  };

  # Not reached.
  die $@ if $@;
 }->();

 print "Values returned at run $run: (@values)\n";

 # warnings are ignored, so this will be completely silent.
 warn "You will not see this at run $run\n";
}

warn "Warnings have been restored\n";
