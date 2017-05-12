# This test is for testing RT::Client::REST with a real instance of RT.
# This is so that we can verify bug reports and compare functionality
# (and bugs) between different versions of RT.

use strict;
use warnings;

use Test::More;

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        plan(skip_all => 'these tests are for release candidate testing');
    }

    if (grep { not defined $ENV{$_} } (qw(RTSERVER RTPASS RTUSER))) {
        plan(skip_all => 'one of RTSERVER, RTPASS, or RTUSER is not set');
    }
}

{
    # We will only use letters, because this string may be used for names of
    # queues and users in RT and we don't want to fail because of RT rules.
    my @chars = ('a' .. 'z', 'A' .. 'Z');
    sub random_string {
        my $retval = '';
        for (1 .. 10) {
            $retval .= $chars[ int(rand(scalar(@chars))) ];
        }
        return $retval;
    }
}

plan 'no_plan';

use Error qw(:try);
use File::Temp qw(tempfile);
use RT::Client::REST;
use RT::Client::REST::Queue;
use RT::Client::REST::User;

my $rt = RT::Client::REST->new(
    server => $ENV{RTSERVER},
);
ok($rt, "RT instance is created");

# Log in with wrong credentials and see that we get expected error
{
    my $e;
    try {
        $rt->login(username => $ENV{RTUSER}, password => "WRONG" . $ENV{RTPASS});
    } catch RT::Client::REST::AuthenticationFailureException with {
        $e = shift;
    };
    ok(defined($e), "Logging in with wrong credentials throws expected error");
}

# Now log in successfully
{
    my $e;
    try {
        $rt->login(username => $ENV{RTUSER}, password => $ENV{RTPASS});
    } catch RT::Client::REST::Exception with {
        $e = shift;
    };
    ok(!defined($e), "login is successful");
}

# Create a user
my $user_id;
my %user_props = (
    name        => random_string,
    password    => random_string,
    comments    => random_string,
    real_name   => random_string,
);
{
    my ($user, $e);
    try {
        $user = RT::Client::REST::User->new(
            rt => $rt, %user_props,
        )->store;
    } catch RT::Client::REST::CouldNotCreateObjectException with {
        $e = shift;
    };
    ok(defined($user), "user $user_props{name} created successfully, id: " . $user->id);
    ok(!defined($e), "...and no exception was thrown");
    $user_id = $user->id;
}

# Retrieve the user we just created and verify its properties
{
    my $user = RT::Client::REST::User->new(rt => $rt, id => $user_id);
    my $e;
    try {
        $user->retrieve;
    } catch Exception::Class::Base with {
        $e = shift;
        diag("fetching user threw $e");
    };
    ok(!defined($e), "fetched user without exception being thrown");
    while (my ($prop, $val) = each(%user_props)) {
        next if $prop eq 'password';    # This property comes back obfuscated
        is($user->$prop, $val, "user property `$prop' matches");
    }
}

# Create a queue
my $queue_name = random_string;
my $queue_id;
{
    my ($queue, $e);
    try {
        $queue = RT::Client::REST::Queue->new(
            rt => $rt, name => $queue_name,
        )->store;
        $queue_id = $queue->id;
    } catch Exception::Class::Base with {
        $e = shift;
        diag("queue store: $e");
    };
    ok($queue, "Create queue $queue_name");
    ok(!defined($e), "created queue without exception being thrown");
    try {
        $queue = RT::Client::REST::Queue->new(
            rt => $rt, id => $queue_id,
        )->retrieve;
    } catch Exception::Class::Base with {
        $e = shift;
        diag("queue retrieve $e");
    };
    is($queue->name, $queue_name, "queue name matches");
    # TODO: with 4.2.3, warning "Unknown key: disabled" is printed
}

# Create a ticket
my $ticket_id;
{
    my ($ticket, $e);
    try {
        $ticket = RT::Client::REST::Ticket->new(
            rt => $rt, queue => $queue_id, subject => random_string,
        )->store(text => random_string);
    } catch Exception::Class::Base with {
        $e = shift;
        diag("ticket store: $e");
    };
    ok(defined($ticket), "Created ticket " . $ticket->id);
    ok(!defined($e), "No exception thrown when ticket created");
    $ticket_id = $ticket->id;
}

# Attach something to the ticket and verify its count and contents
{
    my $att_contents = "dude this is a text attachment\n";
    my ($fh, $filename) = tempfile;
    $fh->print($att_contents);
    $fh->close;
    my $e;
    try {
        RT::Client::REST::Ticket->new(
            rt => $rt, id => $ticket_id,
        )->comment(
            message     => random_string,
            attachments => [ $filename ],
        );
    } catch Exception::Class::Base with {
        diag("attach to ticket: $e");
        $e = shift;
    };
    ok(!defined($e), "create attachment and no exception thrown");
    unlink $filename;
    try {
        my $ticket = RT::Client::REST::Ticket->new(
            rt => $rt, id => $ticket_id,
        );
        my $atts = $ticket->attachments;
        # XXX With RT 4.2.3, the count is 4.  Is it the same with previous
        # versions or is this a change in behavior?
        is($atts->count, 1, "There is one attachment to ticket $ticket_id");
        my $att_iter = $atts->get_iterator;
        while (my $att = &$att_iter) {
            is($att->content, $att_contents, "Attachment content matches");
        }
    } catch Exception::Class::Base with {
        diag("attach to ticket: $e");
        $e = shift;
    };
    ok(!defined($e), "listed attachments and no exception thrown");
}

# TODO: RT 90112: Attachment retrieval returns wrongly decoded files
