use strict;
use warnings;
package RTIR::Extension::MISP;

use LWP::UserAgent;
use JSON;
use UUID::Tiny ':std';

our $VERSION = '0.02';

RT->AddStyleSheets('rtir-extension-misp.css');

=head1 NAME

RTIR-Extension-MISP - Integrate RTIR with MISP

=head1 DESCRIPTION

L<MISP|https://www.misp-project.org/> is a platform for sharing threat intelligence among
security teams, and this extension provides integration from L<RTIR/https://bestpractical.com/rtir>.

=head1 RTIR VERSION

Works with RTIR 5.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Patch RTIR for versions prior to 5.0.2

    patch -p1 -d /opt/rt5/local/plugins/RT-IR < patches/Add-callbacks-to-the-feed-listing-and-display-pages.patch

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RTIR::Extension::MISP');

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you will end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

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

If you want to display the MISP ID custom fields in a separate portlet on the
incident page, you can customize your custom field portlets with something
like this:

    Set(%CustomFieldGroupings,
        'RTIR::Ticket' => [
            'Networking'     => ['IP', 'Domain'],
            'Details' => ['How Reported','Reporter Type','Customer',
                          'Description', 'Resolution', 'Function', 'Classification',
                          'Customer',
                          'Netmask','Port','Where Blocked'],
            'MISP IDs'     => ['MISP Event ID', 'MISP Event UUID'],  # Add/remove CFs as needed
        ],
    );

=head1 DETAILS

This integration adds several different ways to work between the MISP and
RTIR systems as described below.

=head2 Consume Feed from MISP

After adding the MISP configuration described above, the Feeds page in RTIR at
RTIR > Tools > External Feeds will have a new MISP option listed. This feed
pulls in events for the past X number of days based on the DaysToFetch
configuration. From the feed display page, you can click the "Create new ticket"
button to create a ticket with information from the MISP event.

=head2 MISP Portlet on Incident Display

On the Incident Display page, if the custom field MISP Event ID has a value,
a portlet MISP Event Details will be displayed, showing details pulled in
from the event via the MISP REST API.

=head2 Update MISP Event

On an incident with a MISP Event ID, the Actions menu will have an option
"Update MISP Event". If you select this action, RTIR will update the existing
MISP event with an RTIR object, including data from the incident ticket.

=head2 Create MISP Event

If MISP Event ID has no value, the Actions menu on incidents shows an option to
"Create MISP Event". Select this to create an event in MISP with details from
the incident ticket.

=head2 

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
