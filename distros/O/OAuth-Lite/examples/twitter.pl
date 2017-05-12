#!/usr/bin/perl 
#
use strict;
use warnings;

use lib '../lib';
use OAuth::Lite::Consumer;
use Data::Dump qw(dump);
use Perl6::Say;


my $consumer_key = "";
my $consumer_secret = "";

my $consumer = OAuth::Lite::Consumer->new(
    consumer_key    => $consumer_key,
    consumer_secret => $consumer_secret,
);


my $req_token = $consumer->get_request_token(
    url => q{http://twitter.com/oauth/request_token},
    # callback_url => q{oob},
);

say "[GOT REQUEST TOKEN]";
say "TOKEN:".$req_token->token;
say "TOKEN-SECRET:".$req_token->secret;
say "";


say "[ACCESS TO THIS PAGE AND PUSH ALLOW BUTTON]";
say $consumer->url_to_authorize(
    url   => q{http://twitter.com/oauth/authorize},
    token => $req_token,
);
say "";

say "[INPUT THE PINCODE YOU GOT]";
my $pincode;
print "> ";
while ($pincode = <STDIN>) {
    chomp $pincode;
    last;
}

my $access_token = $consumer->get_access_token(
    url => q{http://twitter.com/oauth/access_token},
    token => $req_token,
    verifier => $pincode,
);

unless($access_token) {
    say "Failed to got access token";
    die dump($consumer->oauth_response);
}

say "[GOT ACCESS TOKEN]";
say "TOKEN:".$access_token->token;
say "TOKEN-SECRET:".$access_token->secret;

my $res = $consumer->get("http://twitter.com/statuses/friends_timeline.json");
say ($res->decoded_content||$res->content);

