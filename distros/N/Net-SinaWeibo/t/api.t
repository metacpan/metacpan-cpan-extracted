use strict;
use warnings;
use 5.010;
use Data::Dumper;
use Net::SinaWeibo;
use Test::More;

plan skip_all => 'Enviroment vars: SINA_APP_KEY / SINA_APP_SECRET not set!'
    unless $ENV{SINA_APP_KEY} && $ENV{SINA_APP_SECRET};

plan skip_all  => '00oauth.t not passed!' unless -e 't/test.tokens';

# my %tokens = Net::SinaWeibo->load_tokens('t/test.tokens');
# my $sina = Net::SinaWeibo->new(
#     app_key => $tokens{app_key},
#     app_secret => $tokens{app_secret},
#     tokens => {
#         access_token => $tokens{_access_token},
#         access_token_secret => $tokens{_access_token_secret},
#     },
#     );
# my $ok = $sina->public_timeline;
# my $ok = $sina->hot_users(category => 'tech');
# my $ok = $sina->verify_credentials;
# my $ok = $sina->rate_limit_status;
# my $ok = $sina->update_profile(description => 'Hello,update from api!');
# my $ok = $sina->friends_timeline(count => 5);
# my $ok = $sina->post_status(status => 'Test New OAuth API');
# my $ok = $sina->upload_status(status => 'Test upload image 3',pic => 't/xiaba.jpg');
# my $ok = $sina->update_profile_image(image => 't/profile.jpg');
# say Dumper($ok);
done_testing;