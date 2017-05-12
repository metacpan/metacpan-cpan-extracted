#!perl -w

use strict;
use Net::Google::Calendar;
use XML::Atom::Feed;
use lib qw(t/lib);
use GCalTest;
use Test::More;

my $cal = eval { GCalTest::get_calendar('login') };
if ($@) {
    plan skip_all => "because $@";
} else {
    plan tests => 6;
    #plan skip_all => "Can't for the life of me get this to work";
}

use_ok("Net::Google::Calendar::FeedLink");
use_ok("Net::Google::Calendar::Comments");


my @events = eval { $cal->get_events() };
is($@, '', "Got events");

# should be none
is(scalar(@events), 0, "No events so far");

# create an event
my $title  = "Test attendee event ".time();
my $entry  = Net::Google::Calendar::Entry->new();
$entry->title($title);

# add it
my $saved;
if (@events){
	$saved = $events[0];
} else {
	$saved  = $cal->add_entry($entry);
}
ok($saved, "Saved entry");

eval {
# get the comment url
my $fl   = $saved->comments->feed_link;
my $uri  = $fl->href;
my $feed = $cal->get_feed($uri);

my $comment = Net::Google::Calendar::Entry->new;

my $atom = XML::Atom::Namespace->new(atom => 'http://www.w3.org/2005/Atom');

$feed = XML::Atom::Feed->new;
my $link = XML::Atom::Link->new;
$link->type('application/xml');
$link->rel('http://schemas.google.com/g/2005#post');
$link->href("$uri");
$feed->add_link($link);


my %ns = (
	atom  => 'http://www.w3.org/2005/Atom',
	gAcl  => 'http://schemas.google.com/acl/2007',	
	batch => 'http://schemas.google.com/gdata/batch',
	gCal  => 'http://schemas.google.com/gCal/2005',
	gd    => 'http://schemas.google.com/g/2005',
);

foreach my $key (keys %ns) {
	$feed->set_attr("xmlns:${key}" => $ns{$key});
}


$comment->set($atom, 'category', undef, { scheme => 'http://schemas.google.com/g/2005#kind', term => 'http://schemas.google.com/g/2005#message' } );

$comment->set($atom, 'content', "test comment", { type => 'text' });
my $author = XML::Atom::Person->new;
$author->set($atom, 'name', "Simon Wistow");
$author->set($atom, 'email', $ENV{GCAL_TEST_USER});
$comment->set($atom, 'author', $author);


#$feed->add_entry($comment);
$feed->set($atom, 'entry', $comment, {}, 1);

print $feed->as_xml;

my $return = $cal->update_feed($feed);
die $@ unless defined $return;
print $return->as_xml;

# create a new feed 
};
print "Error: $@\n" if $@;
ok($cal->delete_entry($saved), "Deleted entry");

