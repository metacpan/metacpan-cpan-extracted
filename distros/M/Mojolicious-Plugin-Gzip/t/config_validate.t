use strict;
use Test::More;
use Test::Exception;
use Mojolicious::Lite;

throws_ok { plugin Gzip => [] } qr/config must be a hash reference/, 'arrayref config throws';

throws_ok { plugin Gzip => { invalid_key => 'invalid' } } qr/invalid key passed to Mojolicious::Plugin::Gzip \(only min_size is allowed\)/, 'invalid key throws';
throws_ok { plugin Gzip => { min_size => 860, invalid_key => 'invalid' } } qr/invalid key passed to Mojolicious::Plugin::Gzip \(only min_size is allowed\)/, 'invalid key with valid key throws';

throws_ok { plugin Gzip => { min_size => undef } } qr/min_size must be a positive integer/, 'undef min_size throws';
throws_ok { plugin Gzip => { min_size => '' } } qr/min_size must be a positive integer/, 'empty string min_size throws';
throws_ok { plugin Gzip => { min_size => 'invalid' } } qr/min_size must be a positive integer/, 'string min_size throws';
throws_ok { plugin Gzip => { min_size => -1 } } qr/min_size must be a positive integer/, 'negative int min_size throws';
throws_ok { plugin Gzip => { min_size => 0 } } qr/min_size must be a positive integer/, 'zero int min_size throws';
throws_ok { plugin Gzip => { min_size => 1.3 } } qr/min_size must be a positive integer/, 'positive float min_size throws';

lives_ok { plugin Gzip => { min_size => 1 } } 'positive one min_size lives';
lives_ok { plugin Gzip => { min_size => 2 } } 'positive two min_size lives';
lives_ok { plugin Gzip => { min_size => 3 } } 'positive two min_size lives';

lives_ok { plugin Gzip => { } } 'empty hash config lives';
lives_ok { plugin 'Gzip' } 'no config lives';

done_testing;
