#!perl

# Net::OAuth::Client selects OAuth 1.0a when the application configures a
# callback. The service provider's request token response then decides
# whether that choice survives: without oauth_callback_confirmed the client
# used to drop back to 1.0 by itself, which also drops oauth_verifier from
# the access token request, silently. These tests pin the three states the
# client can be in, and the warning for a verifier that will not be sent.
#
# The user agent here is a stub returning canned responses. Nothing in this
# file opens a socket.

use strict;
use warnings;
use Test::More tests => 14;
use Test::Warn;

use Net::OAuth;
use Net::OAuth::Client;
use HTTP::Response;

{
    package StubUA;
    sub new {
        my ($class, %a) = @_;
        return bless { confirm => $a{confirm}, seen => [] }, $class;
    }
    sub seen { @{ $_[0]{seen} } }
    sub request {
        my ($self, $http_req) = @_;
        push @{ $self->{seen} }, $http_req->uri->as_string;
        my $body;
        if (@{ $self->{seen} } == 1) {
            # Request token response. The presence of oauth_callback_confirmed
            # is the only thing that varies between these tests.
            $body = 'oauth_token=reqtok&oauth_token_secret=reqsec';
            $body .= '&oauth_callback_confirmed=true' if $self->{confirm};
        }
        else {
            $body = 'oauth_token=acctok&oauth_token_secret=accsec';
        }
        my $res = HTTP::Response->new(200, 'OK',
            ['Content-Type' => 'application/x-www-form-urlencoded'], $body);
        $res->request($http_req);
        return $res;
    }
}

sub client {
    my %args = @_;
    my $ua = StubUA->new(confirm => delete $args{confirm});
    my $client = Net::OAuth::Client->new(
        'consumer-key', 'consumer-secret',
        site               => 'https://provider.invalid/',
        request_token_path => '/oauth/request_token',
        authorize_path     => '/oauth/authorize',
        access_token_path  => '/oauth/access_token',
        user_agent         => $ua,
        session            => sub { 'reqsec' },
        %args,
    );
    return ($client, $ua);
}

my $CALLBACK = 'https://app.invalid/cb';

# A provider that confirms the callback: nothing changes, and the verifier
# reaches the wire.
{
    my ($client, $ua) = client(confirm => 1, callback => $CALLBACK);
    ok($client->is_v1a, 'configuring a callback selects 1.0a');
    warnings_are { $client->get_request_token } [],
        'a confirming provider produces no warning';
    ok($client->is_v1a, 'and leaves the client on 1.0a');
    warnings_are { $client->get_access_token('reqtok', 'the-verifier') } [],
        'nor does the access token exchange';
    my @urls = $ua->seen;
    is(scalar @urls, 2, 'both requests were sent');
    like($urls[-1], qr/oauth_verifier=the-verifier/,
        'the access token request carries oauth_verifier');
}

# A provider that does not confirm it, with the client left at its defaults:
# the exchange stops rather than continuing without the verifier.
{
    my ($client, $ua) = client(confirm => 0, callback => $CALLBACK);
    # Run the whole flow, so that the last assertion has something to
    # observe: before this change the flow completed here and sent an
    # access token request with no oauth_verifier on it.
    my $completed = eval {
        $client->get_request_token;
        $client->get_access_token('reqtok', 'the-verifier');
        1;
    };
    ok(!$completed, 'an unconfirmed callback is fatal by default');
    like($@, qr/allow_v1a_downgrade/,
        '... and the message names the option that permits it');
    is(scalar($ua->seen), 1,
        '... and the access token request is never sent');
}

# The same provider, with the application opting in to the fallback. It
# behaves as it always did, but says so both times.
{
    my ($client, $ua) = client(confirm => 0, callback => $CALLBACK,
                               allow_v1a_downgrade => 1);
    warning_like { $client->get_request_token } qr/falling back to OAuth 1\.0/,
        'the opted-in fallback warns';
    ok(!$client->is_v1a, '... and does fall back');
    warning_like { $client->get_access_token('reqtok', 'the-verifier') }
        qr/oauth_verifier was supplied/,
        '... and the dropped verifier warns too';
    my @urls = $ua->seen;
    unlike($urls[-1], qr/oauth_verifier/,
        '... which is accurate: it is not on the wire');
}

# A client that never asked for 1.0a is in 1.0 mode legitimately, but a
# verifier handed to it still goes nowhere, so it still warns.
{
    my ($client, $ua) = client(confirm => 0);
    $client->get_request_token;
    warning_like { $client->get_access_token('reqtok', 'the-verifier') }
        qr/oauth_verifier was supplied/,
        'a 1.0 client warns about a verifier it cannot send';
}
