use 5.006;
use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use Data::Printer;
$Data::Dumper::Maxdepth = 2;

use Moo::Google;

use Test::More;

my $default_file = $ENV{'GOOGLE_TOKENSFILE'} || 'gapi.conf';
my $user         = $ENV{'GMAIL_FOR_TESTING'} || 'pavel.p.serikov@gmail.com';
my $gapi = Moo::Google->new( debug => 0 );

if ( $gapi->auth_storage->file_exists($default_file) ) {
    $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } );
    $gapi->user($user);

    my $id;    # will be id of primary calendar
    my $demo_calendar_id =
      'russ_11874_%46%43+%52ostov#sports@group.v.calendar.google.com';

# DELETE https://www.googleapis.com/calendar/v3/users/me/calendarList/calendarId

    subtest 'CalendarList->list' => sub {
        my $t = $gapi->Calendar->CalendarList->list->json;
        warn "List: " . Dumper $t;
        ok( ref( $t->{items} ) eq 'ARRAY', "returned an ARRAY" );
        ok(
            scalar @{ $t->{items} } > 0,
            "ARRAY isn't empty (user must have at least one primary calendar)"
        );
        ok(
            $t->{items}[0]{kind} eq 'calendar#calendarListEntry',
            "kind seems like OK - calendar#calendarListEntry"
        );
        $id = $t->{items}[0]{id};
    };

    subtest 'CalendarList->get' => sub {
        my $t =
          $gapi->Calendar->CalendarList->get( { calendarId => $id } )->json;

        # warn "List: ".Dumper $t;
        ok( ref($t) eq 'HASH', "returned single item" );
        ok(
            $t->{kind} eq 'calendar#calendarListEntry',
            "kind seems like OK - calendar#calendarListEntry"
        );
        ok( $t->{id} eq $id,
            "got calendar with right id (previously listed first)" );
    };

    subtest 'CalendarList->insert' => sub {

        # add FC Rostov calendar to your Google Calendar
        my $t = $gapi->Calendar->CalendarList->insert(
            {
                options => {    # CalendarList resource
                    id               => $demo_calendar_id,
                    defaultReminders => [
                        {
                            method  => 'popup',
                            minutes => 15
                        }
                    ],
                    notificationSettings => {
                        notifications => [
                            {
                                type   => 'agenda',
                                method => 'email'
                            }
                        ]
                    }
                }
            }
        )->json;
        warn Dumper $t;
        ok( $t->{summary} eq 'FC Rostov',
            "FC Rostov calendar was inserted in your GCal" );
    };

# return 404 instead of 204
# subtest 'CalendarList->delete' => sub {
#   my $r = $gapi->Calendar->CalendarList->delete({ calendarId => $demo_calendar_id });
#   warn $r->code;
#   ok($r->is_empty, 'FC Rostov calendar was deleted');
# };

}
else {
    say 'Cant run test cause json file with tokens not exists!';
}

done_testing();
