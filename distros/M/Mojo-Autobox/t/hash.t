use Mojo::Base -strict;

use Mojo::Autobox;

use Test::More;

subtest 'json method' => sub {
  my $json = {key => 'value'}->json;
  like $json, qr/\s*{\s*"key"\s*:\s*"value"\s*}/, 'correct json output'
};

subtest 'j method' => sub {
  my $json = {key => 'value'}->j;
  like $json, qr/\s*{\s*"key"\s*:\s*"value"\s*}/, 'correct json output'
};

done_testing;

