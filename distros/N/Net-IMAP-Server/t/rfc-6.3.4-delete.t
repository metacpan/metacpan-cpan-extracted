use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;
$t->connect_ok;

$t->cmd_like("DELETE foo" => "tag BAD Log in first" );

$t->cmd_ok("LOGIN username password");

$t->cmd_like("DELETE" => "tag BAD Not enough options" );
$t->cmd_like("DELETE foo bar" => "tag BAD Too many options" );

# Prune INBOX/username
$t->cmd_ok("DELETE INBOX/username");
my %mailboxes = $t->mailbox_list;
is(delete $mailboxes{"INBOX"}, "\\HasNoChildren",
   "INBOX exists");
is(keys %mailboxes, 0, "No other mailboxes");

# Removing a non-existant mailbox is a failure
$t->cmd_like("DELETE bogus" => "tag NO Mailbox doesn't exist");

# Removing the INBOX (in any case) is a failure
$t->cmd_like("DELETE INBOX" => "tag NO INBOX cannot be deleted");
$t->cmd_like("DELETE InBoX" => "tag NO INBOX cannot be deleted");

# The RFC is slightly inconsistent with how removing a mailbox with
# inferiors should function:
#  * Messages are removed from the mailbox
#  * The mailbox is marked as \Noselect
#  * Per the _first_ example under 6.3.4, this mailbox still shows to
#    `LIST "" "*"`; however, per the second, it does _not_ -- only to
#    `LIST "" "%"`.  While the RENAME example supports the former
#    interpretation, the explicit contrast of * to % in the second
#    DELETE example implies that it is intentional.
#  * Removing this \Noselect'd mailbox will fail in the future
# Currently, Net::IMAP::Server simply refuses to remove mailboxes which
# have inferiors, avoiding the \Noselect difficulty entirely.
$t->cmd_ok("CREATE INBOX/with/children");
{
    local $TODO = "Mailbox deletion is still too-conservative";
    $t->cmd_ok("DELETE INBOX/with");
}
%mailboxes = $t->mailbox_list;
is(delete $mailboxes{"INBOX/with/children"}, "\\HasNoChildren",
     "Inferior mailbox still exists");
{
    local $TODO = "Mailbox deletion is still too-conservative";
    ok(!$mailboxes{"INBOX/with"}, "Mailbox is gone");
    is(keys %mailboxes, 1, "No other mailboxes");
}
%mailboxes = $t->mailbox_list("", "INBOX/%");
my $mid = delete $mailboxes{"INBOX/with"};
ok($mid, "Found mid-mailbox using %");
like($mid, qr/\\HasChildren/, "Is marked \\HasChildren");
{
    local $TODO = "Mailbox deletion is still too-conservative";
    like($mid, qr/\\Noselect/, "Is marked \\Noselect");
}

done_testing;
