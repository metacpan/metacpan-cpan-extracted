use Mojolicious::Lite;
use Mojo::Loader 'data_section';
use Time::Piece;
use Test::More;
use Mojo::WebService::Twitter;
use Mojo::WebService::Twitter::Util 'twitter_authorize_url';
use Mojo::Util 'b64_encode';

use constant TEST_API_KEY => 'testapikey';
use constant TEST_API_SECRET => 'testapisecret';
use constant TEST_OAUTH_REQUEST_TOKEN => 'testrequesttoken';
use constant TEST_OAUTH_REQUEST_SECRET => 'testrequestsecret';
use constant TEST_OAUTH_VERIFIER => 'thisisaverifier';
use constant TEST_OAUTH_TOKEN => 'testaccesstoken';
use constant TEST_OAUTH_SECRET => 'testaccesssecret';

app->types->type(form => 'application/x-www-form-urlencoded');

post '/oauth/request_token' => { format => 'form', text => 'oauth_callback_confirmed=true&oauth_token='.TEST_OAUTH_REQUEST_TOKEN.'&oauth_token_secret='.TEST_OAUTH_REQUEST_SECRET };
post '/oauth/access_token' => sub {
	my $c = shift;
	my $oauth_header = $c->req->headers->authorization;
	my ($api_key) = $oauth_header =~ m/oauth_consumer_key="([^"]+)"/;
	is $api_key, TEST_API_KEY, 'received API key';
	my ($verifier) = $oauth_header =~ m/oauth_verifier="([^"]+)"/;
	is $verifier, TEST_OAUTH_VERIFIER, 'received OAuth verifier';
	$c->render(format => 'form', text => 'oauth_token='.TEST_OAUTH_TOKEN.'&oauth_token_secret='.TEST_OAUTH_SECRET);
};
group {
	under '/api' => sub {
		my $c = shift;
		my $oauth_header = $c->req->headers->authorization;
		my ($api_key) = $oauth_header =~ m/oauth_consumer_key="([^"]+)"/;
		is $api_key, TEST_API_KEY, 'received API key';
		my ($access_token) = $oauth_header =~ m/oauth_token="([^"]+)"/;
		is $access_token, TEST_OAUTH_TOKEN, 'received access token';
		return 1;
	};
	get '/account/verify_credentials.json' => { format => 'json', text => data_section('main', 'verify_credentials') };
	post '/statuses/update.json' => { format => 'json', text => data_section('main', 'post_tweet') };
};

my $api_key = $ENV{TWITTER_API_KEY};
my $api_secret = $ENV{TWITTER_API_SECRET};
my $access_token;
my $access_secret;

my $test_online = 0;
if ($ENV{AUTHOR_TESTING} and $ENV{TWITTER_API_POST} and defined $api_key and defined $api_secret) {
	diag 'Running online test for Twitter';
	$test_online = 1;
} else {
	diag 'Running offline test for Twitter; set AUTHOR_TESTING and TWITTER_API_POST and TWITTER_API_KEY/TWITTER_API_SECRET for online test';
	$Mojo::WebService::Twitter::Util::API_BASE_URL = '/api/';
	$Mojo::WebService::Twitter::Util::OAUTH_BASE_URL = '/oauth/';
	$Mojo::WebService::Twitter::Util::OAUTH2_BASE_URL = '/oauth2/';
	$api_key = TEST_API_KEY;
	$api_secret = TEST_API_SECRET;
}

my $twitter = Mojo::WebService::Twitter->new(api_key => $api_key, api_secret => $api_secret);;
$twitter->ua->server->app->log->level('warn');

my $request;
ok(eval { $request = $twitter->request_oauth; 1 }, 'requested authorization') or diag $@;
is $request->{oauth_callback_confirmed}, 'true', 'request callback confirmed';
ok defined($request->{oauth_token}), 'received request token';
ok defined($request->{oauth_token_secret}), 'received request token secret';

my $verifier = TEST_OAUTH_VERIFIER;
if ($test_online) {
	print "Authorization URL: " . twitter_authorize_url($request->{oauth_token}) . "\n";
	print "Enter OAuth verifier: ";
	chomp($verifier = readline STDIN);
}

