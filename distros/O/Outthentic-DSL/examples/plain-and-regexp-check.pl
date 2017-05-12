use Outthentic::DSL;

my $otx = Outthentic::DSL->new(<<'HERE');
  HELLO
  HELLO WORLD
  My birth day is: 1977-04-16
HERE

$otx->validate(<<'CHECK');
  HELLO
  regexp: \d\d\d\d-\d\d-\d\d
CHECK

print "status\tcheck\n";
print "==========================\n";

for my $r (@{$otx->results}) {
    print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
}

