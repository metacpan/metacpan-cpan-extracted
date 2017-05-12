package OpenSourceOrg::API;

use strict;
use warnings;
use utf8;

our $VERSION = '0.001';    # VERSION

# ABSTRACT: Perl API Bindings to the OSI License API

use Moo;
use REST::Client;
use Const::Fast;
use JSON;
use Carp;

const my $base_url => 'https://api.opensource.org';

has _api_client => ( is => 'lazy' );

sub _build__api_client {
    my $client = REST::Client->new();
    $client->setHost($base_url);
    return $client;
}

sub all {
    my $self   = shift();
    my $client = $self->_api_client;
    return $self->_handle_response( $client->GET('/licenses/') );
}

sub tagged {
    my $self    = shift();
    my $keyword = shift();
    my $client  = $self->_api_client;
    return $self->_handle_response( $client->GET( '/licenses/' . $keyword ) );
}

sub get {
    my $self   = shift();
    my $osi_id = shift();
    my $client = $self->_api_client;
    return $self->_handle_response( $client->GET( '/license/' . $osi_id ) );
}

sub get_by_scheme {
    my $self   = shift();
    my $scheme = shift();
    my $id     = shift();
    my $client = $self->_api_client;
    return $self->_handle_response( $client->GET( '/license/' . join( '/', $scheme, $id ) ) );
}

sub _handle_response {
    my $self     = shift();
    my $response = shift();
    if ( $response->responseCode() == 200 ) {
        return from_json( $response->responseContent );
    } else {
        croak 'Error: ' . $response->responseCode() . ". Content: " . $response->responseContent;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSourceOrg::API - Perl API Bindings to the OSI License API 

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use OpenSourceOrg::API;
    my $client = OpenSourceOrg::API->new();
    my $all_licenses = $client->all();
    my $permisive_licenses = $client->tagged('permissive');
    my $mit = $client->get('MIT');
    my $Mozilla_2_0 = $client->get_by_scheme('SPDX', 'MPL-2.0');

=head1 DESCRIPTION

OpenSOurceOrg::API is an API Wrapper that allows you to query the Open Source License API with Perl.

L<https://github.com/OpenSourceOrg/api/blob/master/doc/endpoints.md>

=head1 METHODS

=head2 all

Get a list of all known licenses. 

The response is the perl equivalent of the json returned by the api,
documented in L<https://github.com/OpenSourceOrg/api/blob/master/doc/endpoints.md#schema>

=head2 tagged

Find all licenses tagged with a C<keyword> as defined in 
L<https://github.com/OpenSourceOrg/api/blob/master/doc/endpoints.md#keywords>

=head2 get

Get a license by its OSI ID

=head2 get_by_scheme

Get a license by its Scheme ID

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
