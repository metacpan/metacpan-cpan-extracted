package MooseX::Fastly::Role;
$MooseX::Fastly::Role::VERSION = '0.04';
use Moose::Role;
use Net::Fastly 1.08;
use Carp;
use HTTP::Tiny;

requires 'config';    # Where we can read our config from?!?

=head1 NAME

MooseX::Fastly::Role - Fastly api from config, and purge methods

=head1 SYSOPSIS

  package My::App::CDN::Manager;

  use Moose;

  has config => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        {
              fastly_api_key => 'XXXXX',
              fastly_service_id => 'YYYYY',
        };
    },
  );

  with 'MooseX::Fastly::Role';

  $self->cdn_purge_now({
    keys => [ 'foo', 'bar' ],
    soft_purge => 1,
  });

  $self->cdn_purge_all();

  my $fastly = $self->cdn_api();
  my $services = $self->cdn_services();

=head1 DESCRIPTION

L<Fastly|https://www.fastly.com/> is a global CDN (Content Delivery Network),
used by many companies. This module requires a C<config> method to return
a hashref. This packages uses L<HTTP::Tiny> for most calls (so that you can
use Fastly's token authentication for purging keys), but also provides
accessors to L<Net::Fastly> for convenience.

=head1 METHODS

=head2 cdn_purge_now

  $self->cdn_purge_now({
    keys => [ 'foo', 'bar' ],
    soft_purge => 1,
  });

Purge is called on all services, for each key.

=cut

sub cdn_purge_now {
    my ( $self, $args ) = @_;

    my $services = $self->_cdn_service_ids_from_config();

    foreach my $service_id ( @{$services} ) {
        foreach my $key ( @{ $args->{keys} || [] } ) {
            my $url = "/service/${service_id}/purge/${key}";
            $self->_call_fastly_http_client( $url, $args->{soft_purge} );
        }
    }

    return 1;
}

sub _call_fastly_http_client {
    my ( $self, $url, $soft_purge ) = @_;
    $soft_purge ||= '0';

    my $full_url = 'https://api.fastly.com' . $url;

    $self->_log_fastly_call("Purging ${url}");

    my $http_requester = $self->_fastly_http_client();
    return unless $http_requester;

    my $response = $http_requester->post( $full_url,
        { 'Fastly-Soft-Purge' => $soft_purge, } );

    if ( !$response->{success} || $response->{content} !~ '"status": "ok"' ) {
        $self->_log_fastly_call(
            "Failed to purge: $full_url" . $response->{content} || '' );
    }

}

sub _log_fastly_call {
    if ( $ENV{DEBUG_FASTLY_CALLS} ) {
        warn $_[1];
    }
}

=head2 cdn_purge_all

  $self->cdn_purge_all();

Purge all is called on all services

=cut

sub cdn_purge_all {
    my ( $self, $args ) = @_;

    my $services = $self->_cdn_service_ids_from_config();

    foreach my $service_id ( @{$services} ) {
        foreach my $key ( @{ $args->{keys} || [] } ) {
            my $url = "/service/${service_id}/purge_all";
            $self->_call_fastly_http_client( $url, $args->{soft_purge} );
        }
    }

    return 1;
}


sub _cdn_service_ids_from_config {
    my $self = $_[0];
    my @service_ids;

    my $service_ids = $self->config->{fastly_service_id};

    return \@service_ids unless $service_ids;

    @service_ids
        = ref($service_ids) eq 'ARRAY' ? @{$service_ids} : ($service_ids);
    return \@service_ids;
}

has '_fastly_http_client' => (
    is         => 'ro',
    lazy_build => '_build__fastly_http_client',
);

sub _build__fastly_http_client {
    my $self = $_[0];

    my $token = $self->config->{fastly_api_key};
    return unless $token;

    my $http_requester = HTTP::Tiny->new(
        default_headers => {
            'Fastly-Key' => $token,
            'Accept'     => 'application/json'
        },
    );
    return $http_requester;
}


=head1 Net::Fastly

Methods below return objects from Net::Fastly.

=head2 cdn_api

  my $cdn_api = $self->cdn_api();

If there is a B<fastly_api_key> in C<config> a C<Net::Fastly> instance is
created and returned. Otherwise undef is returned (so you can develope
safely if you do not set B<fastly_api_key> in the C<config>).

=cut

has 'cdn_api' => (
    is         => 'ro',
    lazy_build => '_build_cdn_api',
);

sub _build_cdn_api {
    my $self = $_[0];

    my $api_key = $self->config->{fastly_api_key};
    return undef unless $api_key;

    # We have the credentials, so must be on production
    my $fastly = Net::Fastly->new( api_key => $api_key );
    return $fastly;
}


=head2 cdn_services

   my $services = $self->cdn_services();

An array reference of C<Net::Fastly::Service> objects, based on the
C<fastly_service_id> id(s) set in C<config>.

The array reference will be empty if C<fastly_service_id> is not found
in C<config>.

=cut

has 'cdn_services' => (
    is         => 'ro',
    lazy_build => '_build_cdn_services',
);

sub _build_cdn_services {
    my ( $self, $args ) = @_;

    my @services;

    my $service_ids = $self->config->{fastly_service_id};
    return \@services unless $service_ids;

    my $cdn_api = $self->cdn_api();
    return \@services unless $cdn_api;

    my @service_ids
        = ref($service_ids) eq 'ARRAY' ? @{$service_ids} : ($service_ids);

    @services = map { $cdn_api->get_service($service_ids) } @service_ids;

    return \@services;
}

=head1 AUTHOR

Leo Lapworth <LLAP@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms same as Perl 5.

=cut

1;
