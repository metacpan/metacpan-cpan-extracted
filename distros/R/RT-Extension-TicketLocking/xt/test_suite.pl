#!/usr/bin/perl

# Load this in test scripts with: require "xt/test_suite.pl";
# *AFTER* loading in Test::More.


use strict;
use warnings;

use HTTP::Cookies;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt4/local/lib /opt/rt4/lib);

my $RTIR_TEST_USER = "rtir_test_user";
my $RTIR_TEST_PASS = "rtir_test_pass";

sub default_agent {
    my $agent = new RT::Test::Web;
    $agent->cookie_jar( HTTP::Cookies->new );
    my $u = rtir_user();
    $agent->login($RTIR_TEST_USER, $RTIR_TEST_PASS);
    $agent->get_ok("/index.html", "loaded home page");
    return $agent;
}

sub set_custom_field {
    my $agent = shift;
    my $cf_name = shift;
    my $val = shift;
    my $field_name = $agent->value($cf_name) or return 0;
    $agent->field($field_name, $val);
    return 1;
}

sub display_ticket {
    my $agent = shift;
    my $id = shift;

    $agent->get_ok("/RTIR/Display.html?id=$id", "Loaded Display page for Ticket #$id");
}

sub ticket_state_is {
    my $agent = shift;
    my $id = shift;
    my $state = shift;
    my $desc = shift || "State of the ticket #$id is '$state'";
    display_ticket( $agent, $id );
    $agent->content =~ qr{State:\s*</td>\s*<td[^>]*?>\s*<span class="cf-value">([\w ]+)</span>}ism;
    return is($1, $state, $desc);
}


sub create_user {
    my $user_obj = rtir_user();

    ok($user_obj->Id > 0, "Successfully found the user");
    
    my $group_obj = RT::Group->new(RT::SystemUser());
    $group_obj->LoadUserDefinedGroup("DutyTeam");
    ok($group_obj->Id > 0, "Successfully found the DutyTeam group");

    $group_obj->AddMember($user_obj->Id);
    ok($group_obj->HasMember($user_obj->PrincipalObj), "user is in the group");
}

sub rtir_user {
    my $u = RT::Test->load_or_create_user(
        Name         => $RTIR_TEST_USER,
        Password     => $RTIR_TEST_PASS,
        EmailAddress => "$RTIR_TEST_USER\@example.com",
        RealName     => "$RTIR_TEST_USER Smith",
        Privileged   => 1,
    );
    return $u;
}

sub create_incident {
    return create_rtir_ticket_ok( shift, 'Incidents', @_ );
}
sub create_ir {
    return create_rtir_ticket_ok( shift, 'Incident Reports', @_ );
}
sub create_investigation {
    return create_rtir_ticket_ok( shift, 'Investigations', @_ );
}
sub create_block {
    return create_rtir_ticket_ok( shift, 'Blocks', @_ );
}

sub goto_create_rtir_ticket {
    my $agent = shift;
    my $queue = shift;

    my %type = (
        'Incident Reports' => 'Report',
        'Investigations'   => 'Investigation',
        'Blocks'           => 'Block',
        'Incidents'        => 'Incident'
    );

    $agent->get_ok("/RTIR/index.html", "loaded home page");

    $agent->follow_link_ok({text => $queue, n => "1"}, "Followed '$queue' link");
    $agent->follow_link_ok({text => "New ". $type{ $queue }, n => "1"}, "Followed 'New $type{$queue}' link");
    

    # set the form
    $agent->form_number(3);
}

sub create_rtir_ticket_ok {
    my $agent = shift;
    my $queue = shift;

    my $id = create_rtir_ticket( $agent, $queue, @_ );
    ok $id, "Created ticket #$id in queue '$queue' successfully.";
    return $id;
}

sub create_rtir_ticket
{
    my $agent = shift;
    my $queue = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    goto_create_rtir_ticket($agent, $queue);
    
    #Enable test scripts to pass in the name of the owner rather than the ID
    if ($$fields{Owner} && $$fields{Owner} !~ /^\d+$/)
    {
        if($agent->content =~ qr{<option.+?value="(\d+)"\s*>$$fields{Owner}</option>}ims) {
            $$fields{Owner} = $1;
        }
    }
    

    $fields->{'Requestors'} ||= $RTIR_TEST_USER if $queue eq 'Investigations';
    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }

    my %create = (
        'Incident Reports' => 'Create',
        'Investigations'   => 'Create',
        'Blocks'           => 'Create',
        'Incidents'        => 'CreateIncident'
    );
    # Create it!
    $agent->click( $create{ $queue } );
    
    is ($agent->status, 200, "Attempted to create the ticket");

    return get_ticket_id($agent);
}

