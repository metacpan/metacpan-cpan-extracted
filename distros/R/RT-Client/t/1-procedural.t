#!/usr/bin/perl

use Carp;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use LWP::Simple qw(get $ua);

$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__} = \&Carp::confess;

$ua->cookie_jar({});
get('http://localhost/?user=root&pass=password');

if (get('http://root:password@localhost/Atom/0.3/') =~ /<feed/) {
    plan tests => 69;
}
else {
    plan skip_all => 'Atom 0.3 not available on localhost';
}

use_ok('RT::Client');
my $rt = RT::Client->new('http://root:password@localhost');
isa_ok($rt, 'RT::Client', 'Client');

# Debug and error handler:
#
# $rt->debug(1);
# $rt->handle_error('die');

# Requirements:
# 1. Ticket Creation and Modification via an External Interface

my $tickets = $rt->describe('Tickets');
isa_ok($tickets, 'RT::Client::Container', '->describe($uri)');
isnt($tickets->uri, undef, 'Tickets has a URI: '.$tickets->uri);
isa_ok($rt->describe(URI => 'Tickets'), 'RT::Client::Container', '->describe(URI => $uri)');
is($rt->errstr, undef, 'Nothing bad had happened yet');
is($rt->status, 200, 'Status code is 200');
is($rt->add('Tickets'), undef, 'Adding an empty ticket shall fail');
is($rt->status, 400, 'Status code is 400');
isnt($rt->errstr, undef, 'Error message is in ->errstr: '. $rt->errstr);

my $ticket = $rt->add('Tickets', Queue => 1, Subject => 'Testing');
isa_ok($ticket, 'RT::Client::Object');

my $uri = $ticket->uri;
isnt($uri, undef, 'New Ticket has a URI: '.$uri);

is($rt->get(URI => "$uri.Subject"), 'Testing', '->get(URI => .Subject)');
is($rt->get("$uri.Subject"), 'Testing', '->get(.Subject)');
is($rt->get("$uri.Queue"), 1, '->get(.Queue)');
is($rt->get("$uri/Requestors/UserMembersObj.Count"), 1, '->get(Requestors.Count)');
is($rt->get("$uri/Requestors/UserMembersObj/*0.Name"), 'root', 'Requestor is root');

is($rt->set("$uri.Subject", 'Set0'), 'Set0', '->set(.Subject)');
is($rt->get("$uri.Subject"), 'Set0', '->set(.Subject) really happened');

# exercise different update syntaxes
ok($rt->update($uri, Subject => 'Set1'), '->update');
is($rt->get("$uri.Subject"), 'Set1', '->update really happened');
ok($rt->update($uri, Subject => ['Fnord', 'Set2']), '->update with multival');
is($rt->get("$uri.Subject"), 'Set2', '->update really happened');
ok($rt->update($uri, Subject => { set => 'Set3' }), '->update with explicit set');
is($rt->get("$uri.Subject"), 'Set3', '->update really happened');
ok($rt->update($uri, Subject => { set => [ 'Fnord', 'Set4' ] }), '->update with set + multival');
is($rt->get("$uri.Subject"), 'Set4', '->update really happened');

ok($rt->update($uri, type => 'Comment', Content => 'somme comment here'),
  '->update (Comment)');
ok($rt->update($uri, type => 'Correspond', Content => 'somme comment here'),
  '->update (Correspond)');

SKIP: {
    skip 'Cannot load MIME::Entity', 1
      unless eval { require MIME::Entity; 1 };

    my $mime = MIME::Entity->build(
        Type     => 'multipart/mixed',
        From     => 'root',
        To       => 'root',
        Subject  => 'Test MIME',
        Data     => [ 'Line 1', 'Line 2' ],
    );
    $mime->attach(Path => __FILE__);
    ok($rt->update($uri, type => 'Correspond', MIMEObj => $mime),
    '->update (Correspond + MIME)');
}

my $queue = $rt->get("$uri.QueueObj");
isa_ok($queue, 'RT::Client::Object', '->QueueObj');
my $queue_uri = $queue->uri;
isnt($queue_uri, undef, '->QueueObj has a URI: '.$queue_uri);
is($rt->get("$queue_uri.Id"), 1, '->QueueObj has an Id');

# 1.1 Independent of CLI login credentials, need ability to specify
# "requestor" field so that replies are sent to the requestor.

$rt->current_user('RT_System');
$ticket = $rt->add('Tickets', Queue => 1, Subject => 'By System');
is($rt->current_user, 'RT_System', 'current_user persists over a request');
$rt->current_user($rt->username);

