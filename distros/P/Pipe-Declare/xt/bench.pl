#!perl
use 5.014;
use strict;
use warnings;
use Benchmark qw(cmpthese);
use Pipe::Declare;

# Plan §7: validate that a pipe of N bareword steps is within a few %
# of the hand-nested call. The pad-temp threading should fold to almost
# nothing - the peephole optimiser collapses the unused intermediate
# reads.

sub inc    { $_[0] + 1 }
sub double { $_[0] * 2 }
sub neg    { -$_[0]   }
sub sq     { $_[0] * $_[0] }
sub plus10 { $_[0] + 10 }

# --- 3-step bareword pipeline --------------------------------------------

print "\n=== 3-step bareword pipeline ===\n";

my $hand3 = sub { plus10(double(inc($_[0]))) };
my $pipe3 = sub { pipe { ($_[0]) |> inc |> double |> plus10 } };

cmpthese(-2, {
    hand3 => sub { my $r = $hand3->(7); 1 },
    pipe3 => sub { my $r = $pipe3->(7); 1 },
});

# --- 5-step bareword pipeline --------------------------------------------

print "\n=== 5-step bareword pipeline ===\n";

my $hand5 = sub { sq(neg(plus10(double(inc($_[0]))))) };
my $pipe5 = sub { pipe { ($_[0]) |> inc |> double |> plus10 |> neg |> sq } };

cmpthese(-2, {
    hand5 => sub { my $r = $hand5->(7); 1 },
    pipe5 => sub { my $r = $pipe5->(7); 1 },
});

# --- bareword call with args (1 placeholder) -----------------------------

print "\n=== call-with-args step ===\n";

sub clamp { my ($x, $lo, $hi) = @_; $x < $lo ? $lo : $x > $hi ? $hi : $x }

my $hand_args = sub { clamp(double($_[0]), 0, 100) };
my $pipe_args = sub { pipe { ($_[0]) |> double |> clamp(_, 0, 100) } };

cmpthese(-2, {
    hand_args => sub { my $r = $hand_args->(40); 1 },
    pipe_args => sub { my $r = $pipe_args->(40); 1 },
});

# --- a step that uses _ twice --------------------------------------------

print "\n=== two-placeholder step ===\n";

sub pair { $_[0] + $_[1] }

my $hand_two = sub { my $t = inc(inc($_[0])); inc(pair($t, $t)) };
my $pipe_two = sub { pipe { ($_[0]) |> inc |> inc |> pair(_, _) |> inc } };

cmpthese(-2, {
    hand_two => sub { my $r = $hand_two->(3); 1 },
    pipe_two => sub { my $r = $pipe_two->(3); 1 },
});

# --- method chain --------------------------------------------------------

print "\n=== method-chain step ===\n";

package Counter;
sub new { my ($c, $n) = @_; bless { n => $n // 0 }, $c }
sub inc { $_[0]->{n}++; $_[0] }
sub add { my ($s, $x) = @_; $s->{n} += $x; $s }
sub val { $_[0]->{n} }
package main;

my $hand_m = sub {
    my $c = Counter->new(0);
    $c->inc->inc->add(5)->val;
};
my $pipe_m = sub {
    my $c = Counter->new(0);
    pipe { $c |> ->inc |> ->inc |> ->add(5) |> ->val };
};

cmpthese(-2, {
    hand_method => sub { my $r = $hand_m->(); 1 },
    pipe_method => sub { my $r = $pipe_m->(); 1 },
});

# --- block step: map/grep chain ------------------------------------------

print "\n=== map+grep block-step chain (over 100 elements) ===\n";

my @big = (1..100);
my $hand_blk = sub {
    [ grep { $_ > 50 } map { $_ * 2 } @big ];
};
my $pipe_blk = sub {
    pipe { [@big] |> map { $_ * 2 } |> grep { $_ > 50 } };
};

cmpthese(-2, {
    hand_block => sub { my $r = $hand_blk->(); 1 },
    pipe_block => sub { my $r = $pipe_blk->(); 1 },
});

# --- tap step ----------------------------------------------------------------

print "\n=== tap step ===\n";

my $sink = 0;
my $hand_tap = sub { my $t = inc($_[0]); for ($t) { $sink += $_ } inc($t) };
my $pipe_tap = sub { pipe { ($_[0]) |> inc |> tap { $sink += $_ } |> inc } };

cmpthese(-2, {
    hand_tap => sub { my $r = $hand_tap->(3); 1 },
    pipe_tap => sub { my $r = $pipe_tap->(3); 1 },
});

print "\nDone.\n";
