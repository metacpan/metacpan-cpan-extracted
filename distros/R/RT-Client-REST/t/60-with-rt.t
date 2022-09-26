#!perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

# This test is for testing RT::Client::REST with a real instance of RT.
# This is so that we can verify bug reports and compare functionality
# (and bugs) between different versions of RT.

use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw/ splitpath /;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        plan( skip_all => 'these tests are for release candidate testing' );
    }

    if ( grep { not defined $ENV{$_} } (qw(RTSERVER RTPASS RTUSER)) ) {
        plan( skip_all => 'one of RTSERVER, RTPASS, or RTUSER is not set' );
    }
}

{
    # We will only use letters, because this string may be used for names of
    # queues and users in RT and we don't want to fail because of RT rules.
    my @chars = ( 'a' .. 'z', 'A' .. 'Z' );

    sub random_string {
        my $retval = '';
        for ( 1 .. 10 ) {
            $retval .= $chars[ int( rand( scalar(@chars) ) ) ];
        }
        return $retval;
    }
}

plan 'no_plan';

use Try::Tiny;
use File::Temp qw(tempfile);
use RT::Client::REST;
use RT::Client::REST::Queue;
use RT::Client::REST::User;

my $rt = RT::Client::REST->new( server => $ENV{RTSERVER}, );
ok( $rt, 'RT instance is created' );

# Log in with wrong credentials and see that we get expected error
{
    my $e;
    try {
        $rt->login(
            username => $ENV{RTUSER},
            password => 'WRONG' . $ENV{RTPASS}
        );
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('RT::Client::REST::AuthenticationFailureException') ) {
            $e = $_;
        }
        else {
            $_->rethrow;
        }
    };
    ok( defined($e),
        'Logging in with wrong credentials throws expected error' );
}

# Now log in successfully
{
    my $e;
    try {
        $rt->login( username => $ENV{RTUSER}, password => $ENV{RTPASS} );
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('RT::Client::REST::Exception') ) {
            $e = $_;
        }
        else {
            $_->rethrow;
        }
    };
    ok( !defined($e), 'login is successful' );
}

# Create a user
my $user_id;
my %user_props = (
    name      => random_string(),
    password  => random_string(),
    comments  => random_string(),
    real_name => random_string(),
);
{
    my ( $user, $e );
    try {
        $user = RT::Client::REST::User->new(
            rt => $rt,
            %user_props,
        )->store;
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('RT::Client::REST::CouldNotCreateObjectException') ) {
            $e = $_;
        }
        else {
            $_->rethrow;
        }
    };
    ok( defined($user),
        "user $user_props{name} created successfully, id: "
          . ( defined $user ? $user->id : 'UNDEF' ) );
    ok( !defined($e), '...and no exception was thrown' );
    $user_id = $user->id;
}

