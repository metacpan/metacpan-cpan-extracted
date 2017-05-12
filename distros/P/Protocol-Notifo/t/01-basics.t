#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use Protocol::Notifo;
use File::HomeDir;
use File::Spec::Functions 'catfile';
use MIME::Base64 'decode_base64';

my $n;
lives_ok
  sub { $n = Protocol::Notifo->new(user => 'me', api_key => 'my_key') },
  'new() survived with a prodigal object';
ok(defined($n), '... which, by the way, looks defined');
isa_ok($n, 'Protocol::Notifo', '... and even of the proper type');

is($n->{user},    'me',     '... good user in there');
is($n->{api_key}, 'my_key', '... and a nice little API key');

is($n->{base_url}, 'https://api.notifo.com/v1',
  'The API endpoint is alright');
is(decode_base64($n->{auth_hdr}),
  'me:my_key', '... and the authorization header is perfect');
isnt(substr($n->{auth_hdr}, -1), "\n", '... without a newline at the end');

is(
  $n->config_file,
  catfile(File::HomeDir->my_home, '.notifo.rc'),
  'Use home_dir config file'
);


### Config files
my @test_cases = (
  [ 't/data/cfg1.rc',
    { api_key  => "key1",
      auth_hdr => "dXNlcjE6a2V5MQ==",
      base_url => "https://api.notifo.com/v1",
      user     => "user1"
    }
  ],
  [ 't/data/cfg2.rc',
    { api_key  => "key2",
      auth_hdr => "dXNlcjI6a2V5Mg==",
      base_url => "https://api.notifo.com/v1",
      user     => "user2"
    }
  ]
);

for my $tc (@test_cases) {
  my ($cfg, $attr) = @$tc;

  local $ENV{NOTIFO_CFG} = $cfg;
  lives_ok sub { $n = Protocol::Notifo->new }, "Build object ok with '$cfg'";
  cmp_deeply({%$n}, $attr, '... with the expected attrs');
  is($n->config_file, $cfg, '... and it used the expected cfg file');
}


### Bad boys
subtest 'bad usage of new()', sub {
  throws_ok sub { local $ENV{HOME} = 't'; Protocol::Notifo->new },
    qr/Missing required parameter 'user' to new[(][)], /,
    'new() with missing user, expected exception';

  throws_ok sub { local $ENV{HOME} = 't'; Protocol::Notifo->new(user => 'me') },
    qr/Missing required parameter 'api_key' to new[(][)], /,
    'new() with missing api_key, expected exception';

  throws_ok
    sub { local $ENV{NOTIFO_CFG} = 't/data/bad_cfg.rc'; Protocol::Notifo->new },
    qr/Could not parse line 1/, 'Bad cfg file croaks';
};

done_testing();
