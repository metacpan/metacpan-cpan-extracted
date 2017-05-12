# this generator creates
# comments
# and plain string check expressions:

use Outthentic::DSL;

my $otx = Outthentic::DSL->new(<<'HERE', { debug_mod => 0 });
  foo value
  bar value
HERE

$otx->validate(<<'CHECK');

    generator: <<CODE

      my %d = ( 'foo' => 'foo value', 'bar' => 'bar value' );
      join "\n", map { ( "# $_" , $d{$_} ) } keys %d;

CODE

CHECK

for my $r (@{$otx->results}) {
    print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
}

