package RT::Extension::AI::Provider;

use strict;
use warnings;
use LWP::UserAgent;

sub default_headers {
    my ( $class, $config ) = @_;
    return {
        'Authorization' => "Bearer $config->{api_key}",
        'Content-Type'  => 'application/json'
    };
}

=head2 new config => %config

Accepts a hash that is the main AI config for the current queue.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $config = $args{config};

    unless ( $config->{url} ) {
        RT->Logger->error("Missing $class API URL");
        return;
    }
    unless ( $config->{api_key} ) {
        RT->Logger->error("Missing $class API key");
        return;
    }

    $config->{ua} = $class->create_user_agent(
        timeout => $config->{timeout},
        headers => $class->default_headers($config)
    );

    $config->{api_url} = $config->{url};

    return bless $config, $class;
}

sub process_request {
    die "Method 'process_request' not implemented in the provider";
}

sub create_user_agent {
    my $self = shift;
    my (%args) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout($args{timeout} // 10);
    $ua->env_proxy;

    if ( $args{headers} ) {
        foreach my $header ( keys %{ $args{headers} } ) {
            $ua->default_header( $header => $args{headers}{$header} );
        }
    }

    return $ua;
}

1;
