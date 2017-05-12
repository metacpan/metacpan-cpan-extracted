#!/usr/bin/env perl
# PODNAME: graylog API test
# ABSTRACT: Test connection to the graylog API

# the purpose of these tests is to prove that the generated API works as expected
# it is not to test that graylog works as expected, so we will test only a few
# of the possible methods and assume that the rest will work
# we test initially just a few standard methods and then the majority of the user methods
# as these cover get/put/post/delete actions

# (c) kevin Mulholland 2014, moodfarm@cpan.org
# this code is released under the Perl Artistic License
# extra info at http://support.torch.sh/help/kb/graylog2-server/using-the-gelf-http-input

use 5.10.0;
use strict;
use warnings;
use POSIX qw( strftime);
use Data::Printer;
use App::Basis;
use App::Basis::Config;
use Data::UUID;
use Net::Graylog::Client qw( valid_levels);

use Test::More tests => 2;

my $SERVER   = 'sei';
my $USER     = 'test';
my $PASSWORD = 'password';

BEGIN { use_ok('Net::Graylog::API'); }

sub add_data {
    my ($key)          = @_;
    my $events_created = 0;
    my $du             = Data::UUID->new();
    my $uuid           = $du->create_str();

    my $started = time();
    note("Creating messages with tag:$uuid and key $key");
    my $graylog = Net::Graylog::Client->new( url => "http://$SERVER:12202/gelf" );

    foreach my $lvl ( valid_levels() ) {
        my ( $s, $c ) = $graylog->$lvl(
            message  => "a $lvl message with key $key",
            tag      => $uuid,
            counter  => $events_created + 1,
            testmode => 1
        );
        $events_created++ if ($s);
    }
    note( "Sending $events_created events took " . ( time() - $started ) . "s" );

    return $events_created;
}

# -----------------------------------------------------------------------------
# ready to build the message to send

SKIP: {

    if ( $ENV{AUTHOR_TESTING} ) {

        subtest 'authors_own' => sub {
            plan tests => 7;
            my ( $resp, $messages );

            # this is a uniq key for this series of tests
            my $ukey = $$ . "-" . time();

            my $url = "http://$SERVER:12900";
            my $api = Net::Graylog::API->new( url => $url, user => 'test', password => 'Passw0rd1', timeout => 2 );

            # $resp = $api->system();
            # my $system = $resp->{json};
            # ok( $system && $system->{facility}, 'The system responds' );

            # $resp = $api->counts_total;
            # ok( $resp->{code} == 200 && $resp->{json} && $resp->{json}->{events} >= $events_created,
            #     "counts_total: There are more than $events_created events" );

            # # we need to add some data for the search tests
            my $events_created = add_data($ukey);

            # give graylog a second or so to store and process the messages
            sleep 1;

            # find events that have our key
            $resp = $api->search_absolute_search_absolute( query => $ukey, from => '2014-03-20 00:00:00', to => '2015-01-01 00:00:00' );
            $messages = $resp->{json}->{messages};
            ok( $resp->{code} == 200 && $resp->{json} && scalar @{$messages} == $events_created,
                "search_absolute_search_absolute: found $events_created created events absolutely found"
            );
            # if ( $messages && scalar @{$messages} != $events_created ) {
            #     diag( scalar( @{$messages} ) . " / $events_created events" );
            #     diag( "issue data: " . p($resp) );
            # }

            # badly formatted dates should cause a 400 response from the server, these date fields are not
            # validated though
            $resp = $api->search_absolute_search_absolute( query => $ukey, from => '2014:00:00', to => '2015-01:00' );
            ok( $resp->{code} == 400, "search_absolute_search_absolute: correct badly formatted date response" );

            sleep 1;
            $resp = $api->search_keyword_search_keyword( query => $ukey, keyword => 'last hour' );
            $messages = $resp->{json}->{messages};
            ok( $resp->{code} == 200 && $resp->{json} && scalar @{$messages}, "search_keyword_search_keyword: found some events found in last hour" );
            # if ( $messages && scalar @{$messages} != $events_created ) {
            #     diag( scalar( @{$messages} ) . " / $events_created events" );
            #     diag( "issue data: " . p($resp) );
            # }

            # cannot test streams until we have some
            $resp = $api->streams_get();
            my $streams = $resp->{json};
            ok( $streams && defined( $streams->{streams} ), 'streams_get: Streams responds' );

            $resp = $api->system_notifications_list_notifications();
            my $noti = $resp->{json};
            ok( $noti && defined $noti->{notifications}, 'system_notifications_list_notifications: ' );

            # now that we have tested the general use of the API we should test that all types
            # of call work, users has a full set of get/put/post/delete actions as well as
            # a json body (post) action, so should test the full range of the API generation
            $resp = $api->users_list_users();
            my $users = $resp->{json};
            ok( $users, 'users_list_users: There are users' );

            # this test shows that {username} is replaced in the URL
            $resp = $api->users_get( username => 'test' );
            my $user = $resp->{json};
            ok( $user && $user->{username} eq 'test', 'I am the test user' );

            # setup the user details for creation
            my %details = (
                username        => "test$$",
                fullname        => "user for test $$",
                email           => "testuser\@test$$.org",
                password        => "password123",
                password_repeat => "password123",

                # admin           => '0',

                # permissions => 'users: list',     # not currently implemented?
                # timezone              => 'Etc/UTC',
                # session_timeout_never => '1',
                timeout      => '60',
                timeout_unit => 'minutes',    # seconds minutes hours days
            );

            # none of the other API calls can be tested yet due to lacking documentation
            # $resp = $api->users_create( 'JSON body' => \%details );
            # diag( p($resp) );

            # $resp = $api->users_change_user() ;
            # $resp = $api->users_delete_user() ;
            # $resp = $api->users_change_password() ;
            # $resp = $api->users_edit_permissions() ;
            # $resp = $api->users_delete_permissions() ;
            # $resp = $api->users_list_tokens() ;
            # $resp = $api->users_generate_new_token() ;
            # $resp = $api->users_revoke_token() ;

        };
    }
    else {
        subtest 'not_author' => sub {
            plan tests => 1;
            my $url  = 'http://fred.fred.com:12900';
            my $api  = Net::Graylog::API->new( url => $url, user => $USER, password => $PASSWORD, debug => 0 );
            my $resp = $api->counts_total;

            # we should get a 404 at least
            ok( $resp->{code} == 500, 'Call made, could not connect as expected' );
        };
    }
}

# -----------------------------------------------------------------------------
# all done
