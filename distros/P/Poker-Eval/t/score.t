use Test::More;
use Poker::Score::High;
use Poker::Dealer;

# Create highball score object
my $scorer = Poker::Score::High->new;

# Create dealer, shuffle deck and deal out five cards
my $dealer = Poker::Dealer->new;
my $cards1 = $dealer->deal_named(['2s', '5h', '2c', '2h', 'Ah' ]);
my $cards2 = $dealer->deal_named(['As', '2d', '3c', '4h', '5d' ]);
my $cards3 = $dealer->deal_named(['8s', '5s', 'Ks', '3s', 'Js' ]);

# Numerical score of five card poker hand
my $score1 = $scorer->score($cards1);
my $score2 = $scorer->score($cards2);
my $score3 = $scorer->score($cards3);

plan tests => 6;

is($score1, 5052, 'Three-of-a-Kind scored');
is($scorer->hand_name($score1), 'Three-of-a-Kind', 'Three-of-a-Kind identified');
is($score2, 5853, 'Straight scored');
is($scorer->hand_name($score2), 'a Straight', 'Straight identified');
is($score3, 6468, 'Flush scored');
is($scorer->hand_name($score3), 'a Flush', 'Flush identified');

done_testing();