isa_ok($ticket, 'RT::Client::Object');
$uri = $ticket->uri;
isnt($uri, undef, 'New Ticket has a URI: '.$uri);
is($rt->get("$uri/Requestors/UserMembersObj/*0.Name"), 'RT_System', 'Requestor is RT_System');

# 1.2 Ability to post a ticket to a specific queue.

$ticket = $rt->add('Tickets', Queue => 'General', Subject => 'Queue ByName');
isa_ok($ticket, 'RT::Client::Object');
$uri = $ticket->uri;
isnt($uri, undef, 'New Ticket has a URI: '.$uri);
is($rt->get("$uri.Queue"), 1, 'posted to the 1st queue');

# 1.3 Ability to specify message body. May contain utf8 OR localized
# charset.

$rt->encoding('hz');
is($rt->set("$uri.Subject", '~{1jLb~}'), '~{1jLb~}', '->set(.Subject) with HZ encoding');
$rt->encoding('gbk');
is(length($rt->get("$uri.Subject")), 4, 'retrieved with GBK encoding');
$rt->encoding('UTF-8');

# 1.4 Ability to set values in n existing custom fields.

my $cf = $rt->add("$queue_uri/CustomFields", Name => rand(), Type => 'SelectSingle');
isa_ok($cf, 'RT::Client::Object');
my $cf_uri = $cf->uri;
isnt($cf_uri, undef, 'New CF has a URI: '.$cf_uri);
my $cf_id = $rt->get("$cf_uri.Id");

$rt->add("$cf_uri/Values", Name => 'Value1', Description => 'Description1');
is($rt->errstr, undef, 'CFV created');
$rt->add("$cf_uri/Values", Name => 'Value2', Description => 'Description2');
is($rt->errstr, undef, 'CFV created');

# 1.5 Ability to set values in "Select One Value" and "Enter One Value"

$rt->add("$uri/CustomFieldValues", Field => $cf_id, Value => 'Value1');
is($rt->errstr, undef, 'TCFV set');

is($rt->get("$uri/CustomFieldValues.Count"), 1, "TCFV is added");
is($rt->get("$uri/CustomFieldValues/*0.Content"), 'Value1', "TCFV is set correctly");

$rt->add("$uri/CustomFieldValues", Field => $cf_id, Value => 'Value2');
is($rt->errstr, undef, 'TCFV set');

is($rt->get("$uri/CustomFieldValues.Count"), 1, "TCFV is replaced");
is($rt->get("$uri/CustomFieldValues/*0.Content"), 'Value2', "TCFV is set correctly");

# 1.6 For modifications, need to identify ticket number. We'd prefer to
# identify modifying user as well if possible.

$rt->current_user('RT_System');
my $id = $rt->get("$uri.Id");
is($rt->set("Tickets/$id.Subject", 'by system'), 'by system', 'set subject');
my $sys_id = $rt->get("Users/RT_System.Id");
isnt($rt->get("Tickets/$id/Transactions.Count"), 1, "transactions happened");
is($rt->get("Tickets/$id/Transactions/*-1.Creator"), $sys_id, 'set by system');
$rt->current_user($rt->username);

# 2. Ability to Close a Ticket via an External Interface

is($rt->set("$uri.Status", 'resolved'), 'resolved', 'resolve a ticket');
is($rt->status, 200, 'resolved with status 200');
is($rt->set("$uri.Status", 'resolved'), 'resolved', 'resolve a ticket again');
is($rt->status, 200, 'resolved with status 200');
is($rt->set("$uri.Status", 'open'), 'open', 'ticket reopened');

# 2.1 Ability to close a ticket based on ticket number. We'd prefer to
# identify closing user as well if possible.

$rt->current_user('RT_System');
is($rt->set("Tickets/$id.Status", 'resolved'), 'resolved', 'resolve a ticket');
isnt($rt->get("Tickets/$id/Transactions.Count"), 1, "transactions happened");
is($rt->get("Tickets/$id/Transactions/*-1.Creator"), $sys_id, "set by system");
$rt->current_user($rt->username);

# 3. General CLI Requirements

# 3.1 Error Responses: CLI must return status and error responses
# instead of end-user help text.

is($rt->set("$uri.Status", 'open'), 'open', 'set ticket status to open');
is($rt->status, 200, 'ticket opened with status 200');
is($rt->set("$uri.Owner", 'nobody'.rand()), undef, 'set nonexistent owner');
is($rt->status, 400, 'set ticket owner failed with status 400');
isnt($rt->errstr, undef, 'errstr is '.$rt->errstr);

# 3.2 Environment: Support perl 5.6.1.

cmp_ok($], '>=', 5.006001, 'perl version >= 5.6.1');

