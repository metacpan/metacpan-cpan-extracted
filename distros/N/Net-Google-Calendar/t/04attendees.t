#!perl -w

use strict;
use Net::Google::Calendar;
use Net::Google::Calendar::Person;
use lib qw(t/lib);
use GCalTest;
use Test::More;

my $cal = eval { GCalTest::get_calendar('login') };
if ($@) {
    plan skip_all => "because $@";
#} elsif (!defined $ENV{GCAL_TEST_ATTENDEE} || !defined $ENV{GCAL_TEST_ATTENDEE_NAME}) {
#    plan skip_all => "because you need have set GCAL_TEST_ATTENDEE and GCAL_TEST_ATTENDEE_NAME environment variables which are the details of a real user";
} else {
    plan tests => 26;
}

my $email  = $ENV{GCAL_TEST_ATTENDEE}      || 'test@example.com';
my $name   = $ENV{GCAL_TEST_ATTENDEE_NAME} || 'Tester';
my $status = 'declined';
my $type   = 'required';
my $rel    = 'organizer';


# get events
my @events = eval { $cal->get_events() };
is($@, '', "Got events");

# should be none
is(scalar(@events), 0, "No events so far");

# create an event
my $title  = "Test attendee event ".time();
my $entry  = Net::Google::Calendar::Entry->new();
$entry->title($title);

my $who    = Net::Google::Calendar::Person->new;


# name
ok($who->name($name), "Added name");

# email
ok($who->email($email), "Added email");

# type
eval { $who->attendee_type('useless') };
isnt($@, '', "Caught bogus attendee_type");
eval { $who->attendee_type($type) };
is($@, '', "Set attendee_type");

# status
eval { $who->attendee_status('useless') };
isnt($@, '', "Caught bogus attendee_status");
eval { $who->attendee_status($status) };
is($@, '', "Set attendee_status");




# rel 
eval { $who->rel('useless') };
isnt($@, '', "Caught bogus rel");
eval { $who->rel($rel) };
is($@, '', "Set rel");


ok($entry->who($who), "Added person");

ok($cal->add_entry($entry), "Added an entry");



# get events again
ok(@events = $cal->get_events(), "Got events again");

# should be one
is(scalar(@events), 1, "Got an event");

SKIP: {

skip "Couldn't get events back", 9 unless scalar(@events);

my @who = $events[0]->who;
ok(scalar(@who), "Got people back");
skip "Couldn't get people back ", 8 unless scalar(@who);


my $new_who = $who[0];


# name again
SKIP: {
	skip "Google Bug", 2;
	is($new_who->name, $name, "Got name");
	is($new_who->name, $who->name, "Got same name");
}

# email again
is($new_who->email, $email, "Got email");
is($new_who->email, $who->email, "Got same email");

# status again
is($new_who->attendee_status(), $status, "Got attendee status");
is($new_who->attendee_status(), $who->attendee_status(), "Got same attendee status");


SKIP: {
	skip "Not implemented by Google", 2;	
	# type again
	is($new_who->attendee_type(), $type, "Got attendee type");
	is($new_who->attendee_type(), $who->attendee_type(), "Got same attendee type");
}

SKIP: {
	skip "Google Bug", 2;
	# rel again
	is($new_who->rel(), $rel, "Got attendee rel");
	is($new_who->rel(), $who->rel(), "Got same rel");
}

# delete
ok($cal->delete_entry($entry), "Deleted");

}
