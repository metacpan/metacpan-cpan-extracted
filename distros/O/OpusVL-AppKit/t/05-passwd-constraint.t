use strict;
use warnings;
use Test::Most;


use FindBin qw($Bin);
use lib "$Bin/lib";

use ok 'TestApp';
use Test::WWW::Mechanize::Catalyst 'TestApp';

{
    # build the testing machanised object...
    my $mech = Test::WWW::Mechanize::Catalyst->new();

    # Request index page... not logged in so should redirect..
    $mech->get_ok("/");
    my $cookie = $mech->cookie_jar->{COOKIES}->{'localhost.local'}->{'/'}->{'testapp_session'};

    is( $mech->ct, "text/html");
    $mech->content_contains("Please login", "Redirect to login page");
    $mech->content_contains('OpusVL::AppKit', 'App name and logo should be present');

     # Send some login information..
    $mech->post_ok( '/login', { username => 'appkitadmin', password => 'password' }, "Submit to login page");
    $mech->content_contains("Welcome to", "Logged in, showing index page");

    my $logged_in_cookie = $mech->cookie_jar->{COOKIES}->{'localhost.local'}->{'/'}->{'testapp_session'};
    isnt $logged_in_cookie, $cookie;

    # can we see the admin..
    $mech->get_ok( '/appkit/admin', "Can see the admin index");
    $mech->content_contains("Settings", "Showing admin page");

    # Visit change password page
    $mech->post_ok('/appkit/user/changepword', "Can see the change password page");
    $mech->content_contains("Change Your Password", "Showing Change Password Page");
    $mech->submit_form_ok({
        button => 'submitbutton',
        with_fields => {
            originalpassword => 'password',
            password         => 'passwd',
            passwordconfirm  => 'passwd',
        },
    });

    $mech->content_contains("Minimum length for password is", "Password constraint matched OK") or diag $mech->content;
}

done_testing();