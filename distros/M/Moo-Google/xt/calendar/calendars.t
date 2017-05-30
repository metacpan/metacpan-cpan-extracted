#!perl -T

# run it with 'prove -l -v xt'
# you can also set $ENV{'GOOGLE_TOKENSFILE'} and $ENV{'GMAIL_FOR_TESTING'}
# export GOOGLE_TOKENSFILE='cat.txt'

# https://developers.google.com/google-apps/calendar/v3/reference/

use 5.006;
use strict;
use warnings;
use feature 'say';
use Test::More;

# use lib 'lib'; # to test without dzil install
use Moo::Google;
use Data::Dumper;
use Data::Printer;
$Data::Dumper::Maxdepth = 1;

# $SIG{'__WARN__'} = sub { warn $_[0] unless (caller eq "Moo::Google"); };
# $SIG{'__WARN__'} = sub { warn $_[0] unless (caller eq "Moo::Google::Client"); };

use Test::More;

# use Test::More tests => 3;

# $ENV{'GMAIL_FOR_TESTING'} = 'pavel.p.serikov@gmail.com';
my $default_file = $ENV{'GOOGLE_TOKENSFILE'} || 'gapi.conf';
my $user         = $ENV{'GMAIL_FOR_TESTING'} || 'pavel.p.serikov@gmail.com';

# warn $user;
my $gapi = Moo::Google->new( debug => 0 );

if ( $gapi->auth_storage->file_exists($default_file) ) {
    $gapi->auth_storage->setup( { type => 'jsonfile', path => $default_file } );
    $gapi->user($user);

    ######################################## Calendars ###############
   # Insert new calendar
   # Test of clear (5), delete (6), get (2,7), insert (1), patch (4), update (3)
   # number in () -> sequence of subtest

    my $id;    # id of future created calendar
    my $sample_summary = 'New calendar';
    my $new_summary1   = 'New summary 1';
    my $new_summary2   = 'New summary 2';

    subtest 'Calendars->insert() subtest' => sub {
        my $t = $gapi->Calendar->Calendars->insert(
            { options => { summary => $sample_summary } } )->json;
        ok( ref($t) eq 'HASH',
            "Fine, insert() method returned a HASH, not ARRAY structure" );
        ok( $t->{summary} eq $sample_summary );
        ok( $t->{kind} eq 'calendar#calendar' );
        $id = $t->{id};
        warn "ID of new calendar:" . $id;
    };

    subtest 'Calendars->get() subtest' => sub {
        my $t = $gapi->Calendar->Calendars->get( { calendarId => $id } )->json;
        ok( ref($t) eq 'HASH',
            "Fine, get() method returned a HASH, not ARRAY structure" );
        ok( $t->{summary} eq $sample_summary );
        ok( $t->{kind} eq 'calendar#calendar' );
        ok( $t->{timeZone} eq 'UTC' )
          ;    # New calendar will be in UTC timezone by default
    };

    subtest 'Calendars->update() subtest' => sub {
        my $t = $gapi->Calendar->Calendars->update(
            { calendarId => $id, options => { summary => $new_summary1 } } )
          ->json;
        ok( ref($t) eq 'HASH',
            "Fine, get() method returned a HASH, not ARRAY structure" );
        ok( $t->{summary} eq $new_summary1 );
        ok( $t->{kind} eq 'calendar#calendar' );
    };

    subtest 'Calendars->patch() subtest' => sub {
        my $t = $gapi->Calendar->Calendars->patch(
            { calendarId => $id, options => { summary => $new_summary2 } } )
          ->json;
        ok( ref($t) eq 'HASH',
            "Fine, get() method returned a HASH, not ARRAY structure" );
        ok( $t->{summary} eq $new_summary2 );
        ok( $t->{kind} eq 'calendar#calendar' );
    };

# calendar that you inserted isn't a primary calendar, by default it's secondary
    subtest 'Calendars->clear() subtest' => sub {
        my $t =
          $gapi->Calendar->Calendars->clear( { calendarId => $id } )->json;
        ok( $t->{error}{message} eq 'Cannot clear primary calendar.' );
    };

    subtest 'Calendars->delete() subtest' => sub {
        ok( $gapi->Calendar->Calendars->delete( { calendarId => $id } )
              ->is_empty );
    };

}
else {
    say 'Cant run test cause json file with tokens not exists!';
}

done_testing();
