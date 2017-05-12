#!perl -w

use strict;
use Net::Google::Calendar;
use Net::Google::Calendar::Calendar;
use lib qw(t/lib);
use GCalTest;
use Test::More;

my $cal = eval { GCalTest::get_calendar('login') };
if ($@) {
    plan skip_all => "because $@";
} else {
    plan tests => 22;
}


# Get a list of calendars
my @calendars;
ok(@calendars = $cal->get_calendars(), "Got calendars");

# Should contain default
is(scalar(@calendars), 1, "We've got 1 calendar");
my $default = $calendars[0];

# Create a new calendar
my $new_cal = Net::Google::Calendar::Calendar->new;
$new_cal->title("Foo");
$new_cal->summary("A new test calendar");
ok($cal->add_calendar($new_cal), "Added calendar");

# Check reference
my $updated = $new_cal->updated;
isnt($updated, undef, "Updated was supplied");

# Get list again
ok(@calendars = $cal->get_calendars(), "Got calendars again");
is(scalar(@calendars), 2, "We've got 2 calendars");

sleep(1);

# Update
$new_cal->summary("Updated test calendar");
ok($cal->update_calendar($new_cal), "Updated calendar");

# Check reference
isnt($new_cal->updated, $updated, "Not same updated time");

# Get list again
ok(@calendars = $cal->get_calendars(), "Got calendars again");
is(scalar(@calendars), 2, "We've still got 2 calendars");

# Check list version
# TODO this is brittle - need to grep out
is($calendars[1]->title, $new_cal->title, "List version title is the same");

# Delete
ok($cal->delete_calendar($calendars[1], 1), "Deleted calendar");

# Get list
ok(@calendars = $cal->get_calendars(), "Got calendars again");
is(scalar(@calendars), 1, "We've still got 1 calendar again");

# Add another calendar
$new_cal = Net::Google::Calendar::Calendar->new;
$new_cal->title("Foo again");
$new_cal->summary("A new test calendar again");
ok($cal->add_calendar($new_cal), "Added another calendar");
ok($cal->set_calendar($new_cal), "Set the calendar");

# Add event to one calendar
my $entry  = Net::Google::Calendar::Entry->new();
$entry->title("Testing");
ok($cal->add_entry($entry), "Added entry");
is(scalar($cal->get_events()), 1, "Got entry back");

# Check another
ok($cal->set_calendar($default), "Set the calendar again");
is(scalar($cal->get_events()), 0, "Got no entries back");

# Delete event
ok($cal->set_calendar($new_cal), "Set the calendar again");
ok($cal->delete_calendar($new_cal, 1), "Deleted calendar again");


