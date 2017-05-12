#!/sw/bin/perl5.8.6

use strict;
#use Test::More qw/no_plan/;
use Test::More tests => 25;
use RT;
RT::LoadConfig();
RT::Init;
use RT::EmailParser;
use RT::Action::SendEmail;

# make sure the module is installed
use_ok('RT::Action::ExtractSubjectTag');

# no idea if this test is useful in this context or not, but it's a nice one
# to start with since it succeeds :)
is (__PACKAGE__, 'main', "We're operating in the main package");

my ($id, $message);

### set up the action and the scrip ###

# check if the action is installed, and if not add it to the database
my $action = RT::ScripAction->new($RT::SystemUser);
($id, $message) = $action->Load('ExtractSubjectTag');
if (!$id) {
    ($id, $message) = $action->Create( Name           => 'ExtractSubjectTag',
                                       Description    => '',
                                       ExecModule     => 'ExtractSubjectTag',
                                     );
}
ok ($id, "create action? " . $message);

# check if the scrip is installed, and if not add it to the database
my $scrip = RT::Scrip->new($RT::SystemUser);
($id, $message) = $scrip->Load('OnTransactionExtractSubjectTag');
if (!$id) {
    ($id, $message) 
      = $scrip->Create( 
                        Description     => 'OnTransactionExtractSubjectTag',
                        Queue           => 0,
                        ScripCondition  => 'On Transaction',
                        ScripAction     => 'ExtractSubjectTag',
                        Template        => 'Blank',
                        Stage           => 'TransactionCreate',
                      );
}
ok ($id, "create scrip? " . $message);

### test default action (extract other RT instances' tags) ###

# parse a test e-mail

my $email = 
('Subject: [foo.example #12] ExtractSubjectTag test
From: root@example.com
To: rt@example.com

Foo Bar,

Blah blah blah.

Baz,
Quux
');
my $parser = RT::EmailParser->new($RT::SystemUser);
($id, $message) = $parser->SmartParseMIMEEntityFromScalar( Message => $email, 
  Decode => 1 );
ok($parser->Entity, "Parser returned a MIME entity");
ok($parser->Entity->head, "Entity had a header");

# create a new ticket
my $ticket = RT::Ticket->new($RT::SystemUser);
my $transaction_obj;
($id, $transaction_obj, $message) 
   = $ticket->Create(  Requestor   => ['root@example.com'],
                       Queue       => 'general',
                       Subject     => 'ExtractSubjectTag test',
                    );
ok ($id, "create new ticket? $message");

# add the tag on correspond
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj=>$parser->Entity);
ok($id, "conduct transaction? $message");
ok($ticket->Subject =~ /\Q[foo.example #12]\E/, "Tag was added to ticket's subject");

# check to make sure it doesn't add the tag a second time
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj=>$parser->Entity);
ok($id, "conduct transaction 2? $message");
#it feels like a kludge but it works
my $match_count = 0;
my $subject = $ticket->Subject;
while ($subject =~ /\Q[foo.example #12]\E/g) { $match_count++; }
ok($match_count eq 1, "The same tag was not added a second time");

# create a new e-mail with another, different tag
$email =~ s/\Q[foo.example #12]\E/[bar.example #24]/;
($id, $message) = $parser->SmartParseMIMEEntityFromScalar( Message => $email, 
  Decode => 1 );
ok($parser->Entity, "Parser returned a MIME entity");
ok($parser->Entity->head, "Entity had a header");

# check to make sure the scrip will add that tag to the existing ticket
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj=>$parser->Entity);
ok($id, "conduct transaction? $message");
ok($ticket->Subject =~ /\Q[bar.example #24]\E/, "Second unique tag was added to ticket's subject");

# create a new e-mail with the local RT instance's tag
$email =~ s/\Q[bar.example #24]\E/[$RT::rtname #24]/;
($id, $message) = $parser->SmartParseMIMEEntityFromScalar( Message => $email, 
  Decode => 1 );
ok($parser->Entity, "Parser returned a MIME entity");
ok($parser->Entity->head, "Entity had a header");

#$RT::Action::ExtractSubjectTag::ExtractSubjectTagNoMatch = qr/\[\Q$RT::rtname\E #\d+\]/;
#$RT::EmailSubjectTagRegex = $RT::rtname;

# check to make sure the scrip will *NOT* add that tag to the existing ticket
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj=>$parser->Entity);
ok($id, "conduct transaction? $message");
ok($ticket->Subject !~ /\Q[$RT::rtname #24]\E/, "The local instance's tag was not added to ticket's subject");

### test extraction of multiple tags from the same e-mail subject line ###

# create another new ticket
my $user = RT::CurrentUser->new('root');
ok ($user->id, "Found our user");
my $ticket_mult = RT::Ticket->new($user);
($id, $transaction_obj, $message) 
   = $ticket_mult->Create(  Requestor   => ['root@example.com'],
                            Queue       => 'general',
                            Subject     => 'Multiple ExtractSubjectTag test',
                         );
ok ($id, "create new ticket? $message");

# parse a new e-mail with multiple tags

my $email_mult = 
('Subject: [example.net #12] Multiple ExtractSubjectTag test [example.org #42]
From: root@example.com
To: rt@example.com

Foo Bar,

Blah blah blah.

Baz,
Quux
');
($id, $message) = $parser->SmartParseMIMEEntityFromScalar( 
  Message => $email_mult, Decode => 1 );
ok($parser->Entity, "Parser returned a MIME entity");
#ok($parser->Entity->head, "Entity had a header:\n@{[$parser->Head->stringify]}");
ok($parser->Entity->head, "Entity had a header");

# check to make sure the scrip will add both tags to the ticket
($id, $message, $transaction_obj) = $ticket_mult->Correspond(MIMEObj=>$parser->Entity);
ok($id, "conduct transaction? $message");
ok(
  ($ticket_mult->Subject() =~ /\Q[example.net #12]\E/) &&
  ($ticket_mult->Subject() =~ /\Q[example.org #42]\E/),
  "Both tags were added to the ticket's subject"
);

1;
