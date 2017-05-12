#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use Data::Dumper;

=head1 auth_to_bitbucket_explicit

This example performs OAuth authorization sequence and then calls some
BitBucket method which require authorization (grabs user details).
Various keys used in the process are saved in keyring (if any is
available) so re-run need not ask for them anymore.

Here we give explicit values, without using predefined alias.

=cut

use OAuthomatic;

# Various configurations
my $oauthomatic = OAuthomatic->new(
    app_name => "OAuthomatic demo",
    password_group => "OAuthomatic ad-hoc keys (private)",

    server => {
        # OAuth urls for the service (should be documented somewhere by provider)
        oauth_temporary_url => 'https://bitbucket.org/api/1.0/oauth/request_token',
        oauth_authorize_page => 'https://bitbucket.org/api/1.0/oauth/authenticate',
        oauth_token_url  => 'https://bitbucket.org/api/1.0/oauth/access_token',
        # Useful additional info
        site_client_creation_desc => "Manage account => Access Management => OAuth => Add consumer",
        # site_client_creation_page => https://bitbucket.org/account/user/YOUR-BITBUCKET-NICK/api
        site_client_creation_help => <<"END",
Visit Manage account page within your settings, and choose OAuth link
(Access Management section). Click <Add consumer> button. Use
<Consumer key> as client key and <Consumer secret> as client secret.",
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

print "*** User info   (get_json, no params)\n";

my $reply = $oauthomatic->get_json(
    'https://bitbucket.org/api/2.0/user');

print "    username:     ", $reply->{username}, "\n";
print "    display_name: ", $reply->{display_name}, "\n";
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

###########################################################################

print "*** User repositories   (get_json, parames embeded in url)\n";

$reply = $oauthomatic->get_json(
    "https://bitbucket.org/api/2.0/repositories/$user_uuid",
    {pagelen => 4});

for(my $page_no = 1; $page_no < 5; ++ $page_no)  {  # at most few pages

    print "\n* PAGE $page_no (len: $reply->{pagelen})\n\n";

    my $values = $reply->{"values"};
    foreach my $repo (@$values) {
        print "    name:        ", $repo->{name}, "\n";
        print "    scm:         ", $repo->{scm}, "\n";
        print "    language:    ", $repo->{language}, "\n";
        print "    is_private:  ", $repo->{is_private}, "\n";
        # This does not work because sometimes $links->{$link_name} is an arrayref
        # my $links = $repo->{links};
        # if($links) {
        #     foreach my $link_name (sort keys %$links) {
        #         print "    links/$link_name: ", $links->{$link_name}->{href}, "\n";
        #     }
        # }
        # print "    description: ", $repo->{description}, "\n";
        print "-" x 55, "\n";
    }

    my $next = $reply->{next};   # page is already inside params
    last unless $next;

    print "*" x 65, "\n";

    # Next is OK but ignores my pagelen
    # $reply = $oauthomatic->get_json($next);
    $reply = $oauthomatic->get_json(
        "https://bitbucket.org/api/2.0/repositories/$user_uuid",
        {pagelen => 4, page => $page_no + 1});
}

# See clt_bitbucket_predef for more calls
