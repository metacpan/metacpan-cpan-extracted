use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Email::Abstract; require Test::Email; 1 }
        or plan skip_all => 'require Email::Abstract and Test::Email';
}

plan tests => 38;
use RT;
use RT::Test;
use RT::Test::Email;
use_ok('RTx::WorkflowBuilder');

RT->Config->Set( LogToScreen => 'debug' );

my ($baseurl, $m) = RT::Test->started_ok;

my $q = RT::Queue->new($RT::SystemUser);
$q->Load('___Approvals');

$q->SetDisabled(0);

my %users;
for my $user_name (qw(minion jen moss roy cfo ceo )) {
    my $user = $users{$user_name} = RT::User->new($RT::SystemUser);
    $user->Create( Name => uc($user_name),
                   Privileged => 1,
                   EmailAddress => $user_name.'@company.com');
    my ($val, $msg);
    ($val, $msg) = $user->PrincipalObj->GrantRight(Object =>$q, Right => $_)
        for qw(ModifyTicket OwnTicket ShowTicket);

}

my $stages =
     { 'Manager approval' => 
       { content => '.....',
         subject => 'Manager Approval for PO: {$Approving->Id} - {$Approving->Subject}',
         owner   => q!{{
    Fire                => "moss",
    IT                  => "roy",
    Marketing           => "jen"}->{ $Approving->FirstCustomFieldValue('Department') }}!,
     },
       'Finance approval' =>
       { content => '... ',
         owner => 'CFO',
       },
       'CEO approval' => 
       { content => '..........',
         owner => 'CEO',
     }};

my $approvals = RTx::WorkflowBuilder->new({ stages => $stages, rule => [ 'Manager approval' => 'Finance approval', 'CEO approval']})->compile_template;
my $apptemp = RT::Template->new($RT::SystemUser);
$apptemp->Create( Content => $approvals, Name => "PO Approvals", Queue => "0");

ok($apptemp->Id);

$q = RT::Queue->new($RT::SystemUser);
$q->Create(Name => 'PO');
ok ($q->Id, "Created PO queue");

my $dep_cf = RT::CustomField->new( $RT::SystemUser );
$dep_cf->Create( Name => 'Department', Type => 'SelectSingle', Queue => $q->id );
$dep_cf->AddValue( Name => $_ ) for qw(IT Marketing Fire);


my $scrip = RT::Scrip->new($RT::SystemUser);
my ($sval, $smsg) =$scrip->Create( ScripCondition => 'On Create',
                ScripAction => 'Create Tickets',
                Template => 'PO Approvals',
                Queue => $q->Id);
ok ($sval, $smsg);
ok ($scrip->Id, "Created the scrip");
ok ($scrip->TemplateObj->Id, "Created the scrip template");
ok ($scrip->ConditionObj->Id, "Created the scrip condition");
ok ($scrip->ActionObj->Id, "Created the scrip action");

my $t = RT::Ticket->new($RT::SystemUser);
my ($tid, $ttrans, $tmsg);

mail_ok {
    ($tid, $ttrans, $tmsg) =
        $t->Create(Subject => "answering machines",
                   Owner => "root", Requestor => 'minion',
                   'CustomField-'.$dep_cf->id => 'IT',
                   Queue => $q->Id);
} { #from => qr/RT/,
    to => 'roy@company.com',
    subject => qr/New Pending Approval/,
    body => qr/pending your approval/,
},{ from => qr/PO via RT/,
    to => 'minion@company.com',
    subject => qr/answering machines/,
    body => qr/automatically generated in response/,
};

ok ($tid,$tmsg);

is ($t->ReferredToBy->Count,3, "referred to by the three tickets");

my $deps = $t->DependsOn;
is ($deps->Count, 1, "The ticket we created depends on one other ticket");
my $dependson_ceo= $deps->First->TargetObj;
ok ($dependson_ceo->Id, "It depends on a real ticket");
like($dependson_ceo->Subject, qr/Approval for ticket.*answering machine/);

$deps = $dependson_ceo->DependsOn;
is ($deps->Count, 1, "The ticket we created depends on one other ticket");
my $dependson_cfo = $deps->First->TargetObj;
ok ($dependson_cfo->Id, "It depends on a real ticket");

$deps = $dependson_cfo->DependsOn;
is ($deps->Count, 1, "The ticket we created depends on one other ticket");
my $dependson_roy = $deps->First->TargetObj;
ok ($dependson_roy->Id, "It depends on a real ticket");

like($dependson_roy->Subject, qr/Manager Approval for PO.*answering machines/);

is_deeply([ map { $_->Status } $t, $dependson_roy, $dependson_cfo, $dependson_ceo ],
          [ 'new', 'open', 'new', 'new'], 'tickets in correct state');

mail_ok {
    my $roy = RT::CurrentUser->new;
    $roy->Load( $users{roy} );

    $dependson_cfo->CurrentUser($roy);
    my ($ok, $msg) = $dependson_roy->SetStatus( Status => 'resolved' );
    ok($ok, "roy can approve - $msg");

} { from => qr/RT System/,
    to => 'cfo@company.com',
    subject => qr/New Pending Approval/,
    body => qr/pending your approval/
},{ from => qr/RT System/, # why is this not roy?
    to => 'minion@company.com',
    subject => qr/Ticket Approved:/,
    body => qr/approved by ROY/
};

is_deeply([ map { $_->Status } $t, $dependson_roy, $dependson_cfo, $dependson_ceo ],
          [ 'new', 'resolved', 'open', 'new'], 'tickets in correct state');

# cfo approves
mail_ok {
    my $cfo = RT::CurrentUser->new;
    $cfo->Load( $users{cfo} );

    $dependson_cfo->CurrentUser($cfo);
    my ($ok, $msg) = $dependson_cfo->SetStatus( Status => 'resolved' );
    ok($ok, "cfo can approve - $msg");

} { from => qr/RT System/,
    to => 'ceo@company.com',
    subject => qr/New Pending Approval/,
    body => qr/pending your approval/
},{ from => qr/RT System/,
    to => 'minion@company.com',
    subject => qr/Ticket Approved:/,
    body => qr/approved by CFO/
};

is_deeply([ map { $_->Status } $t, $dependson_roy, $dependson_cfo, $dependson_ceo ],
          [ 'new', 'resolved', 'resolved', 'open'], 'tickets in correct state');

# ceo approves
mail_ok {
    my $ceo = RT::CurrentUser->new;
    $ceo->Load( $users{ceo} );

    $dependson_ceo->CurrentUser($ceo);
    my ($ok, $msg) = $dependson_ceo->SetStatus( Status => 'resolved' );
    ok($ok, "ceo can approve - $msg");

} { from => qr/RT System/,
    to => 'minion@company.com',
    subject => qr/Ticket Approved:/,
    body => qr/approved by CEO/
},{ from => qr/CEO via RT/,
    to => 'root@localhost',
    subject => qr/Ticket Approved:/,
    body => qr/The ticket has been approved/
};

is_deeply([ map { $_->Status } $t, $dependson_roy, $dependson_cfo, $dependson_ceo ],
          [ 'new', 'resolved', 'resolved', 'resolved'], 'tickets in correct state');
