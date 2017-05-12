use strict;
use warnings;

use RT::Test tests => 14, testing => 'RT::Extension::TrailingSubjectTag';

my $subject = 'my hovercraft is full of eels';
my $rtname  = RT->Config->Get('rtname');
my $ticket  = RT::Test->create_ticket(
    Queue   => 'General',
    Subject => $subject,
);

is tag($subject, $ticket),                "$subject [$rtname #1]", "added tag to end";
is tag("[$rtname #1] $subject", $ticket), "[$rtname #1] $subject", "kept existing tag at start";
is tag("$subject [$rtname #1]", $ticket), "$subject [$rtname #1]", "kept existing tag at end";

# Setup a queue subject tag
my $q = RT::Queue->new( RT->SystemUser );
$q->Load('General');
ok $q->id, 'loaded queue';
$q->SetSubjectTag('help!');
my $queuetag = $q->SubjectTag;
is $queuetag, "help!";

is tag($subject, $ticket),                "$subject [$queuetag #1]", "added queue tag to end";
is tag("[$queuetag #1] $subject", $ticket), "[$queuetag #1] $subject", "kept existing queue tag at start";
is tag("$subject [$queuetag #1]", $ticket), "$subject [$queuetag #1]", "kept existing queue tag at end";

sub tag {
    RT::Interface::Email::AddSubjectTag(@_);
}
