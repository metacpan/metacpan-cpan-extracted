use strict;
use warnings;
package RTIR::Extension::MISP;

use LWP::UserAgent;
use JSON;
use UUID::Tiny ':std';

our $VERSION = '1.00';

RT->AddStyleSheets('rtir-extension-misp.css');

if ( RT->Config->can('RegisterPluginConfig') ) {
    RT->Config->RegisterPluginConfig(
        Plugin  => 'RTIR::Extension::MISP',
        Content => [
            {
                Name => 'ExternalFeeds',
                Help => 'https://github.com/bestpractical/rtir-extension-misp#configuration',
            },
        ],
        Meta => {
            ExternalFeeds => {
                Type => 'HASH',
            },
        },
    );
}

=head1 NAME

RTIR-Extension-MISP - Integrate RTIR with MISP

=head1 DESCRIPTION

L<MISP|https://www.misp-project.org/> is a platform for sharing threat intelligence among
security teams, and this extension provides integration from L<RTIR|https://bestpractical.com/rtir>.

=head1 RTIR VERSION

Works with RTIR 6.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RTIR::Extension::MISP');

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you will end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 Base MISP Configuration

Set the following in your C<RT_SiteConfig.pm> with details for the MISP
instance you want RTIR to integrate with.

    Set(%ExternalFeeds,
        'MISP' => [
            {   Name        => 'MISP',
                URI         => 'https://mymisp.example.com',  # Change to your MISP
                Description => 'My MISP Feed',
                DaysToFetch => 5,  # For the feed page, how many days back to fetch
                ApiKeyAuth  => 'API SECRET KEY',  # Change to your real key
            },
        ],
    );

=head2 MISP Custom Fields

This extension ships a C<MISP> custom field grouping in F<etc/MISP_Config.pm>
which is picked up automatically for file-based installs. If your installation
has edited C<%CustomFieldGroupings> via the RT database (Admin E<gt> Tools E<gt>
Configuration), the database value takes precedence over file-based config and
the MISP grouping must be added manually by merging the following into your
existing C<CustomFieldGroupings> setting:

    {
        "RT::Ticket": {
            "Incidents": [
                "MISP",
                ["MISP Event ID", "MISP Event UUID", "MISP RTIR Object ID"]
            ]
        }
    }

=head2 Page Layouts

Since this extension integrates with RTIR, which defines its own page layouts,
the MISP page components must be added manually via B<Admin E<gt> Page Layouts>
to avoid overwriting existing layouts.

=over

=item Ticket Create (Incidents)

Add C<CustomFieldCustomGroupings:MISP> (or the default C<CustomFields> grouping)
so that the MISP Event ID and UUID are set when creating a ticket from the
External Feeds page.

=item Ticket Display (Incidents)

Add C<CustomFieldCustomGroupings:MISP> (or C<CustomFields>) to show the MISP
custom fields on the incident, and C<MISPEventDetails> to display the MISP
event details widget.

=back

=head1 DETAILS

This integration adds several different ways to work between the MISP and
RTIR systems as described below.

=head2 Consume Feed from MISP

After adding the MISP configuration described above, the Feeds page in RTIR at
RTIR > Tools > External Feeds will have a new MISP option listed. This feed
pulls in events for the past X number of days based on the DaysToFetch
configuration. From the feed display page, you can click the "Create new ticket"
button to create a ticket with information from the MISP event.

=head2 MISP Event Details Widget

This extension provides a C<MISPEventDetails> page layout widget for RT 6.
When the C<MISP Event ID> custom field has a value, the widget displays event
details fetched from the MISP REST API including threat level, analysis status,
creator org, and attribute counts. See L</Page Layouts> above for instructions
on adding it to your Incidents Display layout.

=head2 Update MISP Event

On an incident with a MISP Event ID, the Actions menu will have an option
"Update MISP Event". If you select this action, RTIR will update the existing
MISP event with an RTIR object, including data from the incident ticket.

=head2 Create MISP Event

If MISP Event ID has no value, the Actions menu on incidents shows an option to
"Create MISP Event". Select this to create an event in MISP with details from
the incident ticket.

=head2 Customizing MISP Sync with Callbacks

When creating or updating a MISP event, this extension fires two Mason callbacks
that allow you to customize the data sent to and received from MISP without
modifying the extension itself. This can be used to push additional indicators
(domains, hashes, URLs from custom CFs), add taxonomy tags, perform data
mappings, or take action based on the result of the sync.

=over

=item BeforeMISPSync

