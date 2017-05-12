## Test output when there is only 1 state for all events in the sequence

use Test::More tests => 24;
use Statistics::Sequences::Runs;
my @ari = ();
my ($observed, $expected, $variance, $z_value, $p_value, $p_exact) = ();
my $runs = Statistics::Sequences::Runs->new();
for (1 .. 3) {
    $runs->load(data => [@ari]);
    if (! scalar @ari) {
        $observed = 0;
    }
    else {
        $observed = 1;
        $expected = 1;
        $variance = 0;
        $p_exact = 1; 
        $p_value = 1;
        # zed remains undef
    }
    #diag("\nLength of sequence = ". scalar @ari);
    my $observed_got = $runs->observed();
    ok( equal($observed_got, $observed), "Wrong observed value: got <$observed_got> not <$observed>");
    #diag("observed = $observed_got");
    
    my @freqs = $runs->observed_per_state();
    ok( equal($freqs[0], $observed), "Wrong observed value: got <$freqs[0]> not <$observed>");
    #diag("ops:\t", join("\t", @freqs, "\n"));
    
    #my $freqh = $runs->observed_per_state();
    #while (my($key, $val) = each %{$freqh}) {
        #diag("href state $key = $val");
    #}
    
    my $expected_got = $runs->expected();
    ok( equal($expected_got, $expected), "Wrong expected value: got <$expected_got> not <$expected>");
    
    my $variance_got = $runs->variance();
    ok( equal($variance_got, $variance), "Wrong variance value: got <$variance_got> not <$variance>");
    
    my $z_value_got = $runs->z_value();
    ok( equal($z_value_got, $z_value), "Wrong z_value: got <$z_value_got> not <$z_value>");
    #diag("\tz_value = $z_value_got");
    
    my $p_value_got = $runs->p_value(exact => 0);
    ok( equal($p_value_got, $p_value), "Wrong p_value: got <$p_value_got> not <$p_value>");
    #diag("\tp_value = $p_value_got");
    
    my $p_exact_got = $runs->p_value(exact => 1);
    ok( equal($p_exact_got, $p_exact), "Wrong p_exact: got <$p_exact_got> not <$p_exact>");
    #diag("\tp_exact = $p_exact_got");

    my @frq = $runs->bi_frequency();
    ok(equal($frq[0], scalar @ari), "element 0 frequency: observed = $frq[0]");

    push @ari, 0;
    
}
 
$runs->stats_hash(data => [@ari],values =>
  {
   observed => 1,
   expected => 1,
   variance => 1,
   z_value => 1,
   p_value => 1,
  },
  precision_s => 7,
  precision_p => 5,   # for p_value
  flag  => 1,    # for p_value
  exact => 1,    # for p_value
  ccorr => 1 # for z_value
 );

sub equal {
    return 1 if (! defined $_[0] && ! defined $_[1]) || ( ! length $_[0] && ! length $_[1] );
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] == $_[1];
    return 0;
}
1;