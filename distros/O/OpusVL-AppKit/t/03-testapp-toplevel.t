
##########################################################################################################################
# This set of tests should be run against the TestApp within the 't' directory of the OpusVL::AppKit Catalyst app.
#
# I couldn't figure out why we couldn't run the tests in the usual way so 
# I flipped it to do so.  I guess the problem we had was fixed somehow?
#
##########################################################################################################################

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
    $mech->add_header("Content-Type" => "application/json");
    $mech->get("/rest/no_permission/30");
    is $mech->status, 403;
    is $mech->content, '{"message":"Access Denied"}';
    $mech->delete_header("Content-Type");

    # Request public page... not logged but should allow access.
    $mech->get_ok("/test/publicaccess");
    is( $mech->ct, "text/html");
    $mech->content_contains("Controller: Test Action: access_public", "Runs a action with 'AppKitAllAccess' specified ");

    # Send incorrect login information..
    $mech->post_ok( '/login', { username => 'appkitadmin', password => 'passwordnotcorrect' }, "Submit to login page");
    $mech->content_contains("Wrong username or password", "Not Logged after giving incorrect details");

    # Send some login information..
    $mech->post_ok( '/login', { username => 'appkitadmin', password => 'password' }, "Submit to login page");
    $mech->content_contains("Welcome to", "Logged in, showing index page");

    my $logged_in_cookie = $mech->cookie_jar->{COOKIES}->{'localhost.local'}->{'/'}->{'testapp_session'};
    isnt $logged_in_cookie, $cookie;
    # can we see the admin..
    $mech->get_ok( '/appkit/admin', "Can see the admin index");
    $mech->content_contains("Settings", "Showing admin page");

    # can we see the ExtensionA chained actoin
    $mech->get_ok( '/start/mid/end', "Can see the ExtensionA chained action page");
    $mech->content_contains('Start Chained actions...Middle of Chained actions...End of Chained actions.', "Chained content");

    # Request a page (from ExtensionB) we should NOT have access to..
    $mech->get( '/test/noaccess', "Get Access Denied" );
    is $mech->status, 403, 'Check we get a 403';

    # can we see the ExtensionB formpage
    $mech->get_ok( '/extensionb/formpage', "Can see the ExtensionB form page");
    $mech->content_contains('<option value="1">Greg Bastien</option>', "Showing select option with content from the BookDB model");

    # Request a page (we should not have an ACL rule for this action)...
    $mech->get_ok( '/test/custom', "Get Custom page" );
    $mech->content_contains("Test Controller from TestApp - custom action", "Request action with no ACL but be allowed via the 'appkit_can_access_actionpaths' config var.");

    # can we logout.
    $mech->get_ok( '/logout', "Can logout");

    # request the home page .. (which should redirect to login)..
    $mech->get_ok("/");
    $mech->content_like(qr/Access denied/i, 'check not logged in');

    $mech->post_ok( '/login', { username => 'APPKITadmin', password => 'password' }, "Submit to login page");
    $mech->content_contains("Welcome to", "Logged in, showing index page");

    $mech->get_ok('/appkit/admin/users/adduser', 'Go to add user page');
    $mech->post_ok('/appkit/admin/users/adduser', 
        {
            username     => 'tester',
            password     => 'password',
            status       => 'enabled',
            email        => 'colin@opusvl.com',
            tel          => '555-32321',
            submitbutton => 'Submit',
        }, 'Try (and fail) to add user'
    );
    $mech->content_contains("This field is required", "Not all fields filled in on add user page") 
        || diag $mech->content;
    $mech->post_ok('/appkit/admin/users/adduser', 
        {
            username     => 'tester',
            password     => 'password',
            status       => 'enabled',
            email        => 'colin@opusvl.com',
            name         => 'Colin',
            tel          => '555-32321',
            submitbutton => 'Submit',
        }, 'Add user'
    );
    # setup permissions
    # FIXME: these user id/role id's are hard wired.
    # we could use mechanise to find them from the links.
    $mech->get_ok('/user/3/show', 'Look at user details');
    $mech->post_ok('/user/3/show', { user_role => 1, savebutton => 'Save' }, 'Add role to user'); 
    $mech->content_contains('User Roles updated', 'Role should have been updated');

    $mech->add_header("Content-Type" => "application/json");
    $mech->get("/rest/no_permission/30");
    is $mech->status, 403;
    is $mech->content, '{"message":"Access Denied"}';
    $mech->get_ok("/rest/vehicle/30");
    my $r = $mech->content;
    like $r, qr'{.*"stock_id":"?30"?.*}';
    like $r, qr'{.*"source_code":"Test".*}';
    $mech->get("/rest/vehicle/1");
    is $mech->status, 404;
    is $mech->content, '{"error":"Vehicle not found"}';
    $mech->delete_header("Content-Type");

    $mech->get_ok('/extensiona', 'Go to extension page');
    $mech->content_like(qr'Expanded Chained Action'i, 'Check we have menu along left');
    $mech->content_like(qr'Expanded Action'i, 'Check we have menu along left');
    $mech->content_like(qr'ExtensionA'i, 'Check we have menu along left');
    $mech->content_like(qr'ExtensionB'i, 'Check we have menu along left');
    $mech->content_like(qr'Test Controller \(within TestApp\)'i, 'Check we have menu along left');

    TODO: {
          local $TODO = 'Check password reset functionality';
          $mech->get_ok('/user/3/reset', 'Try password reset link');
    }
    # fIXME: check this actually works rather than bounces me for instance!

    $mech->get_ok( '/logout', "Can logout");

    $mech->get_ok('/appkit/user/changepword', 'Get change password page');
    $mech->content_contains('Access denied');
    $mech->post_ok( '/login', { username => 'tester', password => 'password' }, "Login as tester");
    $mech->base_is('http://localhost/appkit/user/changepword', 'Should have redirected to url I was trying to access');
    $mech->content_contains("Current password", "Change password page")
        || diag $mech->content;

    $mech->post_ok('/appkit/user/changepword', { password => 'newpassword', passwordconfirm => 'newpassword', submitbutton => 'Submit Query' }, 'Try to change password without mentioning current password');
    $mech->content_contains('required', 'Should complain about current password being missing')
        || diag $mech->content;

    $mech->post_ok('/appkit/user/changepword', { originalpassword => 'password', password => '', passwordconfirm => '', submitbutton => 'Submit Query' }, 'Try to change password to blank');
    $mech->content_contains('required', 'Should complain about password being missing')
        || diag $mech->content;


    $mech->post_ok('/appkit/user/changepword', { originalpassword => 'password', password => 'newpassword', passwordconfirm => 'nomatch', submitbutton => 'Submit Query'  }, 'Try to change password with dodgy passwords');
    $mech->content_contains('Does not match', 'Should complain about differing password inputs')
        || diag $mech->content;

    $mech->post_ok('/appkit/user/changepword', { originalpassword => 'password', password => 'newpassword', passwordconfirm => 'newpassword', submitbutton => 'Submit Query'  }, 'Try to change password');
    $mech->content_contains('your password has been changed', 'Password changed okay');

    $mech->post_ok('/appkit/user/changepword', { originalpassword => 'wrong', password => 'newpassword2', passwordconfirm => 'newpassword2', submitbutton => 'Submit Query'  }, 'Try to change password using wrong original password');
    $mech->content_contains('Invalid password', 'Password not changed');

    $mech->get_ok( '/logout', "Can logout");

    ##################################################
    # test the blank role fix.

    $mech->post_ok( '/login', { username => 'appkitadmin', password => 'password' }, "Submit to login page");
    $mech->content_contains("Welcome to", "Logged in, showing index page");

    $mech->get_ok('/appkit/admin/access/addrole', 'Go to roles page');
    $mech->post_ok('/appkit/admin/access/addrole', {
        addrolebutton => 'Add Role',
        rolename => 'blah',
    }, 'Create a new role');
    $mech->content_like(qr'Access Tree for blah'i, 'Check we have created role');
    $mech->post_ok('/appkit/admin/access/addrole', {
        addrolebutton => 'Add Role',
        rolename => 'blah',
    }, 'Create a new role');
    $mech->content_like(qr'Role already exists'i, 'Check we cannot create role again');
    $mech->post_ok('/appkit/admin/access/addrole', {
        addrolebutton => 'Add Role',
        rolename => '',
    }, 'Try to create a blank role');
    $mech->content_unlike(qr'Access Tree for'i, 'Check we have created role');
    $mech->content_like(qr'Specify a role name'i, 'Check we got told to enter a role name');

    $mech->get_ok('/admin/access/role/blah/show', 'Go back to the role we created');
    $mech->get('/admin/access/role/blah/delrole', 'Delete the role');
    is $mech->status, 403, 'Check we get a 403';
    $mech->get_ok('/admin/access/role/Administrator/show', 'Lets give ourselves permission to do it, we are admin after all');
    $mech->post_ok('/admin/access/role/Administrator/show', {
            savebutton => 'Save',
            'action_appkit/admin/access/auto'=>'allow',
            'action_appkit/admin/access/addrole'=>'allow',
            'action_appkit/admin/access/delete_role'=>'allow',
            'action_appkit/admin/access/index'=>'allow',
            'action_appkit/admin/access/role_specific'=>'allow',
            'action_appkit/admin/access/show_role'=>'allow',
            'action_appkit/admin/index'=>'allow',
            'action_appkit/admin/users/add_parameter'=>'allow',
            'action_appkit/admin/users/adduser'=>'allow',
            'action_appkit/admin/users/auto'=>'allow',
            'action_appkit/admin/users/delete_parameter'=>'allow',
            'action_appkit/admin/users/delete_user'=>'allow',
            'action_appkit/admin/users/edit_user'=>'allow',
            'action_appkit/admin/users/get_parameter_input'=>'allow',
            'action_appkit/admin/users/index'=>'allow',
            'action_appkit/admin/users/show_user'=>'allow',
            'action_appkit/admin/users/user_specific'=>'allow',
            'action_appkit/user/change_password'=>'allow',
            'action_extensiona/expansionaa/endchain'=>'allow',
            'action_extensiona/expansionaa/home'=>'allow',
            'action_extensiona/expansionaa/midchain'=>'allow',
            'action_extensiona/expansionaa/startchain'=>'allow',
            'action_extensiona/home'=>'allow',
            'action_extensionb/formpage'=>'allow',
            'action_extensionb/home'=>'allow',
            'action_index'=>'allow',
            'action_search/index'=>'allow',
            'action_test/access_admin'=>'allow',
            'action_test/cause_error'=>'allow',
            'action_test/index'=>'allow',
    }, 'Allow deleting roles.');

    $mech->get_ok('/admin/access/role/blah/delrole', 'Delete the role');
    $mech->content_like(qr'Are you sure you want to delete the role'i, 'Check we are asked to confirm the deletion');
    $mech->click_ok('submitok');
    $mech->content_like(qr'Role deleted'i, 'Check we deleted the role');

    $mech->get('/admin/access/role/notthere/delrole');
    is $mech->status, 404, 'Check we get a 404 for a non existent role';

    $mech->get("/db/appkit_auth.db");
    is $mech->status, 404, 'Check we get a 404 for our db';

    # this would be so cool if it worked.  Unfortunately the mech
    # will only work if the page it's just downloaded has this
    # link contained.
    #$mech->link_status_is(['/admin/access/role/notthere/delrole'], 404, 'Check 404 on role that does not exist');

    # FUCKME SIDEWAYS BUG 1057
    # disable a user and ensure we cant' then log in as them!
    $mech->get_ok('/appkit/admin/users/adduser', 'Go to add user page');
    $mech->submit_form(form_number => 1, fields => {
        username => 'deleteme',
        password => 'secure01',
        status => 'enabled',
        email => 'jj@opusvl.com',
        name => 'JJ',
        tel => '3213223',
    }, button => 'submitbutton');

    my $mech2 = Test::WWW::Mechanize::Catalyst->new();
    $mech2->get_ok('/');
    $mech2->content_like(qr|Access Denied|i);
    $mech2->submit_form(form_number => 1,
        fields => {
            username => 'deleteme',
            password => 'secure01',
            remember => 'remember',
        },
    );
    $mech2->content_like(qr|Welcome.*JJ|);
    $mech2->get_ok( '/logout', "Can logout");
    $mech2->content_like(qr|Access Denied|i);

    # now disable the user
    $mech->follow_link_ok({ text_regex => qr|edit|i });
    $mech->submit_form(form_number => 1, fields => {
        username => 'deleteme',
        status => 'disabled',
        email => 'jj@opusvl.com',
        name => 'JJ',
        tel => '3213223',
    }, button => 'submitbutton');
    $mech->content_like(qr|User updated|i);

    $mech2->submit_form(form_number => 1,
        fields => {
            username => 'deleteme',
            password => 'secure01',
            remember => 'remember',
        },
    );
    $mech2->content_unlike(qr|Welcome.*JJ|);
    $mech2->content_like(qr|Wrong username or password|i);

    # now 'delete' the user
    $mech->submit_form(form_number => 1, fields => {
        username => 'deleteme',
        status => 'deleted',
        email => 'jj@opusvl.com',
        name => 'JJ',
        tel => '3213223',
    }, button => 'submitbutton');
    $mech->content_like(qr|User updated|i);

    $mech2->submit_form(form_number => 1,
        fields => {
            username => 'deleteme',
            password => 'secure01',
            remember => 'remember',
        },
    );
    $mech2->content_unlike(qr|Welcome.*JJ|);
    $mech2->content_like(qr|Wrong username or password|i);

    # now activate the user
    $mech->submit_form(form_number => 1, fields => {
        username => 'deleteme',
        status => 'enabled',
        email => 'jj@opusvl.com',
        name => 'JJ',
        tel => '3213223',
    }, button => 'submitbutton');
    $mech->content_like(qr|User updated|i);

    $mech2->submit_form(form_number => 1,
        fields => {
            username => 'deleteme',
            password => 'secure01',
            remember => 'remember',
        },
    );
    $mech2->content_like(qr|Welcome.*JJ|);
    $mech2->content_unlike(qr|Wrong username or password|i);
    $mech2->content_unlike(qr|Access Denied|i);
    $mech->get_ok('/static/images/search_button_small.png');

    ## NEED TO ADD MANY MORE TESTS!!... think about all things that could and could not happen with the TestApp..
    # .. things I can think of now:
    #       
    #       access controll (adding, removing, allow, deny)
    #       roles (adding, removing, allow, deny)
    #       users (adding, removing, change password)

}

done_testing();