my $access;
ok(eval { $access = $twitter->verify_oauth($verifier, $request->{oauth_token}); 1 }, 'verified authorization') or diag $@;
$access_token = $access->{oauth_token};
$access_secret = $access->{oauth_token_secret};
ok defined($access_token), 'received access token';
ok defined($access_secret), 'received access token secret';

$twitter->authentication(oauth => $access_token, $access_secret);

my $user;
ok(eval { $user = $twitter->verify_credentials; 1 }, 'verified authorizing user') or diag $@;
is $user->screen_name, 'grinnz_test', 'right authorizing user';

my $tweet_text = "Test tweet " . ($test_online ? b64_encode(join('', map { chr int rand 256 } 1..8), '') : 'ZyFbPejrGI0=');

my $tweet;
ok(eval { $tweet = $twitter->post_tweet($tweet_text); 1 }, 'posted tweet') or diag $@;
is $tweet->text, $tweet_text, "correct tweet text";

done_testing;

__DATA__

@@ verify_credentials
{"id":696839111970263040,"id_str":"696839111970263040","name":"Perl Test","screen_name":"grinnz_test","location":"","description":"","url":null,"entities":{"description":{"urls":[]}},"protected":false,"followers_count":0,"friends_count":0,"listed_count":0,"created_at":"Mon Feb 08 23:32:45 +0000 2016","favourites_count":0,"utc_offset":null,"time_zone":null,"geo_enabled":false,"verified":false,"statuses_count":0,"lang":"en","contributors_enabled":false,"is_translator":false,"is_translation_enabled":false,"profile_background_color":"F5F8FA","profile_background_image_url":null,"profile_background_image_url_https":null,"profile_background_tile":false,"profile_image_url":"http:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_2_normal.png","profile_image_url_https":"https:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_2_normal.png","profile_link_color":"2B7BB9","profile_sidebar_border_color":"C0DEED","profile_sidebar_fill_color":"DDEEF6","profile_text_color":"333333","profile_use_background_image":true,"has_extended_profile":false,"default_profile":true,"default_profile_image":true,"following":false,"follow_request_sent":false,"notifications":false}

@@ post_tweet
{"created_at":"Tue Feb 09 00:00:27 +0000 2016","id":696846083004112896,"id_str":"696846083004112896","text":"Test tweet ZyFbPejrGI0=","source":"\u003ca href=\"http:\/\/socialgamer.net\" rel=\"nofollow\"\u003ePaperbot SG\u003c\/a\u003e","truncated":false,"in_reply_to_status_id":null,"in_reply_to_status_id_str":null,"in_reply_to_user_id":null,"in_reply_to_user_id_str":null,"in_reply_to_screen_name":null,"user":{"id":696839111970263040,"id_str":"696839111970263040","name":"Perl Test","screen_name":"grinnz_test","location":"","description":"","url":null,"entities":{"description":{"urls":[]}},"protected":false,"followers_count":0,"friends_count":0,"listed_count":0,"created_at":"Mon Feb 08 23:32:45 +0000 2016","favourites_count":0,"utc_offset":null,"time_zone":null,"geo_enabled":false,"verified":false,"statuses_count":1,"lang":"en","contributors_enabled":false,"is_translator":false,"is_translation_enabled":false,"profile_background_color":"F5F8FA","profile_background_image_url":null,"profile_background_image_url_https":null,"profile_background_tile":false,"profile_image_url":"http:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_2_normal.png","profile_image_url_https":"https:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_2_normal.png","profile_link_color":"2B7BB9","profile_sidebar_border_color":"C0DEED","profile_sidebar_fill_color":"DDEEF6","profile_text_color":"333333","profile_use_background_image":true,"has_extended_profile":false,"default_profile":true,"default_profile_image":true,"following":false,"follow_request_sent":false,"notifications":false},"geo":null,"coordinates":null,"place":null,"contributors":null,"is_quote_status":false,"retweet_count":0,"favorite_count":0,"entities":{"hashtags":[],"symbols":[],"user_mentions":[],"urls":[]},"favorited":false,"retweeted":false,"lang":"in","ext":{"stickerInfo":{"r":{"err":{"code":402,"message":"ColumnNotFound"}},"ttl":-1}}}
