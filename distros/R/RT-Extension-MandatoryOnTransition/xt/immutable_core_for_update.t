use strict;
use warnings;

use RT::Extension::MandatoryOnTransition::Test tests => undef, config => <<CONFIG
Set( %MandatoryOnTransition,
     '*' => {
         '* -> resolved' => ['TimeWorked',]
     }
    );
Set( %PriorityAsString,
    Default => { Low => 0, Medium => 50, High => 100 },
);
CONFIG
    ;

use_ok('RT::Extension::MandatoryOnTransition');

my ( $baseurl, $m ) = RT::Test->started_ok();

ok( $m->login( 'root', 'password' ), 'logged in' );
$m->get_ok($m->rt_base_url);

diag "Resolve ticket through Basics with required TimeWorked";
{
    my $t = RT::Test->create_ticket(
        Queue => 'General',
        Subject => 'Ticket to resolve through Modify.html',
        Content => 'Testing',
        );
    ok( $t->id, 'Created ticket to resolve through Modify.html: ' . $t->id);

    $m->goto_ticket($t->id);
    $m->follow_link_ok( { text => 'Basics' }, 'Get Modify.html of ticket' );
    $m->submit_form_ok( { form_name => 'TicketModify',
                          fields => { Status => 'resolved', TimeWorked => 10, },
                          button => 'SubmitTicket', },
                        'Resolve ticket through Basics with required TimeWorked', );

    $m->content_contains("Worked 10 minutes");
    $m->content_contains("Status changed from &#39;new&#39; to &#39;resolved&#39;");
}

diag "Resolve ticket through Jumbo with required TimeWorked";
{
    my $t = RT::Test->create_ticket(
        Queue => 'General',
        Subject => 'Ticket to resolve through ModifyAll.html',
        Content => 'Testing',
        );
    ok( $t->id, 'Created ticket to resolve through ModifyAll.html: ' . $t->id);

    $m->goto_ticket($t->id);
    $m->follow_link_ok( { text => 'Jumbo' }, 'Get ModifyAll.html of ticket' );
    $m->submit_form_ok( { form_name => 'TicketModifyAll',
                          fields => { Status => 'resolved', TimeWorked => 10, },
                          button => 'SubmitTicket', },
                        'Resolve ticket through Jumbo with required TimeWorked', );

    $m->content_contains("Worked 10 minutes");
    $m->content_contains("Status changed from &#39;new&#39; to &#39;resolved&#39;");
}

diag "Modify ticket through Basics without permanently altering %CORE_FOR_UPDATE";
{
    my $t0 = RT::Test->create_ticket(
        Queue => 'General',
        Subject => 'Ticket to modify',
        Content => 'Testing',
        );
    ok( $t0->id, 'Created ticket to modify: ' . $t0->id);

    my $t1 = RT::Test->create_ticket(
        Queue => 'General',
        Subject => 'Ticket to resolve',
        Content => 'Testing',
        );
    ok( $t1->id, 'Created ticket to resolve, after modifying another: ' . $t1->id);

    $m->goto_ticket($t0->id);
    $m->follow_link_ok( { text => 'Basics' }, 'Get Modify.html of ticket' );
    $m->submit_form_ok( { form_name => 'TicketModify',
                          fields => { Priority => 50, },
                          button => 'SubmitTicket', },
                        'Modify any ticket 0 metadata except status, queue, or TimeWorked', );
    if ( RT->Config->Get('EnablePriorityAsString') ) {
        $m->text_contains("Priority changed from 'Low' to 'Medium'");
    }
    else {
        $m->text_contains("Priority changed from (no value) to '50'");
    }

    $m->goto_ticket($t1->id);
    $m->follow_link_ok( { text => 'Resolve' }, 'Try to resolve ticket');
    $m->submit_form_ok( { form_name => 'TicketUpdate',
                          fields => { UpdateTimeWorked => 10 },
                          button => 'SubmitTicket',},
                        'Resolve ticket 1 with value for TimeWorked after modifying another ticket');
    $m->content_contains("Worked 10 minutes");
    $m->content_contains("Status changed from &#39;new&#39; to &#39;resolved&#39;");
}

diag "Modify ticket through Jumbo without permanently altering %CORE_FOR_UPDATE";
{
    my $t0 = RT::Test->create_ticket(
        Queue => 'General',
        Subject => 'Ticket to modify',
        Content => 'Testing',
        );
    ok( $t0->id, 'Created ticket to modify: ' . $t0->id);

    my $t1 = RT::Test->create_ticket(
        Queue => 'General',
        Subject => 'Ticket to resolve',
        Content => 'Testing',
        );
    ok( $t1->id, 'Created ticket to resolve, after modifying another: ' . $t1->id);

    $m->goto_ticket($t0->id);
    $m->follow_link_ok( { text => 'Jumbo' }, 'Get ModifyAll.html of ticket' );
    $m->submit_form_ok( { form_name => 'TicketModifyAll',
                          fields => { Priority => 50, },
                          button => 'SubmitTicket', },
                        'Modify any ticket 0 metadata except status, queue, or TimeWorked', );
    if ( RT->Config->Get('EnablePriorityAsString') ) {
        $m->text_contains("Priority changed from 'Low' to 'Medium'");
    }
    else {
        $m->text_contains("Priority changed from (no value) to '50'");
    }

    $m->goto_ticket($t1->id);
    $m->follow_link_ok( { text => 'Resolve' }, 'Try to resolve ticket');
    $m->submit_form_ok( { form_name => 'TicketUpdate',
                          fields => { UpdateTimeWorked => 10 },
                          button => 'SubmitTicket',},
                        'Resolve ticket 1 with value for TimeWorked after modifying another ticket');
    $m->content_contains("Worked 10 minutes");
    $m->content_contains("Status changed from &#39;new&#39; to &#39;resolved&#39;");
}

undef $m;
done_testing;
