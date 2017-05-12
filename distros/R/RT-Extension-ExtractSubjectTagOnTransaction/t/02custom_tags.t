#!/sw/bin/perl5.8.6

use strict;
#use Test::More qw/no_plan/;
use Test::More tests => 25;
use RT;
RT::LoadConfig();
RT::Init();
use RT::EmailParser;

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

### test custom action ###

# match a & followed by a number surrounded by { }
$RT::Action::ExtractSubjectTag::ExtractSubjectTagMatch = qr/\{(?:\&|\$|\@)\d+\}/; 

# parse a test e-mail with the old tag style
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

# make sure the old tag *isn't* added on correspond
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj => $parser->Entity);
ok($id, "conduct transaction? $message");
ok($ticket->Subject !~ /\Q[foo.example #12]\E/, "Old tag was not added to ticket's subject");

# parse an email with the new tag style
$email =~ s/\Q[foo.example #12]\E/{&32}/;
($id, $message) = $parser->SmartParseMIMEEntityFromScalar( Message => $email, 
  Decode => 1 );
ok($parser->Entity, "Parser returned a MIME entity");
ok($parser->Entity->head, "Entity had a header");

# make sure the new tag *is* added
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj => $parser->Entity);
ok($id, "conduct transaction? $message");
ok($ticket->Subject =~ /\Q{&32}\E/, "New tag was added to ticket's subject");

# don't match certain numbers
$RT::Action::ExtractSubjectTag::ExtractSubjectTagNoMatch = qr/\{(?:\&3\d|\@\d\d??)\}/;

# parse an email with an excluded tag
$email =~ s/\Q{&32}\E/{&38}/;
($id, $message) = $parser->SmartParseMIMEEntityFromScalar( Message => $email, 
  Decode => 1 );
ok($parser->Entity, "Parser returned a MIME entity");
ok($parser->Entity->head, "Entity had a header");

# make sure the excluded tag isn't added
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj => $parser->Entity);
ok($id, "conduct transaction? $message");
ok($ticket->Subject !~ /\Q{&38}\E/, "First excluded tag was not added");

# parse another email with an excluded tag
$email =~ s/\Q{&38}\E/{\@73}/;
($id, $message) = $parser->SmartParseMIMEEntityFromScalar( Message => $email, 
  Decode => 1 );
ok($parser->Entity, "Parser returned a MIME entity");
ok($parser->Entity->head, "Entity had a header");

# make sure the second excluded tag isn't added
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj => $parser->Entity);
ok($id, "conduct transaction? $message");
ok($ticket->Subject !~ /\Q{@73}\E/, "Second excluded tag was not added");

# parse an e-mail with an included tag
$email =
('Subject: {&42} ExtractSubjectTag test
From: root@example.com
To: rt@example.com

Foo Bar,

Blah blah blah.

Baz,
Quux
');
($id, $message) = $parser->SmartParseMIMEEntityFromScalar( Message => $email, 
  Decode => 1 );
ok($parser->Entity, "Parser returned a MIME entity");
ok($parser->Entity->head, "Entity had a header");

# make sure that included tags can still be added
($id, $message, $transaction_obj) = $ticket->Correspond(MIMEObj => $parser->Entity);
ok($id, "conduct transaction? $message");
ok($ticket->Subject =~ /\Q{&42}\E/, "Included tags can still be added");



1;
