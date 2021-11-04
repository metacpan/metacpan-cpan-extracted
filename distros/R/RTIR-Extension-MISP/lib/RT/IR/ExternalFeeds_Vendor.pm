package RT::IR::ExternalFeeds;

use strict;
use warnings;

use LWP::UserAgent;
use JSON;

sub InitMISP {
    my $self = shift;
    my $misp_config = RT->Config->Get('ExternalFeeds')->{MISP};

    unless ( $misp_config ) {
        RT->Logger->error("No MISP configuration found in \%ExternalFeeds");
        return (0, 'No MISP configuration found');
    }

    my $i = 1;
    foreach my $misp_feed ( @$misp_config ) {
        next unless (ref $misp_feed eq 'HASH');
        $misp_feed->{index} = $i++;
        $self->{misp_feeds}{$misp_feed->{Name}} = $misp_feed;
        $self->{have_misp_feeds} ||= 1;
    }
    return(1, 'MISP initialized');
}

sub have_misp_feeds {
    return shift()->{have_misp_feeds};
}

sub misp_feeds {
    my $self = shift;
    return sort { $a->{index} <=> $b->{index} } values %{$self->{misp_feeds}};
}

sub fetch_misp_feed {
    my ($self, $name, $current_user) = @_;
    my $url = $self->{misp_feeds}{$name}{URI};
    # make sure we have a fairly short timeout so page doesn't get apache timeout.

    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    my $default_headers = HTTP::Headers->new(
        'Authorization' => $self->{misp_feeds}{$name}{ApiKeyAuth},
        'Accept'        => 'application/json',
        'Content-Type'  => 'application/json',
    );
    $ua->default_headers( $default_headers );

    my $days_to_fetch = $self->{misp_feeds}{$name}{DaysToFetch} || 1;
    my $date = RT::Date->new($current_user);
    $date->SetToNow;
    $date->AddDays(-$days_to_fetch);

    my $args = { "searchDatefrom" => $date->ISO };
    my $json = encode_json( $args );

    my $response = $ua->post($url . '/events/index', Content => $json);
    return $self->_parse_misp_feed($response);
}

sub _parse_misp_feed {
    my $self = shift;
    my $response = shift;

    return { __error => "Can't reach feed : " . $response->status_line } unless ($response->is_success);

    my $json;
    eval { $json = JSON->new->decode($response->content); };
    if ( $@ ) {
        return { __error => "Couldn't parse JSON response "};
        RT->Logger->error("Could not parse JSON: $@");
    }

    my $parsed_feed;
    foreach my $event ( @$json ) {
        my $event_values = {
            date => $event->{date},
            info => $event->{info},
            id => $event->{id},
            uuid => $event->{uuid},
            threat_level_id => $event->{threat_level_id},
            creator_org => $event->{Orgc}{name},
        };
        push (@{$parsed_feed->{items}}, $event_values);
    }

    return $parsed_feed;
}


1;