Fires before the MISP event is created or updated. Receives C<$Ticket>,
C<$Actions>, and C<$ARGSRef>.

=item AfterMISPSync

Fires after the MISP event is created or updated. Receives C<$Ticket>,
C<$Actions>, C<$ARGSRef>, C<$OK> (1 on success, 0 on failure), and C<$Msg>
(the result message). The MISP Event ID is available on the ticket via
C<< $Ticket->FirstCustomFieldValue('MISP Event ID') >>.

=back

Callback files should be placed at:

    html/Callbacks/<YourPlugin>/RTIR/Incident/Display.html/ProcessArguments/BeforeMISPSync
    html/Callbacks/<YourPlugin>/RTIR/Incident/Display.html/ProcessArguments/AfterMISPSync

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RTIR-Extension-MISP@rt.cpan.org">bug-RTIR-Extension-MISP@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RTIR-Extension-MISP">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RTIR-Extension-MISP@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RTIR-Extension-MISP

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

sub GetUserAgent {
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    my $misp_config = RT->Config->Get('ExternalFeeds')->{MISP};
    RT->Logger->error("Unable to load MISP configuration") unless $misp_config;

    my $default_headers = HTTP::Headers->new(
        'Authorization' => $misp_config->[0]{ApiKeyAuth},
        'Accept'        => 'application/json',
        'Content-Type'  => 'application/json',
    );
    $ua->default_headers( $default_headers );
    return $ua;
}

sub GetMISPBaseURL {
    my $misp_config = RT->Config->Get('ExternalFeeds')->{MISP};
    RT->Logger->error("Unable to load MISP configuration") unless $misp_config;

    my $url = $misp_config->[0]{URI};
    return $url;
}

sub FetchEventDetails {
    my $event_id = shift;

    my $url = GetMISPBaseURL();
    return unless $url;

    my $ua = GetUserAgent();

    my $response = $ua->get($url . "/events/$event_id");

    unless ( $response->is_success ) {
        RT->Logger->error('Unable to fetch event data: ' . $response->status_line());
        return 0;
    }

    my $json;
    eval { $json = JSON->new->decode($response->content); };
    return $json;
}

