use Outthentic::DSL;

my $otx = Outthentic::DSL->new(<<'HERE');
  2001-01-02
  Name: Outthentic
  App Version Number: 1.1.10
HERE

$otx->validate(<<'CHECK');
  regexp: \d\d\d\d-\d\d-\d\d # date in format of YYYY-MM-DD
  regexp: Name:\s+\w+ # name
  regexp: App Version Number:\s+\d+\.\d+\.\d+ # version number
CHECK

for my $r (@{$otx->results}) {
    print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
}