# Retrieve the user we just created and verify its properties
{
    my $user = RT::Client::REST::User->new( rt => $rt, id => $user_id );
    my $e;
    try {
        $user->retrieve;
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("fetching user threw $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( !defined($e), 'fetched user without exception being thrown' );
    while ( my ( $prop, $val ) = each(%user_props) ) {
        next if $prop eq 'password';    # This property comes back obfuscated
        is( $user->$prop, $val, "user property `$prop' matches" );
    }
}

# Create a queue
my $queue_name = 'A queue named ' . random_string();
my $queue_id;
my $queue;
{
    my $e;
    try {
        $queue = RT::Client::REST::Queue->new(
            rt   => $rt,
            name => $queue_name,
        )->store;
        $queue_id = $queue->id;
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("test queue store: $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( $queue,       "Create test queue '$queue_name'" );
    ok( !defined($e), 'created test queue without exception being thrown' );
}
{
    my $e;
    try {
        $queue = RT::Client::REST::Queue->new(
            rt => $rt,
            id => $queue_id,
        )->retrieve;
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("queue retrieve $e");
        }
        else {
            $_->rethrow;
        }
    };
    is( $queue->name, $queue_name, 'test queue name matches' );

    # TODO: with 4.2.3, warning "Unknown key: disabled" is printed
}

# Create a ticket
my $ticket;
{
    my $e;
    my $subject = 'This is a subject ' . random_string();
    try {
        $ticket = RT::Client::REST::Ticket->new(
            rt      => $rt,
            queue   => $queue_id,
            subject => $subject,
        )->store( text => 'Some random text ' . random_string() );
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("ticket store: $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( defined($ticket),
        "Created ticket '$subject' ID " . ( defined $ticket ? $ticket->id : 'UNDEF' ) );
    ok( !defined($e), 'No exception thrown when ticket created' );
}

# Attach something to the ticket and verify its count and contents
{
    my $att_contents = "dude this is a text attachment\n";
    my ( $fh, $filename ) = tempfile;
    $fh->print($att_contents);
    $fh->close;
    my $message = 'This is a message ' . random_string(),
    my $e;
    try {
        $ticket->comment(
            message     => $message,
            attachments => [$filename],
        );
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("attach to ticket: $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( !defined($e), 'Create attachment and no exception thrown' );
    unlink $filename;
    $e = undef;
    try {
        my $atts = $ticket->attachments;

        # XXX With RT 4.2.3, the count is 4. Is it the same with previous
        # versions or is this a change in behavior?
        is( $atts->count, 4, 'There are 4 attachment to ticket ' . $ticket->id );
        my $att_iter = $atts->get_iterator;
        my $basename = (splitpath($filename))[2];
        my ($att) = grep { $_->file_name eq $basename } &$att_iter;
        if ($att) {
            ok(1, "Found attachment with filename: $basename");
            is( $att->content, $att_contents, 'Attachment content matches' );
        }
        else {
            ok(0, "Found attachment with filename: $basename");
        }

    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("attach to ticket: $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( !defined($e), 'listed attachments and no exception thrown' );
}
# Comment with HTML
{
    my $message = sprintf('Some <b>html</b> message text <pre>%s</pre>', random_string());
    my $e;
    try {
        $ticket->comment(
            message => $message,
            html    => 1
        );
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("attach to ticket: $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( !defined($e), 'Add html comment and no exception thrown' );
    try {
        my $atts = $ticket->attachments;
        my $att_iter = $atts->get_iterator;
        my $att = (&$att_iter)[-1];
        if ($att) {
            ok(1, 'Retrieved final attachment');
            is( $att->content_type, 'text/html', 'Content-Type is text/html' );
        }
        else {
            ok(0, 'Retrieved final attachment');
        }

    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("attach to ticket: $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( !defined($e), 'listed attachments and no exception thrown' );
}

# Search for tickets (with format s)
{
    my (@results, $e);
    try {
        @results = $rt->search(
            type => 'ticket',
            query => "Queue='$queue_name'",
            format => 's'
        )
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("searching for tickets (with format s): $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( scalar @results > 0, 'Found some results (with format s)' );
    is_deeply( \@results, [[ $ticket->id, $ticket->subject ]], 'Search results as expected (with format s)' );
    ok( !defined($e), 'No exception thrown when searching tickets (with format s)' );
}

# Delete the ticket
{
    my $e;
    try {
        $ticket->status('deleted');
        $ticket->store;
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("delete ticket: $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( !defined($e), 'ticket deleted and no exception thrown' );
}

# TODO: RT 90112: Attachment retrieval returns wrongly decoded files

# Disable the queue
{
    my $e;
    try {
        $queue->disabled(1);
        $queue->store;
    }
    catch {
        die $_ unless blessed $_ && $_->can('rethrow');
        if ( $_->isa('Exception::Class::Base') ) {
            $e = $_;
            diag("disable test queue: $e");
        }
        else {
            $_->rethrow;
        }
    };
    ok( !defined($e), 'disabled queue without exception being thrown' );
}

