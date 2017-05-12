use strict;
use warnings;

use Test::More;
use Readonly;

#
# test the client functions with the api/network live
#

use lib 'lib';
use_ok('Sailthru::Client');

my ( $api_key, $secret, $verified_from_email ) =
  ( $ENV{SAILTHRU_KEY}, $ENV{SAILTHRU_SECRET}, $ENV{SAILTHRU_FROM_EMAIL} );

# resources to use for the test.  These will be automatically created/deleted on Sailthru
Readonly my $TIMESTAMP => time;
Readonly my $LIST      => 'CPAN test list ' . $TIMESTAMP;
Readonly my $EMAIL     => 'sc-cpan@example' . $TIMESTAMP . '.com';
Readonly my $TEMPLATE  => 'CPAN Test ' . $TIMESTAMP;

# responses to api calls
my $response;

my $bad_sc = Sailthru::Client->new( 'key', 'secret' );
# testing invalid key response
$response = $bad_sc->get_email('not_an_email');
is( $response->{error}, 3, 'testing error code on invalid key' );

my $sc;

SKIP: {
    skip 'requires an API key and secret', 1 if not defined $api_key or not defined $secret;

    # test bad secret
    $sc = Sailthru::Client->new( $api_key, 'invalid_secret' );
    $response = $sc->get_email('not_an_email');
    is( $response->{error}, 5, 'testing authentication failing error code' );

    # build a good client to use
    $sc = Sailthru::Client->new( $api_key, $secret );

    # test invalid email
    $response = $sc->get_email('not_an_email');
    is( $response->{error}, 11, 'testing error code on invalid email' );

    #
    # setup template and list to test against
    #

    # create template (or overwrite if already exists)
    my @lines = <DATA>;
    close DATA;
    $response = $sc->api_post( 'template', { template => $TEMPLATE, content_html => "@lines" } );
    is( $response->{error}, undef,     'no error creating template' );
    is( $response->{name},  $TEMPLATE, 'created template name matches' );

    # try to create list, in case it doesn't exist (will delete at end, anyway) and verify it's there
    my $list = $sc->api_post( 'list', { list => $LIST } );
    is( $list->{errormsg}, undef, 'no error creating list' );
    $list = $sc->api_get( 'list', { list => $LIST } );
    is( $list->{list},     $LIST, 'email list exists' );
    is( $list->{errormsg}, undef, 'no error getting list' );

    #
    # test template and preview
    #

    # check retrieving template
    $response = $sc->get_template($TEMPLATE);
    is( $response->{name},         $TEMPLATE, 'retrieved template name matches' );
    is( $response->{content_html}, "@lines",  'retrieved template matches' );
    is( $response->{error},        undef,     'no error in response' );

    # valid source
    my $source = $sc->api_post( 'blast', { copy_template => $TEMPLATE } );
    like( $source->{content_html}, qr/Hey/,       'got right result' );
    like( $source->{content_html}, qr/\Q{email}/, 'has variable' );
    unlike( $source->{content_html}, qr/\Q@{[$EMAIL]}/, 'did not find email' );
    is( $source->{error}, undef, 'no error in response' );

    # valid preview
    my $preview = $sc->api_post(
        'preview',
        {
            template => $TEMPLATE,
            email    => $EMAIL,
        }
    );
    ok( not( $preview->{error} ), 'no error in preview' );
    like( $preview->{content_html}, qr/Hey/, 'found text' );
    unlike( $preview->{content_html}, qr/\Q{email}/, 'does not have variable' );
    like( $preview->{content_html}, qr/\Q@{[$EMAIL]}/, 'found email' );
    is( $preview->{error}, undef, 'no error in response' );

    #
    # test sending
    #

    # schedule send, check that the send exists, delete send
    # test send
    my $schedule_time = "+12 hours";
    $response = $sc->send( $TEMPLATE, $EMAIL, {}, {}, $schedule_time );
    my $send_id = $response->{send_id};
    isnt( $send_id, undef, 'send created successfully' );
    is( $response->{status}, 'scheduled', 'send scheduled successfully' );
    is( $response->{error},  undef,       'no error in response' );
    # test get_send
    $response = $sc->get_send($send_id);
    is( $response->{send_id}, $send_id, 'send retrieved successfully' );
    is( $response->{error},   undef,    'no error in response' );
    # temporarily suppress deprecation warnings
    {
        no warnings 'deprecated';
        $response = $sc->getSend($send_id);
        is( $response->{send_id}, $send_id, 'send retrieved successfully with getSend (deprecated)' );
        is( $response->{error},   undef,    'no error in response' );
    }
    # delete the send
    $response = $sc->api_delete( 'send', { send_id => $send_id } );
    is( $response->{ok},    1,     'send deleted successfully' );
    is( $response->{error}, undef, 'no error in response' );

    #
    # test email subscriptions
    #

    my $email;

    # add email via api calls
    $email = $sc->api_post( 'email', { email => $EMAIL, lists => { $LIST => 1 } } );
    is( $email->{error}, undef, 'no error in response' );
    $email = $sc->api_get( 'email', { email => $EMAIL } );
    is( $email->{error},        undef, 'no error in response' );
    is( $email->{lists}{$LIST}, 1,     'is on list' );

    # remove via api call
    $email = $sc->api_post( 'email', { email => $EMAIL, lists => { $LIST => 0 } } );
    is( $email->{error}, undef, 'no error in response' );
    $email = $sc->api_get( 'email', { email => $EMAIL } );
    is( $email->{error},        undef, 'no error in response' );
    is( $email->{lists}{$LIST}, undef, 'is not on list' );

    # add via set_email/get_email
    $email = $sc->set_email( $EMAIL, {}, { $LIST => 1 } );
    is( $email->{error}, undef, 'no error in response' );
    $email = $sc->get_email($EMAIL);
    is( $email->{error},        undef, 'no error in response' );
    is( $email->{lists}{$LIST}, 1,     'is on list' );

    # remove via set_email/get_email
    $email = $sc->set_email( $EMAIL, {}, { $LIST => 0 } );
    is( $email->{error}, undef, 'no error in response' );
    $email = $sc->get_email($EMAIL);
    is( $email->{error},        undef, 'no error in response' );
    is( $email->{lists}{$LIST}, undef, 'is not on list' );

    #
    # test scheduling email blasts
    #

    SKIP: {
        skip 'requires a verified email to be set in SAILTHRU_FROM_EMAIL', 1
          if not defined $verified_from_email;

        # add email to list via set_email/get_email
        $email = $sc->set_email( $EMAIL, {}, { $LIST => 1 } );
        is( $email->{error}, undef, 'no error in response' );
        $email = $sc->get_email($EMAIL);
        is( $email->{error},        undef, 'no error in response' );
        is( $email->{lists}{$LIST}, 1,     'is on list' );

        my $blast_name    = "My new blast $TIMESTAMP";
        my $schedule_time = "+12 hours";
        my $blast_subject = "Hello! $TIMESTAMP";
        my $content_html  = "<p><b>Hello there.</b> $TIMESTAMP</p>";
        my $content_text  = "Hello there. $TIMESTAMP";
        $response =
          $sc->schedule_blast( $blast_name, $LIST, $schedule_time, 'FROM TEST',
            $verified_from_email, $blast_subject, $content_html, $content_text );
        is( $response->{error}, undef, 'no error in response' );
        my $blast_id = $response->{blast_id};
        isnt( $blast_id, undef, 'blast created successfully' );
        is( $response->{status}, 'scheduled', 'blast scheduled successfully' );
        $response = $sc->get_blast($blast_id);
        is( $response->{error},    undef,     'no error in response' );
        is( $response->{blast_id}, $blast_id, 'blast retrieved successfully' );
        $response = $sc->api_delete( 'blast', { blast_id => $blast_id } );
        is( $response->{error}, undef, 'no error in response' );
        is( $response->{ok},    1,     'blast deleted successfully' );

        $response =
          $sc->schedule_blast_from_template( $TEMPLATE, $LIST, $schedule_time,
            { from_name => 'FROM TEST', from_email => $verified_from_email, subject => 'Hey.' } );
        is( $response->{error}, undef, 'no error in response' );
        $blast_id = $response->{blast_id};
        isnt( $blast_id, undef, 'blast from template created successfully' );
        is( $response->{status}, 'scheduled', 'blast from template scheduled successfully' );
        is( $response->{error},  undef,       'no error in response' );
        $response = $sc->get_blast($blast_id);
        is( $response->{blast_id}, $blast_id, 'blast from template retrieved successfully' );
        $response = $sc->api_delete( 'blast', { blast_id => $blast_id } );
        is( $response->{error}, undef, 'no error in response' );
        is( $response->{ok},    1,     'blast from template deleted successfully' );

        # remove email from list via set_email/get_email
        $email = $sc->set_email( $EMAIL, {}, { $LIST => 0 } );
        is( $email->{error}, undef, 'no error in response' );
        $email = $sc->get_email($EMAIL);
        is( $email->{error},        undef, 'no error in response' );
        is( $email->{lists}{$LIST}, undef, 'is not on list' );
    }

    #
    # test deprecated methods
    #

    # temporarily suppress deprecation warnings
    {
        no warnings 'deprecated';
        # test deprecation of 'contacts' API
        my $r = $sc->importContacts( 'foobarbaz@gmail.com', 'foobarbaz' );
        is( $r->{error}, 99, 'importContacts returns error 99 (other).' );
        like(
            $r->{errormsg},
            qr/The contacts API has been discontinued as of August 1st, 2011/,
            'importContacts returns errormsg describing deprecation of "contacts".'
        );

        # add email to list via set_email/get_email
        $email = $sc->setEmail( $EMAIL, {}, { $LIST => 1 } );
        is( $email->{error}, undef, 'no error in response' );
        $email = $sc->getEmail($EMAIL);
        is( $email->{error},        undef, 'no error in response' );
        is( $email->{lists}{$LIST}, 1,     'is on list' );

        my $blast_name    = "My new blast $TIMESTAMP";
        my $schedule_time = "+12 hours";
        my $blast_subject = "Hello! $TIMESTAMP";
        my $content_html  = "<p><b>Hello there.</b> $TIMESTAMP</p>";
        my $content_text  = "Hello there. $TIMESTAMP";
        $response =
          $sc->scheduleBlast( $blast_name, $LIST, $schedule_time, 'FROM TEST',
            $verified_from_email, $blast_subject, $content_html, $content_text );
        is( $response->{error}, undef, 'no error in response' );
        my $blast_id = $response->{blast_id};
        isnt( $blast_id, undef, 'blast created successfully with scheduleBlast (deprecated)' );
        is( $response->{status}, 'scheduled', 'blast scheduled successfully with scheduleBlast (deprecated)' );
        $response = $sc->getBlast($blast_id);
        is( $response->{error},    undef,     'no error in response' );
        is( $response->{blast_id}, $blast_id, 'blast retrieved successfully with getBlast (deprecated)' );
        $response = $sc->api_delete( 'blast', { blast_id => $blast_id } );
        is( $response->{error}, undef, 'no error in response' );
        is( $response->{ok},    1,     'blast deleted successfully' );

        # test that template can be retrieved
        $response = $sc->getTemplate($TEMPLATE);
        is( $response->{error},        undef,     'no error in response' );
        is( $response->{name},         $TEMPLATE, 'retrieved template name matches with getTemplate (deprecated)' );
        is( $response->{content_html}, "@lines",  'retrieved template matches with getTemplate (deprecated)' );

        $response =
          $sc->copyTemplate( $TEMPLATE, '', '', 'my blast', $schedule_time, $LIST,
            { from_name => 'FROM TEST', from_email => $verified_from_email, subject => 'Hey.' } );
        is( $response->{error}, undef, 'no error in response' );
        $blast_id = $response->{blast_id};
        isnt( $blast_id, undef, 'blast from template created successfully with copyTemplate (deprecated)' );
        is( $response->{status}, 'scheduled', 'blast scheduled successfully with copyTemplate (deprecated)' );
        $response = $sc->getBlast($blast_id);
        is( $response->{error},    undef,     'no error in response' );
        is( $response->{blast_id}, $blast_id, 'blast retrieved successfully with getBlast (deprecated)' );
        $response = $sc->api_delete( 'blast', { blast_id => $blast_id } );
        is( $response->{error}, undef, 'no error in response' );
        is( $response->{ok},    1,     'blast from copyTemplate deleted successfully' );

        # remove email from list via set_email/get_email
        $email = $sc->setEmail( $EMAIL, {}, { $LIST => 0 } );
        is( $email->{error}, undef, 'no error in response' );
        $email = $sc->getEmail($EMAIL);
        is( $email->{error},        undef, 'no error in response' );
        is( $email->{lists}{$LIST}, undef, 'is not on list' );
    }

    #
    # clean up created list and template
    #

    $email = $sc->api_delete( 'list', { list => $LIST } );
    is( $email->{error}, undef, 'no error in response' );
    $email = $sc->api_get( 'list', { list => $LIST } );
    ok( $email->{error}, 'got error from deleted list' );
    is( $email->{name}, undef, 'email list does not exist' );

    # delete template, rerun preview, look for error.
    $email = $sc->api_delete( 'template', { template => $TEMPLATE } );
    is( $email->{error}, undef, 'no error in response' );

    my $no_template = $sc->api_post(
        'preview',
        {
            template => $TEMPLATE,
            email    => $EMAIL,
        }
    );

    ok( $no_template->{error}, 'got error from deleted template' );
    like( $no_template->{errormsg}, qr/template/, 'got expected error message from deleted template' );
}

done_testing;

__DATA__
<html>
<body>
<h1>Hey!!!</h1>

This is a big important message

Not really, we just use this template to test the CPAN module.

bye, {email}

<p><small>If you believe this has been sent to you in error, please safely <a href="{optout_confirm_url}">unsubscribe</a>.</small></p>
</body>
</html>