sub get_ticket_id {
    my $agent = shift;
    my $content = $agent->content();
    my $id = 0;
    if ($content =~ /.*Ticket (\d+) created.*/g) {
        $id = $1;
    }
    elsif ($content =~ /.*No permission to view newly created ticket #(\d+).*/g) {
        diag "No permissions to view the ticket" if $ENV{'TEST_VERBOSE'};
    }
    else {
        diag "Couldn't find ticket id in:\n$content" if $ENV{'TEST_VERBOSE'};
    }
    return $id;
}


sub create_incident_for_ir {
    my $agent = shift;
    my $ir_id = shift;
    my $fields = shift || {};
    my $cfs = shift || {};

    display_ticket($agent, $ir_id);

    # Select the "New" link from the Display page
    $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");

    $agent->form_number(3);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }

    $agent->click("CreateIncident");
    
    is ($agent->status, 200, "Attempting to create new incident linked to child $ir_id");

    ok ($agent->content =~ /.*Ticket (\d+) created in queue.*/g, "Incident created from child $ir_id.");
    my $incident_id = $1;

#    diag("incident ID is $incident_id");
    return $incident_id;
}

sub ok_and_content_like {
    my $agent = shift;
    my $re = shift;
    my $desc = shift || "looks good";
    
    is($agent->status, 200, "request successful");
    #like($agent->content, $re, $desc);
    $agent->content_like($re, $desc);
}


sub create_incident_and_investigation {
    my $agent = shift;
    my $fields = shift || {};
    my $cfs = shift || {};
    my $ir_id = shift;

    $ir_id ? display_ticket($agent, $ir_id)
        : $agent->get_ok("/index.html", "loaded home page");

    if($ir_id) {
        # Select the "New" link from the Display page
        $agent->follow_link_ok({text => "[New]"}, "Followed 'New (Incident)' link");
    }
    else 
    {
        $agent->follow_link_ok({text => "Incidents"}, "Followed 'Incidents' link");
        $agent->follow_link_ok({text => "New Incident", n => '1'}, "Followed 'New Incident' link");
    }

    # Fill out forms
    $agent->form_number(3);

    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }
    $agent->click("CreateWithInvestigation");
    my $msg = $ir_id
        ? "Attempting to create new incident and investigation linked to child $ir_id"
        : "Attempting to create new incident and investigation";
    is ($agent->status, 200, $msg);
    $msg = $ir_id ? "Incident created from child $ir_id." : "Incident created.";

    my $re = qr/.*Ticket (\d+) created in queue &#39;Incidents&#39;/;
    $agent->content_like( $re, $msg );
      my ($incident_id) = ($agent->content =~ $re);
      
    $re = qr/.*Ticket (\d+) created in queue &#39;Investigations&#39;/;
    $agent->content_like( $re, "Investigation created for Incident $incident_id." );
    my ($investigation_id) = ($agent->content =~ $re);

    return ($incident_id, $investigation_id);
}


sub create_ticket {
    my $agent = shift;
    my $queue = shift || 'General';

    return create_rtir_ticket($agent, $queue, @_) 
        if $queue eq 'Incidents'
        || $queue eq 'Blocks'
        || $queue eq 'Investigations'
        || $queue eq 'Incident Reports';
    
    my $fields = shift || {};
    my $cfs = shift || {};

    my $q = RT::Test->load_or_create_queue(Name => $queue);

    $agent->goto_create_ticket($q);

    #Enable test scripts to pass in the name of the owner rather than the ID
    if ( $fields->{'Owner'} && $fields->{'Owner'} !~ /^\d+$/ ) {
        my $u = RT::User->new( $RT::SystemUser );
        $u->Load( $fields->{'Owner'} );
        die "Couldn't load user '". $fields->{'Owner'} ."'"
            unless $u->id;
        $fields->{'Owner'} = $u->id;
    }
    
    $agent->form_number(3);
    while (my ($f, $v) = each %$fields) {
        $agent->field($f, $v);
    }

    while (my ($f, $v) = each %$cfs) {
        set_custom_field($agent, $f, $v);
    }
    
    
    # Create it!
    $agent->click_button(value => 'Create');
    
    is ($agent->status, 200, "Attempted to create the ticket");

    return get_ticket_id($agent);
}

1;
