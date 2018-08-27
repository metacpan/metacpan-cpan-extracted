package MyApp::Controller::Facebook;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Net::Facebook::Oauth2;


=head1 DESCRIPTION

this example shows you how to use Net::Facebook::Oauth2 with Catalyst,
it's not the best way of writing your catalyst controller though :P

The call back URL below is in the same block of
When live test this application don't use localhost, as facebook will
return an error because the callback URL must match the one you set in
facebook developer platfor for your application

=cut


    sub index : Private {

        my ( $self, $c ) = @_;
        my $params = $c->req->parameters;

        my $fb = Net::Facebook::Oauth2->new(
            application_id => 'your_application_id',  ##get this from your facebook developers platform
            application_secret => 'your_application_secret', ##get this from your facebook developers platform
            callback => 'http://localhost:3000/facebook',  ##Callback URL, facebook will redirect users after authintication
        );

        #### first check if callback URL doesn't contain a verifier code  "code" parameter
        if (!$params->{code}){

            ##there is no verifier code passed so let's create authorization URL and redirect to it
            my $url = $fb->get_authorization_url(
                scope => ['user_posts','manage_pages', 'user_friends'], ###pass scope/Extended Permissions params as an array telling facebook how you want to use this access
                display => 'page' ## how to display authorization page, other options popup "to display as popup window" and wab "for mobile apps"
            );

            ##you can find more about facebook scopes/Extended Permissions at
            ##http://developers.facebook.com/docs/authentication/permissions
            $c->res->redirect($url);
        }
        else {
            ####second step, we recieved "verifier" code parameters, now get access token
            ###you need to pass the verifier code to get access_token
            my $access_token = $fb->get_access_token( code => $params->{code} );

            ###save this token in database or session
            $c->session->{access_token} =  $access_token;
            $c->res->body('Welcome from facebook');
        }
    }

    ##get/post to facebook on the behalf of the authorized user
    ##first get this user information, login name, user profile URL
    sub get : Local {

        my ( $self, $c ) = @_;
        my $params = $c->req->parameters;

        my $fb = Net::Facebook::Oauth2->new(
            access_token => $c->session->{access_token} ##Load previous saved access token from session or database
        );

        ##lets get list of friends for the authorized user
        my $info = $fb->get(
            'https://graph.facebook.com/v2.8/me' ##Facebook API URL
        );

        $c->res->body($info->as_json); ##as_json method will print response as json object
    }

    ##example 2 - get friends list for this user
    sub get_friends : Local {

        my ( $self, $c ) = @_;
        my $params = $c->req->parameters;

        my $fb = Net::Facebook::Oauth2->new(
            access_token => $c->session->{access_token}
        );

        ##lets get list of friends for the authorized user
        my $friends = $fb->get(
            'https://graph.facebook.com/v2.8/me/friends' ##Facebook 'list friend' Graph API URL
        );

        $c->res->body($friends->as_json);
    }

    ####post to facebook example
    sub post : Local {

        my ( $self, $c ) = @_;
        my $params = $c->req->parameters;

        ###Lets post a message to the feed of the authorized user
        my $fb = Net::Facebook::Oauth2->new(
            access_token => $c->session->{access_token}
        );

        my $res = $fb->post(
            'https://graph.facebook.com/v2.8/me/feed', ###API URL
            {
                message => 'This is a post to my feed from Net::Facebook::Oauth2' ##hash of params/variables (param=>value)
            }
        );
        $c->res->body($res->as_json);
    }

1;