sub AddRTIRObjectToMISP {
    my $ticket = shift;

    my $ua = GetUserAgent();
    my $url = GetMISPBaseURL();

    my $event_id = $ticket->FirstCustomFieldValue('MISP Event ID');
    if ( !$event_id ) {
        ( $event_id, my $msg ) = CreateMISPEvent($ticket);
        if ( !$event_id ) {
            RT->Logger->error("Couldn't load and create event: $msg");
            return ( 0, 'MISP event update failed' );
        }
    }

    # This is base object information defined in MISP
    # See: https://github.com/MISP/misp-objects/blob/main/objects/rtir/definition.json
    my %misp_data = (
        "name" => "rtir",
        "meta-category" => "misc",
        "template_uuid" => "7534ee19-0a1f-4f46-a197-e6e73e457943",
        "description" => "RTIR - Request Tracker for Incident Response",
        "template_version" => "2",
        "uuid" => create_uuid_as_string(UUID_V4),
        "distribution" => "5",
        "sharing_group_id" => "0"
    );

    my %attribute_fields = (
        classification => $ticket->FirstCustomFieldValue('Classification'),
        ip             => $ticket->FirstCustomFieldValue('IP'),
        queue => $ticket->QueueObj->Name,
        status => $ticket->Status,
        subject => $ticket->Subject,
        'ticket-number' => $ticket->Id,
    );

    my @attributes;
    foreach my $attribute ( keys %attribute_fields ) {
        next unless $attribute_fields{$attribute};
        push @attributes, {
            'uuid' => create_uuid_as_string(UUID_V4),
            'object_relation' => $attribute,
            'value' => $attribute_fields{$attribute},
            'type' => $attribute eq 'ip' ? 'ip-dst' : 'text',
            'disable_correlation' => JSON::false,
            'to_ids' => $attribute eq 'ip' ? JSON::true : JSON::false,
            'category' => $attribute eq 'ip' ? 'Network activity' : 'Other'
        }
    }

    if ( my $object_id = $ticket->FirstCustomFieldValue('MISP RTIR Object ID') ) {
        my $response = $ua->get( $url . '/objects/view/' . $object_id );
        if ( $response->is_success ) {
            my $content = decode_json( $response->decoded_content );
            if ( $content->{Object}{deleted} ) {
                RT->Logger->debug("Object $object_id has been deleted, will create a new one");
            }
            else {
                my $failed;
                for my $attribute ( @{ $content->{Object}{Attribute} } ) {
                    next if $attribute->{deleted};
                    my $name = $attribute->{object_relation};
                    if ( ( $attribute_fields{$name} // '' ) ne ( $attribute->{value} // '' ) ) {
                        my $json     = encode_json( { value => $attribute_fields{$name} } );
                        my $response = $ua->put( $url . '/attributes/edit/' . $attribute->{id}, Content => $json );
                        if ( $response->is_success ) {
                            RT->Logger->debug("Updated attribute $attribute->{id}");
                        }
                        else {
                            RT->Logger->error( "Unable to update attribute $attribute->{id}: "
                                    . $response->status_line()
                                    . $response->decoded_content() );
                            $failed ||= 1;
                        }
                    }
                    delete $attribute_fields{$name};
                }

                for my $attribute ( keys %attribute_fields ) {
                    next unless $attribute_fields{$attribute};
                    my ($data)   = grep { $_->{object_relation} eq $attribute } @attributes;
                    my $json     = encode_json( { event_id => $event_id, object_id => $object_id, %$data } );
                    my $response = $ua->post( $url . '/attributes/add/' . $event_id, Content => $json );
                    if ( $response->is_success ) {
                        my $content = decode_json( $response->decoded_content );
                        RT->Logger->debug("Created attribute $content->{Attribute}{id}");
                    }
                    else {
                        RT->Logger->error(
                            "Unable to create attribute: " . $response->status_line() . $response->decoded_content() );
                        $failed ||= 1;
                    }
                }

                if ($failed) {
                    return ( 0, 'MISP event update failed' );
                }
                else {
                    return ( 1, 'MISP event updated' );
                }
            }
        }
        else {
            RT->Logger->error( "Unable to get object $object_id: " . $response->status_line() . $response->decoded_content() );
            return ( 0, 'MISP event update failed' );
        }
    }

    $misp_data{'Attribute'} = \@attributes;
    my $json = encode_json( \%misp_data );

    my $response = $ua->post($url . "/objects/add/" . $event_id, Content => $json);

    if ( $response->is_success ) {
        my $content = decode_json( $response->decoded_content );
        my ( $ret, $msg ) = $ticket->AddCustomFieldValue( Field => 'MISP RTIR Object ID', Value => $content->{Object}{id} );
        if ( !$ret ) {
            RT->Logger->error("Unable to update MISP RTIR Object ID to $content->{Object}{id}: $msg");
        }
    }
    else {
        RT->Logger->error('Unable to add object to event: ' . $response->status_line() . $response->decoded_content());
        return (0, 'MISP event update failed');
    }

    return (1, 'MISP event updated');
}

sub CreateMISPEvent {
    my $ticket = shift;

    my $ua = GetUserAgent();
    my $url = GetMISPBaseURL();
    my $json = encode_json(
        {
            info => $ticket->Subject,
        }
    );
    my $response = $ua->post($url . "/events/add", Content => $json);
    if ( $response->is_success ) {
        my $content = decode_json( $response->decoded_content );
        my ( $ret, $msg ) = $ticket->AddCustomFieldValue( Field => 'MISP Event ID', Value => $content->{Event}{id} );
        if ( !$ret ) {
            RT->Logger->error("Unable to update MISP Event ID to $content->{Event}{id}: $msg");
        }

        ( $ret, $msg ) = $ticket->AddCustomFieldValue( Field => 'MISP Event UUID', Value => $content->{Event}{uuid} );
        if ( !$ret ) {
            RT->Logger->error("Unable to update MISP Event UUID to $content->{Event}{uuid}: $msg");
        }
        return $ticket->FirstCustomFieldValue('MISP Event ID');
    }
    else {
        RT->Logger->error('Unable to create event: ' . $response->status_line() . $response->decoded_content());
        return (0, 'MISP event create failed');
    }
}

{
    use RT::ObjectCustomFieldValue;
    no warnings 'redefine';
    my $orig = \&RT::ObjectCustomFieldValue::_FillInTemplateURL;
    *RT::ObjectCustomFieldValue::_FillInTemplateURL = sub {
        my $self = shift;
        my $url  = shift;
        return undef unless defined $url && length $url;
        my $misp_url = RT->Config->Get('ExternalFeeds')->{MISP}[0]{URI};
        $url =~ s!__MISPURL__!$misp_url!g;
        return $orig->( $self, $url );
    };
}

1;
