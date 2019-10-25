use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojolicious::Lite;
use Mojo::Util ();

throws_ok { plugin BcryptSecure => { cost => undef } } qr/cost must be a positive int <= 99/, 'undef cost throws';

throws_ok { plugin BcryptSecure => { cost => [] } } qr/cost must be a positive int <= 99/, 'array ref cost throws';

throws_ok { plugin BcryptSecure => { cost => 0 } } qr/cost must be a positive int <= 99/, '0 cost throws';

throws_ok { plugin BcryptSecure => { cost => -1 } } qr/cost must be a positive int <= 99/, '-1 cost throws';

throws_ok { plugin BcryptSecure => { cost => '' } } qr/cost must be a positive int <= 99/, 'empty string cost throws';

throws_ok { plugin BcryptSecure => { cost => 'string' } } qr/cost must be a positive int <= 99/, 'string cost throws';

throws_ok { plugin BcryptSecure => { cost => 100 } } qr/cost must be a positive int <= 99/, '100 cost throws';

my $key_value_dump = Mojo::Util::dumper { unknown_key => 'unknown value' };
throws_ok { plugin BcryptSecure => { unknown_key => 'unknown value' } } qr{Unknown keys/values provided: \Q$key_value_dump\E}, 'unknown key and value throw';

throws_ok { plugin BcryptSecure => { cost => 8, unknown_key => 'unknown value' } } qr{Unknown keys/values provided: \Q$key_value_dump\E}, 'unknown key and value with known key (cost) throw';

lives_ok { plugin 'BcryptSecure' } 'no config lives';

lives_ok { plugin BcryptSecure => { cost => 1 } } 'cost 1 lives';

lives_ok { plugin BcryptSecure => { cost => 99 } } 'cost 99 lives';

done_testing;
