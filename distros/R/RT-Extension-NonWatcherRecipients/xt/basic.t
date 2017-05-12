use strict;
use warnings;

use RT::Extension::NonWatcherRecipients::Test tests => undef;

use_ok('RT::Extension::NonWatcherRecipients');

my $user = RT::User->new(RT->SystemUser);
$user->Load('root');
$user->SetEmailAddress('root@example.com');

my $t = RT::Ticket->new($user);
my ($id, $msg) = $t->Create(
    Queue => 'General',
    Subject => 'Test ticket',
    Content => 'This is a test',
    Requestor => ['root'],
    );

ok( $t->id, 'Create test ticket: ' . $t->id);

diag "Unknown user without a record and filtering of existing watcher";
{
    my ($txn_id, $txn_msg, $txn_obj) = $t->Correspond(
         CcMessageTo => 'sharkbanana@bestpractical.com, root@example.com',
         Content => 'This is a test' );

    ok( $txn_id, "Created transaction: $txn_id $txn_msg");

    my $message = RT::Extension::NonWatcherRecipients->FindRecipients(
        Transaction => $txn_obj,
        Ticket => $t);

    like( $message, qr/The following people received a copy/, 'Got message');
    like( $message, qr/sharkbanana\@bestpractical\.com/, 'Got email address');
    unlike( $message, qr/root\@example\.com/, "root's email address is excluded");
}

diag "Existing user record, but not a watcher";
{
    my $foo = RT::User->new( RT->SystemUser );
    my ($ok, $msg) = $foo->Create( Name => 'foo', EmailAddress => 'foo@example.com' );
    ok $ok, "Created user foo: $msg";

    my ($txn_id, $txn_msg, $txn_obj) = $t->Correspond(
         CcMessageTo => 'foo@example.com',
         Content => 'This is another test' );

    ok( $txn_id, "Created transaction: $txn_id $txn_msg");

    my $message = RT::Extension::NonWatcherRecipients->FindRecipients(
        Transaction => $txn_obj,
        Ticket => $t);

    like( $message, qr/The following people received a copy/, 'Got message');
    like( $message, qr/foo\@example\.com/, "foo's email address is included");
}

done_testing;
