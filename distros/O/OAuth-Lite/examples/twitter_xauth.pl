#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';
use OAuth::Lite::Consumer;
use Data::Dump qw(dump);
use Perl6::Say;
use MIME::Base64;

my $consumer_key    = "";
my $consumer_secret = "";

my $consumer = OAuth::Lite::Consumer->new(
    consumer_key    => $consumer_key,
    consumer_secret => $consumer_secret,
    ua              => LWP::UserAgent->new,
);

say "[INPUT USERNAME]";
my $username;
print "> ";
while ($username = <STDIN>) {
    chomp $username;
    last;
}

say "[INPUT PASSWORD]";
my $password;
print "> ";
while ($password = <STDIN>) {
    chomp $password;
    last;
}

my $res = $consumer->obtain_access_token(
    url => q{https://twitter.com/oauth/access_token},
    params => {
        x_auth_username => $username,
        x_auth_password => $password,
        x_auth_mode     => "client_auth",
    },
);

unless($res) {
    say "Failed to got access token";
    die dump($consumer->oauth_response);
}

say "[GOT ACCESS TOKEN]";
say "TOKEN:".$res->token->token;
say "TOKEN-SECRET:".$res->token->secret;
say "EXPIRES:".$res->param('x_auth_expires');
say $res->param('screen_name');
say $res->param('user_id');

#my $result = $consumer->get("http://twitter.com/statuses/friends_timeline.json");
#say ($result->decoded_content||$result->content);

