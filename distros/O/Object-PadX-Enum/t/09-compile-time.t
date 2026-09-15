#!perl
use v5.22;
use warnings;

use Test2::V0;

use B ();
use Object::PadX::Enum;

my $runtime_var = 5;

enum CtColors {
   item RED  ( v => 10 );
   item BLUE ( v => $runtime_var );
   field $v :param :reader = undef;
}

# Singletons exist as soon as the closing brace has been parsed, so a BEGIN
# block later in the same unit sees them.
my ( $begin_saw_accessor, $begin_ordinal );
BEGIN {
   $begin_saw_accessor = defined &CtColors::RED;
   $begin_ordinal      = CtColors->RED->ordinal;
}
ok( $begin_saw_accessor, 'item accessor exists at BEGIN time after the block' );
is( $begin_ordinal, 0, 'singleton usable at BEGIN time' );

# Item accessors are constant subs: a function-style call compiled after the
# enum folds to a constant, leaving no entersub in the caller's optree.
sub folded_call { return CtColors::RED() }

sub optree_has_entersub {
   my ( $cv ) = @_;
   my @queue = ( B::svref_2object( $cv )->ROOT );
   while ( @queue ) {
      my $op = shift @queue;
      next unless $op and $$op;
      return 1 if $op->name eq 'entersub';
      push @queue, $op->first, $op->sibling if $op->flags & B::OPf_KIDS;
      push @queue, $op->sibling unless $op->flags & B::OPf_KIDS;
   }
   return 0;
}

ok( !optree_has_entersub( \&folded_call ), 'CtColors::RED() call is constant-folded' );
ref_is( folded_call(), CtColors->RED, 'folded constant is the same singleton' );

# Item args are evaluated at compile time; runtime state is not visible.
is( CtColors->BLUE->v, undef, 'item args referencing runtime lexicals see undef' );
is( CtColors->RED->v,  10,    'constant item args work as expected' );

done_testing;
