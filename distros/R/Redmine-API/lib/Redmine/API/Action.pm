#
# This file is part of Redmine-API
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Redmine::API::Action;

# ABSTRACT: Action to the API
use strict;
use warnings;
our $VERSION = '0.04';    # VERSION
use Moo;

use Carp;
use JSON;
use REST::Client;

has 'request' => (
    is  => 'ro',
    isa => sub {
        croak "request should be a Redmine::API::Request object"
            unless ref $_[0] eq 'Redmine::API::Request';
    },
    required => 1,
);

has 'action' => (
    is       => 'ro',
    required => 1,
);

has '_rest_cli' => ( is => 'lazy' );

sub _build__rest_cli {
    my ($self) = @_;
    my $api = $self->request->api;

    my $cli = REST::Client->new();
    $cli->setHost( $api->base_url );
    $cli->addHeader( 'X-Redmine-API-Key' => $api->auth_key );
    $cli->addHeader( 'Content-Type'      => 'application/json' );
    $cli->addHeader( 'Accept'            => 'application/json' );
    return $cli;

}

sub create {
    my ( $self, %data ) = @_;
    return $self->formatResponse(
        $self->_rest_cli->POST(
            '/' . $self->request->route . '.json',
            encode_json( { $self->action => \%data } ),
        )
    );
}

sub all {
    my ( $self, %options ) = @_;
    return $self->formatResponse(
        $self->_rest_cli->GET(
                  '/'
                . $self->request->route . '.json'
                . $self->_rest_cli->buildQuery( \%options )
        )
    );
}

sub get {
    my ( $self, $id, %options ) = @_;
    return $self->formatResponse(
        $self->_rest_cli->GET(
                  '/'
                . $self->request->route . '/'
                . $id . '.json'
                . $self->_rest_cli->buildQuery( \%options )
        )
    );
}

sub del {
    my ( $self, $id ) = @_;
    return $self->formatResponse(
        $self->_rest_cli->DELETE(
            '/' . $self->request->route . '/' . $id . '.json'
        )
    );
}

sub update {
    my ( $self, $id, %data ) = @_;
    return $self->formatResponse(
        $self->_rest_cli->PUT(
            '/' . $self->request->route . '/' . $id . '.json',
            encode_json( { $self->action => \%data } ),
        )
    );
}

sub formatResponse {
    my ( $self, $req ) = @_;

    return {} if $req->responseCode == 404;

    croak "ERROR ", $req->responseCode,
        " : ACCESS FORBIDDEN, CHECK YOUR TOKEN !"
        if $req->responseCode == 401;
    croak "ERROR ", $req->responseCode, " : ", $req->responseContent
        if $req->responseCode >= 500;

    return {} if !length( $req->responseContent );

    my $resp;
    if ( !eval { $resp = decode_json( $req->responseContent ); 1 } ) {
        croak "Bad JSON format : ", $req->responseContent;
    }

    return $resp;
}

1;

__END__

=pod

=head1 NAME

Redmine::API::Action - Action to the API

=head1 VERSION

version 0.04

=head1 METHODS

=head2 create

Create entry into Redmine.

Args: %data

data is pass thought payload

=head2 all

Get all data from Redmine.

Args: %options

You can pass offset, limit ...

=head2 get

Get one entry from Redmine.

Args: $id, %options

=head2 del

Delete one entry from Redmine

Args: $id

=head2 update

Update one entry from Redmine

Args: $id, %data

data is pass thought payload to Redmine

=head2 formatResponse

return response except if the message has not the right status

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/Redmine-API/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
