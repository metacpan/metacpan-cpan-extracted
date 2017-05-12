BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
use PadWalker;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

our $this_one_shouldnt_be_found;
$this_one_shouldnt_be_found = 12; # quieten warning

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

my $outside_var = 12345;

sub foo {
  my $variable = 23;

  {
     my $hmm = 12;
  }
  #my $hmm = 21;

  my $h = PadWalker::peek_my(0);
  onlyvars(2, $h, qw'$outside_var $variable');

  ${$h->{'$variable'}} = 666;
}

sub bar {
  local ($t, $l, @v) = @_;

  my %x = (1 => 2);
  my $y = 9;

  onlyvars($t, baz($l), @v);
  
  my @z = qw/not yet visible/;
}

sub baz {
  my $baz_var;
  return PadWalker::peek_my(shift);
}

foo();										# test 2

bar(3, 1, qw($outside_var $y %x));						# test 3

&{ my @array=qw(fring thrum); sub {bar(4, 2, qw(@array $outside_var));} };	# test 4

() = sub {1};
my $alot_before;
onlyvars(5, PadWalker::peek_my(0), qw($outside_var $alot_before));		# test 5

my $before;
onlyvars(6, baz(1), qw($outside_var $alot_before $before));			# test 6
my $after;

onlyvars(7, baz(0), qw($baz_var $outside_var));					# test 7

sub quux {
  my %quux_var;
  bar(@_);
}

quux(8, 2, qw($before $alot_before $after $outside_var %quux_var));		# test 8


# Come right out to the file scope (and test eval handling)
my $discriminate1;
eval q{ my $inter; eval q{ my $discriminate2;
 quux(9, 3, qw( $before $alot_before $after $outside_var
    $discriminate1 $discriminate2 $inter));			# test 9
} };

quux(10, 1, qw($outside_var $y %x));						# test 10

tie my $x, "blah", 2;
my $yyy;
onlyvars(11, $x, qw($outside_var $x $yyy
		    $alot_before $before $after $discriminate1));		# test 11
my $too_late;

# This is quite a subtle one: the variable $x is actually FETCHed from inside
# the onlyvars subroutine. The magical scalar is on the stack until line 2 of
# onlyvars. So if we peek back one level from the FETCH, we can see inside
# onlyvars.
tie $x, "blah", 1;
onlyvars(12, $x, qw(@initial));							# test 12

eval q{ PadWalker::peek_my(1) };
print (($@ =~ /^Not nested deeply enough/) ? "ok 13\n" : "not ok 13\n");	# test 13

sub recurse {
  my ($i) = @_;
  if ($i == 0) {
    my $vars = PadWalker::peek_my(2);
    my $val = ${$vars->{'$i'}};
    print ($val eq "2" ? "ok 14\n" : "not ok 14\t# $val\n");
  }
  else {
    recurse($i - 1);
  }
}

recurse(5);									# test 14

eval q{
    my %e;
    onlyvars(15, PadWalker::peek_my(0),
		 qw($outside_var $x $yyy
		    $alot_before $before $after $discriminate1 $too_late %e))
};										# test 15

package blah;

sub TIESCALAR { my ($class, $x)=@_; bless \$x }
sub FETCH     { my $self = shift; return PadWalker::peek_my($$self) }
