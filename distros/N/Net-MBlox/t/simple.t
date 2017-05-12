use Test::More skip_all => "Requires token";

BEGIN { use_ok( 'Net::MBlox' ) }

my $mb = Net::MBlox->new(
  consumer_key => $ENV{MBLOX_CONSUMER_KEY},
  consumer_secret => $ENV{MBLOX_CONSUMER_SECRET},
  app_id =>  $ENV{MBLOX_APP_ID}
);

my $res = $mb->query('POST', 'sms/outbound/messages', {
  message => "Test SMS",
  destination => 44,
  originator => 44,
});

warn $res->code;

done_testing();
