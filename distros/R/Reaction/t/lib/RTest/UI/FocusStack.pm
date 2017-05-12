package RTest::UI::FocusStack;

use base qw/Test::Class/;
use Reaction::Class;
use Reaction::UI::FocusStack;
use aliased "Reaction::UI::ViewPort";
use Test::More ();
use Test::Memory::Cycle;

has 'stack' => (isa => 'Reaction::UI::FocusStack', is => 'rw', set_or_lazy_build('stack'));

sub build_stack {
  return Reaction::UI::FocusStack->new;
}

sub test_stack :Tests {
  my $self = shift;
  my $stack = $self->build_stack;
  my $ctx = bless({}, 'Catalyst');
  Test::More::ok(!$stack->has_loc_prefix, 'No location prefix');
  Test::More::cmp_ok($stack->vp_count, '==', 0, 'Empty viewport stack');
  my $vp = $stack->push_viewport(ViewPort, ctx => $ctx);
  Test::More::is($vp->location, '0', 'New vp has location 0');
  Test::More::cmp_ok($stack->vp_count, '==', 1, 'Viewport count 1');
  Test::More::is($stack->vp_head, $vp, 'Head set ok');
  Test::More::is($stack->vp_tail, $vp, 'Tail set ok');
  my $vp2 = $stack->push_viewport(ViewPort, ctx => $ctx);
  Test::More::is($vp2->location, '1', 'New vp has location 1');
  Test::More::cmp_ok($stack->vp_count, '==', 2, 'Viewport count 2');
  Test::More::is($stack->vp_head, $vp, 'Head set ok');
  Test::More::is($stack->vp_tail, $vp2, 'Tail set ok');
  Test::More::is($vp->inner, $vp2, 'Inner ok on head');
  Test::More::is($vp2->outer, $vp, 'Outer ok on tail');
  Test::More::is($vp->focus_stack, $stack, 'Head focus_stack ok');
  Test::More::is($vp2->focus_stack, $stack, 'Tail focus_stack ok');
  memory_cycle_ok($stack, 'No cycles in the stack');
  my $vp3 = $stack->push_viewport(ViewPort, ctx => $ctx);
  my $vp4 = $stack->push_viewport(ViewPort, ctx => $ctx);
  Test::More::is($stack->vp_tail, $vp4, 'Tail still ok');
  Test::More::cmp_ok($stack->vp_count, '==', 4, 'Count still ok');
  $stack->pop_viewports_to($vp3);
  Test::More::is($stack->vp_tail, $vp2, 'Correct pop to');
  Test::More::cmp_ok($stack->vp_count, '==', 2, 'Count after pop to');
  Test::More::is($stack->vp_head, $vp, 'Head unchanged');
  Test::More::is($stack->vp_tail, $vp2, 'Tail back to vp2');
  my $pop_ret = $stack->pop_viewport;
  Test::More::is($vp2, $pop_ret, 'Correct viewport popped');
  Test::More::is($stack->vp_head, $vp, 'Head unchanged');
  Test::More::is($stack->vp_tail, $vp, 'Tail now head');
  $stack->pop_viewport;
  Test::More::ok(!defined($stack->vp_head), 'Head cleared');
  Test::More::ok(!defined($stack->vp_tail), 'Tail cleared');
  Test::More::cmp_ok($stack->vp_count, '==', 0, 'Count Zero');
}

1;  
