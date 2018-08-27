#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use Net::Facebook::Oauth2;
use Data::Dumper;

=head1 DESCRIPTION

This is a general example of using use Net::Facebook::Oauth2;
For a better understanding I recommend you to look at the Catalyst example
Don't worry if you are not familiar with catalyst, I tried to make it as simple
as I can with no complication, plus Catalyst is awsome :)

=cut

sub facebook {

    my $cgi = CGI->new;

    my $fb = Net::Facebook::Oauth2->new(
        application_id => 'your_application_id',  ##get this from your facebook developers platform
        application_secret => 'your_application_secret', ##get this from your facebook developers platform
        callback => 'http://your-domain.com/callback',  ##Callback URL, facebook will redirect users after authintication
    );

    ##you can find more about facebook scopes/Extended Permissions at
    ##http://developers.facebook.com/docs/authentication/permissions
    my $url = $fb->get_authorization_url(
        scope => ['user_posts','manage_pages', 'user_friends'], ###pass scope/Extended Permissions params as an array telling facebook how you want to use this access
        display => 'page' ## how to display authorization page, other options popup "to display as popup window" and wab "for mobile apps"
    );

    ##now redirect to the authorization page
    print $cgi->redirect($url);
}

sub callback {
    ##this sub represent the callback block, where facebook will send users back upon authorization

    my $cgi = CGI->new;
    my $fb = Net::Facebook::Oauth2->new(
        application_id => 'your_application_id',
        application_secret => 'your_application_secret',
        callback => 'http://your-domain.com/callback'
    );

    ####We recieve "verifier" code parameter, now get access token
    ###you need to pass the verifier code to get access_token
    my $access_token = $fb->get_access_token(code => $cgi->param('code'));

    ##that's it, now you have access_token of this user
    ###save this token in database or session to use later in your application
    save_access_token($access_token);

    print $cgi->header();
    print "Welcome";
}


###get information about this user from Facebook, use get method
sub get {

    my $cgi = CGI->new;

    ###now any time you want to get information about user, just retrieve saved access_token of that use
    ###pass it to
    ###and call facebook Graph API URL

    ###for example let's get friends list of that user
    my $access_token = get_access_token('userid'); ###this is a demo, no real get_access_token sub here :P

    my $fb = Net::Facebook::Oauth2->new(
        access_token => $access_token ##Load previous saved access token from session or database
    );

    my $friends = $fb->get(
        'https://graph.facebook.com/v2.8/me/friends' ##Facebook friends list API URL
    );

    print $cgi->header();
    print $friends->as_json;
}

###to post something to facebook use post method
sub post {

    my $cgi = CGI->new;

    ###Lets post a message to the feed of the authorized user
    my $access_token = get_access_token('userid');
    my $fb = Net::Facebook::Oauth2->new(
        access_token => $access_token
    );

    my $res = $fb->post(
        'https://graph.facebook.com/v2.8/me/feed', ###API URL
        {
            message => 'This is a post to my feed from Net::Facebook::Oauth2' ##hash of params/variables (param=>value)
        }
    );

    print $cgi->header();
    print Dumper($res->as_hash); ##print response as perl hash
}


1;
