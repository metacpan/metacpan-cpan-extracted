# Copyright (c) 2013 Experieco Ltd. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

package RT::Action::UpdateIcestack;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw(RT::Action);

use LWP::UserAgent;
use HTTP::Request::Common;
use XML::LibXML;
use Date::Manip;
use MIME::Base64;

my $DEBUG_FILE = "/tmp/ui_debug.log";

sub Commit {
	my $self = shift;
	my $ti = $self->TicketObj;

	### Fetch these variables from Creator's custom fields (specific to each customer)
	my $host = $ti->CreatorObj->CustomFieldValues("IcestackHostURL")->First->Content;
	my $key = $ti->CreatorObj->CustomFieldValues("IcestackCode")->First->Content;

	my $targetURL = $host . "/STACK/stack/requestUpdate.action?PluginID=3";
	my $valueId = $ti->Type."/".$ti->id;
	my $valueType = $ti->QueueObj->Name;
	my $valueStatus = $ti->Status;
	my $valueEmail = ($ti->Requestors->MemberEmailAddresses)[0];
	my $valueStart = UnixDate(ParseDate($ti->StartsObj->AsString), "%Y-%m-%dT%T%z");
	my $valuePriority = $ti->Priority;
	my $valueSummary = $ti->Subject;
	my $valueTitle = $ti->Type."/".$ti->id;
	
	# Program starts
	my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
	my $root = $doc->createElement("ServiceRequest");
	
	my $elementId = $doc->createElement("ID");
	$elementId->appendTextNode($valueId);
	$root->appendChild($elementId);
	
	my $elementType = $doc->createElement("Type");
	$elementType->appendTextNode($valueType);
	$root->appendChild($elementType);
	
	my $elementStatus = $doc->createElement("Status");
	$elementStatus->appendTextNode($valueStatus);
	$root->appendChild($elementStatus);
	
	my $elementEmail = $doc->createElement("Email");
	$elementEmail->appendTextNode($valueEmail);
	$root->appendChild($elementEmail);
	
	my $elementStart = $doc->createElement("CommitmentStart");
	$elementStart->appendTextNode($valueStart);
	$root->appendChild($elementStart);
	
	my $elementCommitmentType = $doc->createElement("CommitmentType");
	$elementCommitmentType->appendTextNode("BY");
	$root->appendChild($elementCommitmentType);
	
	my $elementMonitor = $doc->createElement("MonitorData");
	
	my $elementPriorityData = $doc->createElement("Data");
	my $elementPriorityType = $doc->createElement("Type");
	$elementPriorityType->appendTextNode("String");
	$elementPriorityData->appendChild($elementPriorityType);
	my $elementPriorityName = $doc->createElement("Name");
	$elementPriorityName->appendTextNode("Priority");
	$elementPriorityData->appendChild($elementPriorityName);
	my $elementPriorityValue = $doc->createElement("Value");
	$elementPriorityValue->appendTextNode($valuePriority);
	$elementPriorityData->appendChild($elementPriorityValue);
	$elementMonitor->appendChild($elementPriorityData);
	
	my $elementSummaryData = $doc->createElement("Data");
	my $elementSummaryType = $doc->createElement("Type");
	$elementSummaryType->appendTextNode("String");
	$elementSummaryData->appendChild($elementSummaryType);
	my $elementSummaryName = $doc->createElement("Name");
	$elementSummaryName->appendTextNode("Summary");
	$elementSummaryData->appendChild($elementSummaryName);
	my $elementSummaryValue = $doc->createElement("Value");
	$elementSummaryValue->appendTextNode($valueSummary);
	$elementSummaryData->appendChild($elementSummaryValue);
	$elementMonitor->appendChild($elementSummaryData);
	
	my $elementTitleData = $doc->createElement("Data");
	my $elementTitleType = $doc->createElement("Type");
	$elementTitleType->appendTextNode("String");
	$elementTitleData->appendChild($elementTitleType);
	my $elementTitleName = $doc->createElement("Name");
	$elementTitleName->appendTextNode("Title");
	$elementTitleData->appendChild($elementTitleName);
	my $elementTitleValue = $doc->createElement("Value");
	$elementTitleValue->appendTextNode($valueTitle);
	$elementTitleData->appendChild($elementTitleValue);
	$elementMonitor->appendChild($elementTitleData);
	
	$root->appendChild($elementMonitor);
	
	$doc->setDocumentElement($root);
	my $message=$doc->toString();

	# log debug for xml input (optional)
	open OUT, ">$DEBUG_FILE";
	print OUT "\n\nInput";
	print OUT "-----------------\n";
	print OUT $message;
	print OUT "\n";
	
	my $client = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0x00 });
	my $request = HTTP::Request->new;
	$request->method("POST");
	$request->uri($targetURL);
	$request->header('Authorization' => 'BASIC ' . encode_base64($key));
	$request->content_type('application/xml');
	$request->content($message);
	my $response = $client->request($request);

	# log debug for xml output (optional)
	print OUT "\n\nOutput";
	print OUT "-----------------\n";
	print OUT $response->content;
	print OUT "\n";
	close OUT;

	return 1;
}

