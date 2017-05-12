use Outthentic::DSL;

my $otx = Outthentic::DSL->new('HELLO');

$otx->validate(<<'CHECK');
  generator: [ 'H', 'E', 'L', 'O' ];
CHECK

for my $r (@{$otx->results}) {
    print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
}

