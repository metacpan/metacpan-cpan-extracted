#!perl

use strict;
use warnings;
use Test::More tests => 10;

BEGIN {
	use_ok( 'Net::OpenMicroBlogging' );
}

diag( "Testing Net::OpenMicroBlogging $Net::OpenMicroBlogging::VERSION, Perl $], $^X" );

my $request = Net::OpenMicroBlogging->request('request token')->new(
    consumer_key => 'dpf43f3p2l4k3l03',
    consumer_secret => 'kd94hf93k423kf44',
    request_url => 'https://ublog.example.net/request_token',
    request_method => 'POST',
    signature_method => 'HMAC-SHA1',
    timestamp => '1191242090',
    nonce => 'hsu94j3884jdopsl',
    omb_listener => 'http://ublog.example.net/bob',
);

$request->sign;

ok($request->verify);

is($request->to_post_body,
   'oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=hsu94j3884jdopsl&oauth_signature=%2BoBmHpPIBnnaH5oAlKL5hx0lQ2Y%3D&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242090&oauth_version=1.0&omb_listener=http%3A%2F%2Fublog.example.net%2Fbob&omb_version=http%3A%2F%2Fopenmicroblogging.org%2Fprotocol%2F0.1');


$request = Net::OpenMicroBlogging->request('user auth')->new(
    token => 'hh5s93j4hdidpola',
    callback => 'http://consumer.example.net/callback',
    omb_listener => 'http://ublog.example.net/bob',
    omb_listenee => 'http://ublog.example.net/alice',
    omb_listenee_profile => 'http://ublog.example.net/alice',
    omb_listenee_nickname => 'Alice',
    omb_listenee_fullname => 'Alice Munro',
    omb_listenee_homepage => 'http://alice.example.com',
    omb_listenee_bio => 'Alice is awesome',
    omb_listenee_location => 'Vancouver, Canada',
    omb_listenee_avatar => 'http://alice.example.com/me.png',
    omb_listenee_license => 'http://creativecommons.org/licenses/by/3.0/',
);

is($request->to_post_body,
   'oauth_callback=http%3A%2F%2Fconsumer.example.net%2Fcallback&oauth_token=hh5s93j4hdidpola&omb_listenee=http%3A%2F%2Fublog.example.net%2Falice&omb_listenee_avatar=http%3A%2F%2Falice.example.com%2Fme.png&omb_listenee_bio=Alice%20is%20awesome&omb_listenee_fullname=Alice%20Munro&omb_listenee_homepage=http%3A%2F%2Falice.example.com&omb_listenee_license=http%3A%2F%2Fcreativecommons.org%2Flicenses%2Fby%2F3.0%2F&omb_listenee_location=Vancouver%2C%20Canada&omb_listenee_nickname=Alice&omb_listenee_profile=http%3A%2F%2Fublog.example.net%2Falice&omb_listener=http%3A%2F%2Fublog.example.net%2Fbob&omb_version=http%3A%2F%2Fopenmicroblogging.org%2Fprotocol%2F0.1');

$request = Net::OpenMicroBlogging->request('update profile')->new(
    token => 'hh5s93j4hdidpola',
    token_secret => 'hdhd0244k9j7ao03',
    consumer_key => 'dpf43f3p2l4k3l03',
    consumer_secret => 'kd94hf93k423kf44',
    request_url => 'https://ublog.example.net/update',
    request_method => 'POST',
    signature_method => 'HMAC-SHA1',
    timestamp => '1191242090',
    nonce => 'hsu94j3884jdopsl',
    omb_listenee => 'http://ublog.example.net/alice',
    omb_listenee_profile => 'http://ublog.example.net/alice',
    omb_listenee_nickname => 'Alice',
    omb_listenee_fullname => 'Alice Munro',
    omb_listenee_homepage => 'http://alice.example.com',
    omb_listenee_bio => 'Alice is awesome',
    omb_listenee_location => 'Vancouver, Canada',
    omb_listenee_avatar => 'http://alice.example.com/me.png',
    omb_listenee_license => 'http://creativecommons.org/licenses/by/3.0/',
);

$request->sign;

is($request->to_post_body,
   'oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=hsu94j3884jdopsl&oauth_signature=zSh58XmlMs%2BFaI8%2BkcePqntgrV4%3D&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242090&oauth_token=hh5s93j4hdidpola&oauth_version=1.0&omb_listenee=http%3A%2F%2Fublog.example.net%2Falice&omb_listenee_avatar=http%3A%2F%2Falice.example.com%2Fme.png&omb_listenee_bio=Alice%20is%20awesome&omb_listenee_fullname=Alice%20Munro&omb_listenee_homepage=http%3A%2F%2Falice.example.com&omb_listenee_license=http%3A%2F%2Fcreativecommons.org%2Flicenses%2Fby%2F3.0%2F&omb_listenee_location=Vancouver%2C%20Canada&omb_listenee_nickname=Alice&omb_listenee_profile=http%3A%2F%2Fublog.example.net%2Falice&omb_version=http%3A%2F%2Fopenmicroblogging.org%2Fprotocol%2F0.1');

