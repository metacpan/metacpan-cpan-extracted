# Template for writing a new tests

use 5.006;
use strict;
use warnings;
use feature 'say';

use Data::Dumper;
use Data::Printer;
$Data::Dumper::Maxdepth = 3;

use DateTime;
use DateTime::Format::RFC3339;
my $formatter = DateTime::Format::RFC3339->new();

use Moo::Google;

use Test::More;

my $default_file = $ENV{'GOOGLE_TOKENSFILE'} || 'gapi.conf';
my $user         = $ENV{'GMAIL_FOR_TESTING'} || 'pavel.p.serikov@gmail.com';

# my $user = $ENV{'GMAIL_FOR_TESTING'} || 'fablab61ru@gmail.com';
my $gapi = Moo::Google->new( debug => 0 );

if ( $gapi->auth_storage->file_exists($default_file) ) {
    $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } );
    $gapi->user($user);

    my $calendarId = 'primary';    # same as $user
    my @event_ids;
    my $maxResults = 5
      ; # how much events will be added to test right filtration by  maxResults in Events->list

    subtest 'Events->insert' => sub {
        ## add some 2-hours events
        my $t;

        for ( my $i = 1 ; $i <= $maxResults ; $i++ ) {

            print $i;

            $t = $gapi->Calendar->Events->insert(
                {
                    calendarId => $calendarId,
                    options    => {
                        start => {
                            dateTime =>
                              $formatter->format_datetime( DateTime->now() )
                        },
                        end => {
                            dateTime => $formatter->format_datetime(
                                DateTime->now()->add_duration(
                                    DateTime::Duration->new( hours => 2 )
                                )
                            )
                        },
                        summary => "Moo::Google test event number" . $i
                    }
                }
            )->json;

            push @event_ids, $t->{id};
        }

        warn "Inserted event ids: " . Dumper \@event_ids;

        # test last response structure
        ok( ref($t) eq 'HASH', "returned an ARRAY" );
        ok(
            $t->{kind} eq 'calendar#event',
            "kind seems like OK - calendar#event"
        );
        ok( $t->{organizer}{email} eq $user, "organizer user email is OK" );
        ok( $t->{creator}{email} eq $user,   "creator email is OK" );
    };

    subtest 'Events->get' => sub {
        my $t = $gapi->Calendar->Events->get(
            { calendarId => $calendarId, eventId => $event_ids[0] } )->json;
        ok( ref($t) eq 'HASH', "returned an ARRAY" );
        ok(
            $t->{kind} eq 'calendar#event',
            "kind seems like OK - calendar#event"
        );
    };

    subtest 'Events->list' => sub {
        my $t;

        for ( my $i = 2 ; $i <= $maxResults ; $i++ )
        {    # working for not every email - possible bug
            $t = $gapi->Calendar->Events->list(
                { calendarId => $calendarId, options => { maxResults => $i } } )
              ->json;
            ok( scalar @{ $t->{items} } == $i, "maxResults =" . $i );
        }

        # test last response structure
        # warn Dumper $t;
        ok( ref($t) eq 'HASH', "returned a single item" );
        ok(
            $t->{kind} eq 'calendar#events',
            "kind seems like OK - calendar#events"
        );
        ok(
            $t->{items}[0]{kind} eq 'calendar#event',
            "kind seems like OK - calendar#events"
        );
    };

    # delete one event from @event_ids

    subtest 'Events->delete' => sub {
        my $r1 =
          $gapi->Calendar->Events->list( { calendarId => $calendarId } )->json;
        my $n1        = scalar @{ $r1->{items} };
        my $id_to_del = $event_ids[0];                     # may do rand
        my $r2        = $gapi->Calendar->Events->delete(
            { calendarId => $calendarId, eventId => $id_to_del } );
        my $r3 =
          $gapi->Calendar->Events->list( { calendarId => $calendarId } )->json;
        my $n2 = scalar @{ $r3->{items} };
        ok( $r2->code == 204, 'response code is 204' );
        ok( $n2 eq $n1 - 1,   'items minus 1' );
    };

}
else {
    say 'Cant run test cause json file with tokens not exists!';
}

done_testing();
