use Test::More;

use Net::Songkick;

SKIP: {
  skip 'Set environment variable SONGKICK_API_KEY for testing', 4
    unless defined $ENV{SONGKICK_API_KEY};

  my $sk = Net::Songkick->new({ api_key => $ENV{SONGKICK_API_KEY} });

  ok($sk, 'Got something');
  isa_ok($sk, 'Net::Songkick');
  is($sk->api_key, $ENV{SONGKICK_API_KEY}, 'Correct api key');
  isa_ok($sk->ua, 'LWP::UserAgent');
}

done_testing;
