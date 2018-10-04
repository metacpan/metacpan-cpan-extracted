
use strict;
use warnings;
use utf8;
use lib 'lib';
use Net::Google::OAuth;

use Test::More 'no_plan';

BEGIN {
    use_ok("Net::Google::OAuth");
}

my $EMAIL                   = $ENV{'GMAIL_EMAIL'};
my $CLIENT_ID               = $ENV{'GMAIL_CLIENT_ID'};
my $CLIENT_SECRET           = $ENV{'GMAIL_CLIENT_SECRET'};
my $SCOPE                   = $ENV{'GMAIL_SCOPE'};



can_ok("Net::Google::OAuth", 'new');

SKIP: {
    skip "Skip test get access token. Not defined: GMAIL_EMAIL" if not defined $EMAIL;
    skip "Skip test get access token. Not defined: GMAIL_CLIENT_ID" if not defined $CLIENT_ID;
    skip "Skip test get access token. Not defined: GMAIL_CLIENT_SECRET" if not defined $CLIENT_SECRET;
    skip "Skip test get access token. Not defined: GMAIL_SCOPE" if not defined $SCOPE;

    my $oauth = Net::Google::OAuth->new(
                                -client_id      => $CLIENT_ID,
                                -client_secret  => $CLIENT_SECRET,
                            );
    isa_ok($oauth, "Net::Google::OAuth");

    my ($access_token, $refresh_token) = test_generate_access_token($oauth);
    my ($new_access_token, $new_refresh_token) = test_get_access_token_from_refresh($oauth, $refresh_token);

    print "Access token: $new_access_token\n";
    print "Refresh token: $new_refresh_token\n";
}


sub test_generate_access_token {
    my ($oauth) = @_;
    $oauth->generateAccessToken(
                            -email          => $EMAIL,
                            -scope          => $SCOPE,
                        );
    my $access_token = $oauth->getAccessToken();
    ok($access_token, "Get access token");
    print "Access token: $access_token\n";
    
    my $refresh_token = $oauth->getRefreshToken();
    ok ($refresh_token, "Get refresh token");
    
    return ($access_token, $refresh_token);
}

sub test_get_access_token_from_refresh {
    my ($oauth, $refresh_token) = @_;
    $oauth->refreshToken(
                            -refresh_token      => $refresh_token,
                        );
    my $access_token = $oauth->getAccessToken();
    ok($access_token, "Get access after refresh");
    print "Access token new: $access_token\n";

    my $refresh_token_new = $oauth->getRefreshToken();
    ok ($refresh_token_new, "Get refresh token new");
    
    return ($access_token, $refresh_token);


}
