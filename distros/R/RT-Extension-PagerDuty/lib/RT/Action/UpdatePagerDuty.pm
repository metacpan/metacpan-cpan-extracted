package RT::Action::UpdatePagerDuty;

use strict;
use warnings;
use base 'RT::Action';

use HTTP::Request::Common qw(POST PUT GET);
use LWP::UserAgent;

sub Prepare {
    my $self = shift;

    return 1;
}

sub Commit {
    my $self = shift;

    my $config = RT::Config->Get('PagerDuty');
    unless ($config) {
        RT->Logger->error('PagerDuty config not set');
        return 0;
    }

    my $service_id
        = $config->{queues}{ $self->TicketObj->QueueObj->Name }{service}
        // $config->{queues}{'*'}{service};
    unless ($service_id) {
        RT->Logger->error( 'PagerDuty no service id found for queue: '
                . $self->TicketObj->QueueObj->Name );
        return 0;
    }

    my $service = $config->{services}{$service_id}
        // $config->{services}{'*'};
    unless ($service) {
        RT->Logger->error(
            "PagerDuty no service config found for id: $service_id");
        return 0;
    }

    my $token = $service->{api_token};
    my $user  = $service->{api_user};
    unless ( $token && $user ) {
        RT->Logger->error(
            "PagerDuty service config missing token or user for service id: $service_id"
        );
        return 0;
    }

    my $arg = lc( $self->Argument );
    if ( $arg eq 'trigger' ) {
        return $self->_trigger( $service_id, $token, $user );
    } else {
        return $self->_update( $arg, $token, $user );
    }
}

sub _trigger {
    my ( $self, $service_id, $token, $user ) = @_;

    if ( $self->TicketObj->FirstCustomFieldValue('PagerDuty ID') ) {

        # this ticket already has a PagerDuty ID filled in
        # that means it was created by PagerDuty webhook
        # so do not need to create incident
        RT->Logger->debug(
            'PagerDuty skipping ticket trigger as it was created by PagerDuty webhook'
        );
        return 1;
    }

    my $ua = LWP::UserAgent->new;
    $ua->timeout(15);

    my $id      = $self->TicketObj->id;
    my $tag     = $self->TicketObj->SubjectTag;
    my $subject = $self->TicketObj->Subject;
    my $content = $self->TransactionObj->Content( Type => 'text/plain' );

    my %post_content = (
        incident => {
            type    => "incident",
            title   => "$tag $subject",
            service => {
                id   => $service_id,
                type => "service_reference"
            },
            incident_key => $tag,
            body         => {
                type    => "incident_body",
                details => $content
            }
        }
    );

    my $post_content = JSON::to_json( \%post_content );

    RT->Logger->debug("PagerDuty POST: $post_content");

# https://developer.pagerduty.com/api-reference/b3A6Mjc0ODE0MA-create-an-incident
    my $req = POST(
        'https://api.pagerduty.com/incidents',
        'Accept',
        'application/vnd.pagerduty+json;version=2',
        'Authorization',
        "Token token=$token",
        'Content-Type',
        'application/json',
        'From',
        $user,
        CONTENT => $post_content
    );

    my $resp = $ua->request($req);

    RT->Logger->debug( 'PagerDuty got response: '
            . $resp->status_line . ' '
            . $resp->decoded_content() );

    unless ( $resp->is_success ) {
        RT->Logger->error(
            'PagerDuty request failed: ' . $resp->status_line );
        return 0;
    }

# update PagerDuty custom fields
# XXX - allow arbitrary PagerDuty custom fields and parse name for /PagerDuty\s*($field_name)/
#       where $field_name matches a field returned from the API
#       would want to make field names "prettier" so maybe map _ => - and uppercase first letter of each word?
    my $return = JSON::from_json( $resp->decoded_content );
    my ( $status, $msg ) = $self->TicketObj->AddCustomFieldValue(
        Field => 'PagerDuty ID',
        Value => $return->{incident}->{id} // ''
    );
    unless ($msg) {
        RT->Logger->error("PagerDuty could not set PagerDuty ID field: $msg");
    }
    ( $status, $msg ) = $self->TicketObj->AddCustomFieldValue(
        Field => 'PagerDuty URL',
        Value => $return->{incident}->{html_url} // ''
    );
    unless ($msg) {
        RT->Logger->error(
            "PagerDuty could not set PagerDuty URL field: $msg");
    }

    return 1;
}

sub _update {
    my ( $self, $status, $token, $user ) = @_;

    $status //= '';

    # try to allow some flexibility in the status parameter
    if ( $status =~ /^resolve/i ) {
        $status = 'resolved';
    } elsif ( $status =~ /^ack/i ) {
        $status = 'acknowledged';
    }

    my $ua = LWP::UserAgent->new;
    $ua->timeout(15);

    my $pd_id = $self->TicketObj->CustomFieldValuesAsString('PagerDuty ID');

    # XXX - should it fail here? any way to show an error to user from here?
    #       or do we just assume no pd id means no incident to worry about?
    return 1 unless $pd_id;

    RT->Logger->debug("PagerDuty GET $pd_id");
    my $req = GET(
        'https://api.pagerduty.com/incidents/' . $pd_id,
        'Accept',
        'application/vnd.pagerduty+json;version=2',
        'Authorization',
        "Token token=$token",
        'Content-Type',
        'application/json',
    );
    my $resp = $ua->request($req);
    if ( $resp->is_success ) {
        my $return = JSON::from_json( $resp->decoded_content );
        if ( $return->{incident}{status} eq $status ) {
            RT->Logger->debug("PagerDuty incident is already $status");
            return 1;
        }
    }
    else {
        RT->Logger->error( 'PagerDuty request failed: ' . $resp->status_line );
        # Not return here as we still want to try to PUT even if GET fails
    }

    my %content = (
        incident => {
            type   => "incident",
            status => $status
        }
    );

    my $content = JSON::to_json( \%content );

    RT->Logger->debug("PagerDuty PUT: $content");

# https://developer.pagerduty.com/api-reference/b3A6Mjc0ODE0Mg-update-an-incident
    $req = PUT(
        'https://api.pagerduty.com/incidents/' . $pd_id,
        'Accept',
        'application/vnd.pagerduty+json;version=2',
        'Authorization',
        "Token token=$token",
        'Content-Type',
        'application/json',
        'From',
        $user,
        CONTENT => $content
    );

    $resp = $ua->request($req);

    RT->Logger->debug( 'PagerDuty got response: '
            . $resp->status_line . ' '
            . $resp->decoded_content() );

    unless ( $resp->is_success ) {
        RT->Logger->error(
            'PagerDuty request failed: ' . $resp->status_line );
        return 0;
    }

    return 1;
}

1;
