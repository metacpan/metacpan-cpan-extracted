use Outthentic::DSL;

my $otx = Outthentic::DSL->new( 'A'x99 , { match_l  => 9 });

$otx->validate('A'x99);

print "status\tcheck\n";
print "==========================\n";

for my $r (@{$otx->results}) {
    print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
}

