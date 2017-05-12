#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use Const::Fast;
use Data::Dumper;

# Docs: https://dev.twitter.com/web/sign-in/implementing
# https://dev.twitter.com/rest/reference/get/statuses/home_timeline

# Will create or modify this one
const my $TEST_REPO_SLUG => "oauthomatic_test_repo";
const my $TEST_REPO_NAME => "OAuthomatic Test Repo";

=head1 auth_to_twitter

This example performs OAuth authorization sequence and then calls some
Twitter method which require authorization (grabs user details).
Various keys used in the process are saved in keyring (if any is
available) so re-run need not ask for them anymore.

=cut

use OAuthomatic;

# Various configurations
my $oauthomatic = OAuthomatic->new(
    app_name => "OAuthomatic demo",
    password_group => "OAuthomatic ad-hoc keys (private)",

    server => {
        oauth_temporary_url => 'https://api.twitter.com/oauth/request_token',
        oauth_authorize_page => 'https://api.twitter.com/oauth/authenticate',
        oauth_token_url  => 'https://api.twitter.com/oauth/access_token',
        site_client_creation_desc => "Twitter Apps Developer Site",
        site_client_creation_page => 'https://apps.twitter.com/',
        site_client_creation_help => <<"END",
Use Create New App button and fill the form. Once done,
visit <Keys and Access Tokens> tab in application details and
copy <Consumer Key> as client key and <Consumer Secret> as client secret.
END
    },

    browser => "firefox",

    debug => 1,     # Print various info about progress
   );

print "*** Setting up OAuth communication\n";

# Initiates OAuth-authorized communication. Not necessary
# (will be executed by first call if skipped), but let's be explicit.
$oauthomatic->ensure_authorized();

###########################################################################

print "*** Timeline   (get_json, no params)\n";

my $reply = $oauthomatic->get_json(
    'https://api.twitter.com/1.1/statuses/home_timeline.json',
    count => 5);

use Data::Dumper;
print Dumper($reply);

__END__

print "    user.name:    ", $reply->{user}->{name}, "\n";
print "    source: ",    $reply->{display_name}, "\n";
print "    type:         ", $reply->{type}, "\n";
print "    uuid:         ", $reply->{uuid}, "\n";
print "    website:      ", $reply->{website}, "\n";
my $links = $reply->{links};
if($links) {
    foreach my $link_name (sort keys %$links) {
        print "    links/$link_name: ", $links->{$link_name}->{href}, "\n";
    }
}

my $user_uuid = $reply->{uuid};
