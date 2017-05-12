use lib 't/lib';
use strict;
use warnings;

use Net::IMAP::Server::Test;
my $t = "Net::IMAP::Server::Test";

$t->start_server_ok;
$t->connect_ok;

$t->cmd_like("CREATE foo" => "tag BAD Log in first" );

$t->cmd_ok("LOGIN username password");

$t->cmd_like("CREATE" => "tag BAD Not enough options" );
$t->cmd_like("CREATE foo bar" => "tag BAD Too many options" );

# We assume a "/" separator here
my $res = $t->cmd_ok( 'LIST "" ""');
ok($res =~ m{^\* LIST \(\\Noselect\) "/" ""\r\n}m, "Separator is /");

# Check starting state
my %mailboxes = $t->mailbox_list;
is(delete $mailboxes{"INBOX"}, "\\HasChildren",
   "INBOX exists");
is(delete $mailboxes{"INBOX/username"}, "\\HasNoChildren",
   "INBOX/username exists");
is(keys %mailboxes, 0, "No other mailboxes");

# Create a new top-level mailbox
$t->cmd_ok("CREATE moose");
%mailboxes = $t->mailbox_list;
is(delete $mailboxes{"moose"}, "\\HasNoChildren",
   "moose now exists");
is(keys %mailboxes, 2, "No other mailboxes created");

# Creating a subfolder marks the parent as \HasChildren
$t->cmd_ok("CREATE moose/thingy");
%mailboxes = $t->mailbox_list;
is($mailboxes{"moose"}, "\\HasChildren",
   "moose now has children");
is($mailboxes{"moose/thingy"}, "\\HasNoChildren",
   "moose/thingy now exists");

# Creating a folder with a trailing separator strips it off
$t->cmd_ok("CREATE trailing/");
%mailboxes = $t->mailbox_list;
is(delete $mailboxes{"trailing"}, "\\HasNoChildren",
   "Trailing slash is removed");
is(keys %mailboxes, 4, "No other mailboxes created");

# Creating a deep mailbox creates all of its parents
$t->cmd_ok("CREATE deeply/nested/folder");
%mailboxes = $t->mailbox_list;
is(delete $mailboxes{"deeply"}, "\\HasChildren",
   "First level created");
is(delete $mailboxes{"deeply/nested"}, "\\HasChildren",
   "Second level created");
is(delete $mailboxes{"deeply/nested/folder"}, "\\HasNoChildren",
   "Third level created");

# Invalid IMAP-UTF-7 fails
$t->cmd_like('CREATE "INBOX/&Jjo!"', qr/BAD Invalid UTF-7/ );
$t->cmd_like('CREATE "INBOX/&U,BTFw-&ZeVnLIqe-"', qr/BAD Invalid UTF-7/ );

# UTF-8 mailbox names fail
$t->cmd_like(qq{CREATE "INBOX/\x{2668}"}, qr/BAD Mailbox name contains 8-bit data/);

# Creating over an existing mailbox fails
$t->cmd_like("CREATE moose" => qr/NO Mailbox already exists/);

# This is true even for the magic case-insensitive INBOX
$t->cmd_like("CREATE INBOX" => qr/NO Mailbox already exists/);
$t->cmd_like("CREATE InBoX" => qr/NO Mailbox already exists/);

done_testing;