1;

__END__

=head1 NAME

RT::Action::UpdateIcestack - Send ticket updates to Icestack

=head1 DESCRIPTION

This RT ScripAction is invoked when a ticket is updated and sends the update through to Icestack.

=head1 INSTALLATION

Can be installed using the following commands:

    perl Makefile.PL
    make
    make install
    make initdb

=head1 CONFIGURATION

=head2 Enable Plugin

Update RT_SiteConfig.pm with a line similar to the below:

    Set(@Plugins,(qw(RT::Action::UpdateIcestack)));

=head2 Create Scrip

This Scrip will invoke the ScripAction installed above whenever a ticket is updated.

    Log onto RT web interface as root
    Click Tools->Configuration->Global->Scrips->Create
    Enter in Scrip Fields as follows:
        Description: Send update to Icestack
        Condition: On Transaction
        Action: Update Icestack
        Template: Global template: Transaction
        Stage: TransactionCreate
    Click Create

=head2 Add custom fields to Users table

These fields are used to associate an RT User with a particular Icestack instance.

    Log onto RT web interface as root
    Click Tools->Configuration->Custom Fields->Create
        Name: IcestackCode
        Description: Key code issued from Icestack
        Type: Enter one value
        Applies to: Users
    Click Tools->Configuration->Custom Fields->Create
        Name: IcestackHostURL
        Description: Host URL used to push updates back into Icestack
        Type: Enter one value
        Applies to: Users
    Click Create

=head2 Configure Icestack Integration

Icestack communicates with RT via an RT User. It is necessary to populate the IcestackCode and IcestackHostURL fields for this User so that the update mechanism will function.

This User should have access to one or more queues. These will be visible to the Icestack system.

The instructions given below are for creation of new User and Queue(s). It is also possible to modify an existing User.

=head3 Create User

As alluded to above this User will be associated with a particular Icestack instance via the custom fields.

    Log onto RT web interface as root
    Click Tools->Configuration->Users->Create
        Username: <user name>
        Let this user access RT: CHECK
        Let this user be granted rights (Privileged): CHECK
        IcestackHostURL: <url>
        IcestackCode: <code>
    Click Create

=head3 Create Queue and assign rights for User

Create one or more Queues to be associated with the User and Icestack instance.

    Log onto RT web interface as root
    Click Tools->Configuration->Queues->Create
        Queue Name: <queue name>
        Description: Queue for <user name>
        Lifecycle: default
    Click Create
    Click Tools->Configuration->Queues->Select
    Click <queue name>
    Click User Rights
    Add rights for this user: <user name>
        Create tickets: CHECK
        View queue: CHECK
        View ticket summaries: CHECK
        Modify tickets: CHECK
        (others may be necessary, depending...)
    Click Save Changes

=head1 NOTES

To assist with testing the integration the XML exchange with Icestack is logged to /tmp/ui_debug.log.

=head1 AUTHOR

Mark Ibell E<lt>marki@econz.co.nzE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Experieco Ltd. All rights reserved.
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file.

=cut
