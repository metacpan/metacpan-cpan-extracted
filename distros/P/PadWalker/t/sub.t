use strict; use warnings;
use PadWalker 'peek_sub';

print "1..6\n";

my $t = 0;

sub onlyvars {
  my (@initial);
  my ($t, $h, @names) = @_;
  my %names;
  @names{@names} = (1) x @names;
  
  while (my ($n,$v) = each %$h) {
    if (!exists $names{$n}) {
      print "not ok $t\t# Unexpected interloper $n\n";
      return;
    }
    delete $names{$n};
  }
  if (keys %names) {
    print "not ok $t\t# Not found: ", join(', ', keys %names), "\n";
    return;
  }
  print "ok $t\n";
}

onlyvars(++$t, peek_sub(\&onlyvars), qw(@initial $t $h @names %names $n $v));

sub f {
  my $x = shift;
  sub {
    my $y = $x;
  }
}

onlyvars(++$t, peek_sub(f()), qw($x $y));

sub g {
  my $x = shift;
  sub {
    my $y;
  }
}

onlyvars(++$t, peek_sub(g()), qw($y));

my $x = "Hello!";
my $h = peek_sub(sub {my $y = $x});
print (($h->{'$x'} == \$x) ? "ok 4\n" : "not ok 4\n");

# Make sure it correctly signals an exception if the sub is not a Perl sub
eval { no warnings "uninitialized"; peek_sub(undef); };
print (($@ =~ /cv is not a code reference/i) ? "ok 5\n" : "not ok 5\n");

eval { peek_sub(\&peek_sub); };
print (($@ =~ /cv has no padlist/) ? "ok 6\n" : "not ok 6\n");