$request = Net::OpenMicroBlogging->request('post notice')->new(
    token => 'hh5s93j4hdidpola',
    token_secret => 'hdhd0244k9j7ao03',
    consumer_key => 'dpf43f3p2l4k3l03',
    consumer_secret => 'kd94hf93k423kf44',
    request_url => 'https://ublog.example.net/post',
    request_method => 'POST',
    signature_method => 'HMAC-SHA1',
    timestamp => '1191242090',
    nonce => 'hsu94j3884jdopsl',
    omb_listenee => 'http://ublog.example.net/alice',
    omb_notice => 'http://ublog.example.net/alice/statuses/1234',
    omb_notice_content => 'Not much to say, today',
    omb_notice_url => 'http://ublog.example.net/alice/statuses/1234',
    omb_notice_license => 'http://creativecommons.org/licenses/by/3.0/',
    omb_seealso => 'http://ublog.example.net/alice/images/hello.png',
    omb_seealso_disposition => 'inline',
    omb_seealso_mediatype => 'image/png',
    omb_seealso_license => 'hhttp://creativecommons.org/licenses/by/3.0/',
);

$request->sign;

ok($request->verify);

is($request->to_post_body,
   'oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=hsu94j3884jdopsl&oauth_signature=dUJunrXKIgbmJjVqDKNL6%2B8rxmk%3D&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242090&oauth_token=hh5s93j4hdidpola&oauth_version=1.0&omb_listenee=http%3A%2F%2Fublog.example.net%2Falice&omb_notice=http%3A%2F%2Fublog.example.net%2Falice%2Fstatuses%2F1234&omb_notice_content=Not%20much%20to%20say%2C%20today&omb_notice_license=http%3A%2F%2Fcreativecommons.org%2Flicenses%2Fby%2F3.0%2F&omb_notice_url=http%3A%2F%2Fublog.example.net%2Falice%2Fstatuses%2F1234&omb_seealso=http%3A%2F%2Fublog.example.net%2Falice%2Fimages%2Fhello.png&omb_seealso_disposition=inline&omb_seealso_license=hhttp%3A%2F%2Fcreativecommons.org%2Flicenses%2Fby%2F3.0%2F&omb_seealso_mediatype=image%2Fpng&omb_version=http%3A%2F%2Fopenmicroblogging.org%2Fprotocol%2F0.1');

is($request->to_authorization_header('http://ublog.example.net/', ",\n")."\n", <<EOT);
OAuth realm="http://ublog.example.net/",
oauth_consumer_key="dpf43f3p2l4k3l03",
oauth_nonce="hsu94j3884jdopsl",
oauth_signature="dUJunrXKIgbmJjVqDKNL6%2B8rxmk%3D",
oauth_signature_method="HMAC-SHA1",
oauth_timestamp="1191242090",
oauth_token="hh5s93j4hdidpola",
oauth_version="1.0",
omb_listenee="http%3A%2F%2Fublog.example.net%2Falice",
omb_notice="http%3A%2F%2Fublog.example.net%2Falice%2Fstatuses%2F1234",
omb_notice_content="Not%20much%20to%20say%2C%20today",
omb_notice_license="http%3A%2F%2Fcreativecommons.org%2Flicenses%2Fby%2F3.0%2F",
omb_notice_url="http%3A%2F%2Fublog.example.net%2Falice%2Fstatuses%2F1234",
omb_seealso="http%3A%2F%2Fublog.example.net%2Falice%2Fimages%2Fhello.png",
omb_seealso_disposition="inline",
omb_seealso_license="hhttp%3A%2F%2Fcreativecommons.org%2Flicenses%2Fby%2F3.0%2F",
omb_seealso_mediatype="image%2Fpng",
omb_version="http%3A%2F%2Fopenmicroblogging.org%2Fprotocol%2F0.1"
EOT

$request = $request->from_url($request->to_url, 
    consumer_secret => 'kd94hf93k423kf44',
    token_secret => 'hdhd0244k9j7ao03',
    request_url => 'https://ublog.example.net/post',
    request_method => 'POST',
);

ok($request->verify);

is($request->to_post_body,
   'oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=hsu94j3884jdopsl&oauth_signature=dUJunrXKIgbmJjVqDKNL6%2B8rxmk%3D&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242090&oauth_token=hh5s93j4hdidpola&oauth_version=1.0&omb_listenee=http%3A%2F%2Fublog.example.net%2Falice&omb_notice=http%3A%2F%2Fublog.example.net%2Falice%2Fstatuses%2F1234&omb_notice_content=Not%20much%20to%20say%2C%20today&omb_notice_license=http%3A%2F%2Fcreativecommons.org%2Flicenses%2Fby%2F3.0%2F&omb_notice_url=http%3A%2F%2Fublog.example.net%2Falice%2Fstatuses%2F1234&omb_seealso=http%3A%2F%2Fublog.example.net%2Falice%2Fimages%2Fhello.png&omb_seealso_disposition=inline&omb_seealso_license=hhttp%3A%2F%2Fcreativecommons.org%2Flicenses%2Fby%2F3.0%2F&omb_seealso_mediatype=image%2Fpng&omb_version=http%3A%2F%2Fopenmicroblogging.org%2Fprotocol%2F0.1');
