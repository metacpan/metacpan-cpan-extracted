#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More 'no_plan';

$SIG{__WARN__} = sub { use Carp; Carp::cluck(@_) };
$SIG{__DIE__} = sub { use Carp; Carp::confess(@_) };

use_ok('RT::Client');

exit;

__END__
my $rt = RT::Client->new('http://root:password@localhost')->top;
isa_ok($rt, 'RT::Client::Container', 'Toplevel');

# some way to RaiseError!

# Requirements:
# 1. Ticket Creation and Modification via an External Interface

my $tickets = $rt->Tickets;
isa_ok($tickets, 'RT::Client::Container', 'Tickets');

can_ok($tickets, 'search');
can_ok($tickets, 'add');

my $results = $tickets->search;
isa_ok($results, 'RT::Client::ResultSet');
exit;

can_ok($results, 'remove');
can_ok($results, 'update');

is($tickets->_errstr, undef, 'Nothing bad had happened yet');
is($tickets->add, undef, 'Adding an empty ticket shall fail');
isnt($tickets->_errstr, undef, 'Error message is in ->_errstr');
is($rt->errstr, $tickets->_errstr, 'Error message is global');

my $ticket = $tickets->add( Queue => 1, Subject => 'Testing' );
isa_ok($ticket, 'RT::Client::Object');
can_ok($ticket, 'remove');
can_ok($ticket, 'update');
can_ok($ticket, 'comment');
can_ok($ticket, 'correspond');

is($ticket->Subject, 'Testing');
is($ticket->Queue, 1);

# exercise different update syntaxes
is($ticket->setSubject('Set0'), 'Set0');
is($ticket->update( Subject => 'Set1' ), 'Set1');
is($ticket->update( Subject => [ 'Fnord', 'Set2' ] ), 'Set2');
is($ticket->update( Subject => { set => 'Set3' } ), 'Set3');
is($ticket->update( Subject => { set => [ 'Fnord', 'Set4' ] } ), 'Set4');

# equivalent to $ticket->_top->Queues($ticket->Queue)
my $queue = $ticket->QueueObj;
isa_ok($queue, 'RT::Client::Object');
can_ok($queue, 'remove');
can_ok($queue, 'update');
ok(!$queue->can('comment'), 'Cannot comment on a Queue');
ok(!$queue->can('correspond'), 'Cannot correspond on a Queue');

# 1.1 Independent of CLI login credentials, need ability to specify
# "requestor" field so that replies are sent to the requestor.

my $email = 'rand-' . rand() . '@example.com';
is($ticket->Requestor->search->count, 1);
$ticket->addRequestor($email);
is($ticket->Requestor->search->count, 2);

# 1.2 Ability to post a ticket to a specific queue.

$ticket = $queue->Tickets->add( Subject => 'Testing' );
isa_ok($ticket, 'RT::Client::Object');
is($ticket->Subject, 'Testing');

# 1.3 Ability to specify message body. May contain utf8 OR localized
# charset.

$ticket->_encoding('hz');
is($ticket->_encoding, $rt->encoding, '->_encoding is global');
$ticket->setSubject('~{1jLb~}');
$ticket->_encoding('gbk');
is(length($ticket->Subject), 4);
$ticket->_encoding('utf-8');

# 1.4 Ability to set values in n existing custom fields.

my $cf = $queue->CustomFields->add(
    Name => 'CFTest',
    Type => 'SelectSingle',
);

$cf->addValues( Name => 'foo', Description => 'Foo Option' );

# 1.5 Ability to set values in "Select One Value" and "Enter One Value"
# -type custom fields

# RT-Tickets/5/CustomFieldValues/9/1.Content
# RT-Tickets/5/CustomFieldValues/9/1.Content
$ticket->CustomFieldValues($cf)->set( Content => 'foo');

is($ticket->CustomFieldsValues($cf)->count, 1);
is($ticket->CustomFieldsValues($cf)->first->Content, 'foo');

# 1.6 For modifications, need to identify ticket number. We'd prefer to
# identify modifying user as well if possible.

my $id = $ticket->Id;
$rt->current_user('Nobody');
is($ticket->_current_user, $rt->current_user, '->_current_user is global');
$rt->Tickets($id)->comment( Content => "Hello!" );
$rt->current_user($rt->username);

# 2. Ability to Close a Ticket via an External Interface

$ticket->setStatus('resolved');

# 2.1 Ability to close a ticket based on ticket number. We'd prefer to
# identify closing user as well if possible.

$ticket->current_user('Nobody');
$ticket->comment( Content => 'reopen!' );
is($ticket->Status, 'open');
$ticket->setStatus('resolved');
$ticket->current_user($rt->username);

# 3. General CLI Requirements

# 3.1 Error Responses: CLI must return status and error responses
# instead of end-user help text.

$ticket->setStatus('open');
is($rt->_status, 200);
is($ticket->_status, 200);
$ticket->setOwner('no_such_user' . rand());
is($rt->_status, 200);
is($ticket->_status, 400);
isnt($ticket->_errstr, undef);

# 3.2 Environment: Support perl 5.6.1.

cmp_ok($], '>=', 5.006001);

