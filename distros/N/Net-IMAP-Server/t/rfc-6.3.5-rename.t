use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;
$t->connect_ok;

$t->cmd_like("RENAME foo bar" => "tag BAD Log in first" );

$t->cmd_ok("LOGIN username password");

$t->cmd_like("RENAME" => "tag BAD Not enough options" );
$t->cmd_like("RENAME foo" => "tag BAD Not enough options" );
$t->cmd_like("RENAME foo bar baz" => "tag BAD Too many options" );

# Simple rename
$t->cmd_ok("CREATE moose");
$t->cmd_ok("RENAME moose thingy");
my %mailboxes = $t->mailbox_list;
ok(!exists $mailboxes{"moose"}, "Old mailbox no longer exists");
ok(exists $mailboxes{"thingy"}, "New mailbox exists");

# Renaming a mailbox to that doesn't exist fails
$t->cmd_like("RENAME bogus nonexistant", "tag NO Mailbox doesn't exist");

# Renaming a mailbox to one that exists already is an error
$t->cmd_ok("CREATE bogus");
$t->cmd_like("RENAME bogus thingy", "tag NO Mailbox already exists");

# Renaming a folder moves all subfolders
$t->cmd_ok("CREATE old/folder");
$t->cmd_ok("RENAME old new");
%mailboxes = $t->mailbox_list;
ok(!exists $mailboxes{"old"}, "Old mailbox no longer exists");
ok(exists $mailboxes{"new"}, "New mailbox exists");
ok(!exists $mailboxes{"old/folder"}, "Old subfolder no longer exists");
ok(exists $mailboxes{"new/folder"}, "New subfolder exists");

# Renaming creates any hierarchy necessary
$t->cmd_ok("RENAME new/folder deep/folder");
%mailboxes = $t->mailbox_list;
ok(!exists $mailboxes{"new/folder"}, "Old mailbox no longer exists");
ok(exists $mailboxes{"new"}, "Old mailbox's parent still longer exists");
ok(exists $mailboxes{"deep"}, "Parent folder created");
ok(exists $mailboxes{"deep/folder"}, "Subfolder created");

# Renaming INBOX is magic
$t->cmd_ok("RENAME INBOX newinbox");
%mailboxes = $t->mailbox_list;
ok(exists $mailboxes{"newinbox"}, "newinbox now exists");
{
    local $TODO = "Moving INBOX is broken";
    ok(exists $mailboxes{"INBOX"}, "INBOX still exists");
    ok(exists $mailboxes{"INBOX/username"}, "INBOX's subfolders still exist");
    ok(!exists $mailboxes{"newinbox/username"}, "newinbox doesn't have INBOX's subfolder");
}

# Renaming to a bad UTF-7 name is an error
$t->cmd_like('RENAME bogus "INBOX/&Jjo!"', qr/BAD Invalid UTF-7/ );
$t->cmd_like('RENAME bogus "INBOX/&U,BTFw-&ZeVnLIqe-"', qr/BAD Invalid UTF-7/ );

# Renaming to an 8-bit name is an error
$t->cmd_like(qq{RENAME bogus "INBOX/\x{2668}"}, qr/BAD Mailbox name contains 8-bit data/);

done_testing;
