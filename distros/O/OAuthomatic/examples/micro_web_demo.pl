#!/usr/bin/perl

=head1 micro_web_demo

This is NOT example of using OAuthomatic. Instead, it is a way to
spawn and test the helper micro-web server without initializing
the remaining machinery.

May be useful for template testing in case someone wishes to create
custom page templates.

=cut

# FIXME: maybe name it oauthomatic_template_tester and distribute as script?

use strict;
use warnings;
use feature 'say';
use FindBin;
use Path::Tiny;

use OAuthomatic::Config;
use OAuthomatic::Server;
use OAuthomatic::Internal::MicroWeb;

my $web = OAuthomatic::Internal::MicroWeb->new(
    server => OAuthomatic::Server->new(
        site_name => "NonExistantOauthSite.com",
        site_client_creation_page => "http://non_existant_oauth_site.com/grant/app/permissions",
        site_client_creation_desc => "NonExistant Developers Page",
        site_client_creation_help => <<"END",
Create <New App> button and fill the form to create client tokens.
Use value labelled <Application Identifier> as client key, and
<Application Shared Secret> as client secret.
END
        # Those are not used here, but we must fill sth
        oauth_authorize_page => 'http://not.used',
        oauth_temporary_url => 'http://not.used',
        oauth_token_url => 'http://not.used',
       ),
    config => OAuthomatic::Config->new(
        app_name => 'MicroWeb Demo',
        # To use non-installed copy. Change to your directory to test yor templates
        html_dir => path($FindBin::Bin)->absolute->parent->child("share")->child("oauthomatic_html"),
       ),
    port => 55666,  # fixed to make it possible to reload after restart (comment out for some tests)
    verbose => 1,
   );

$web->start;

say "";
say "Check the following URLs:";
say "";
say "    Root: ";
say "        ", $web->root_url;
say "    OAuth callback (correct): ";
say "        ", $web->callback_url . "?oauth_verifier=VERIF1234IER&oauth_token=TOK5678EN";
say "    OAuth callback (refused): ";
say "        ", $web->callback_url . "?oauth_problem=user_refused";
say "    OAuth callback (bad): ";
say "        ", $web->callback_url;
say "        ", $web->callback_url . "?oauth_verifier=ABCD&xyz=X";
say "    Client key entry form (fill and submit it):";
say "        ", $web->client_key_url;
say "";

say "I will shut down once you submitted app tokens form AND (correct) access tokens form";

while(1) {
    my $r = $web->wait_for_oauth_grant;
    last if $r;
};

while(1) {
    my $r = $web->wait_for_client_cred;
    last if $r;
};

$web->stop;
