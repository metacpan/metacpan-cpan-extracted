use strict; use warnings;
use PadWalker;

# All these bugs were reported by Dave Mitchell; he's the first
# person to get his very own test script.

print "1..8\n";

# Does PadWalker work if it's called from a closure?
sub f {
    my $x = shift;
    sub {
        my $t = shift;
        my $x_val = ${PadWalker::peek_my(0)->{'$x'}};
        print ($x_val eq $x ? "ok $t\n" : "not ok $t # $x_val\n");
    }
}

f(6)->(1);

# Even if the sub 'f' has been blown away?
my $f = f('eh?');
undef &f;
$f->(2);

# If there's no reference to the value, we expect to get undef;
# if there is, we expect to get the value.
sub h {
    my $x = my $y = 'fixed';
    sub {
      my $vals = PadWalker::peek_my(0);
      my $x_ref = $vals->{'$x'};
      my $y_ref = $vals->{'$y'};
      
      # There is a difference in behaviour between different versions
      # of Perl here. Since a0d2bbd5c47035a4f7369e4fddd46b502764d86e
      # we don’t see unclosed variables in the pad at all.
      print (!defined($x_ref)||!defined($$x_ref)  ? "ok 3\n" : "not ok 3 # $x_ref\n");
      print (defined($y_ref) ? "ok 4\n" : "not ok 4\n");
      print ($$y_ref eq 'fixed' ? "ok 5\n" : "not ok 5 # $$y_ref\n");
      my $unused = $y;
    }
}
h()->();

# How well do we cope with one variable masking another?

my $x = 1;
sub g {
    my $x = 2;
    my $v_x = ${PadWalker::peek_my(0)->{'$x'}};
    print ($v_x eq 2 ? "ok 6\n" : "not ok 6 # $v_x\n");
}
g();

no warnings 'misc'; # I know it masks an earlier declaration -
                    # that's the whole point!
my $x = 'final value';
my $v_x = ${PadWalker::peek_my(0)->{'$x'}};
print ($v_x eq $x ? "ok 7\n" : "not ok 7 # $v_x\n");

# An 'our' variable should mask a 'my':
our $x;
$x = $x; # Stop old perls from giving 'used only once' warning
print (exists PadWalker::peek_my(0)->{'$x'} ? "not ok 8\n" : "ok 8\n");
