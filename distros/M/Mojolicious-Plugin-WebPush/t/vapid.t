use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Mojo::File qw(curfile);
use lib curfile->sibling('lib')->to_string;
use TestUtils qw(webpush_config $SUB $PUBKEY_B64);
use MIME::Base64 qw(encode_base64url decode_base64url);
use Mojo::JSON qw(decode_json);

plugin 'ServiceWorker';
plugin 'WebPush' => webpush_config();

# modified port of github.com/web-push-libs/vapid/py_vapid tests

my $t = Test::Mojo->new;
my $ENDPOINT = 'https://updates.push.services.mozilla.com';
subtest 'sign RFC8292' => sub {
  my $result = app->webpush->authorization({endpoint => "$ENDPOINT/push"});
  ok $result =~ qr/^vapid t=(.*),k=(.*)$/;
  my ($t, $k) = ($1, $2);
  my $t_val = decode_json decode_base64url((split /\./, $t)[1]);
  is_deeply $t_val, { aud => $ENDPOINT, sub => $SUB, exp => $t_val->{exp} };
  is $k, $PUBKEY_B64;
  ok app->webpush->verify_token($result);
};

subtest 'verify RFC8292' => sub {
  my $key = "BDd3_hVL9fZi9Ybo2UUzA284WG5FZR30_95YeZJsiApwXKpNcF1rRPF3foI".
         "iBHXRdJI2Qhumhf6_LFTeZaNndIo";
  my $auth = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9.eyJhdWQiOiJod".
          "HRwczovL3VwZGF0ZXMucHVzaC5zZXJ2aWNlcy5tb3ppbGxhLmNvbSIsImV".
          "4cCI6MTQ5NDY3MTQ3MCwic3ViIjoibWFpbHRvOnNpbXBsZS1wdXNoLWRlb".
          "W9AZ2F1bnRmYWNlLmNvLnVrIn0.LqPi86T-HJ71TXHAYFptZEHD7Wlfjcc".
          "4u5jYZ17WpqOlqDcW-5Wtx3x1OgYX19alhJ9oLumlS2VzEvNioZolQA";
  ok app->webpush->verify_token("vapid t=$auth,k=$key");
  $auth =~ s/.{4}$/_BAD/;
  ok !app->webpush->verify_token("vapid t=$auth,k=$key");
};

done_testing;
