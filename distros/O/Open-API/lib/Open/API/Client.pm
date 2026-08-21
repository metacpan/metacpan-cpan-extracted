package Open::API::Client;

use 5.008003;
use strict;
use warnings;
use Open::API;   # loads the shared XS

our $VERSION = '0.11';

1;

__END__

=head1 NAME

Open::API::Client - a spec-driven HTTP client on Fetch's C ABI

=head1 SYNOPSIS

    my $client = Open::API::Client->new(
        spec     => 'openapi.json',      # or api => $open_api
        base_url => 'http://127.0.0.1:3000',
    );

    my $res = $client->call('getPet', petId => 42)->get;
    # { status => 200, headers => {...}, data => { id => 42, ... } }

    # operationId sugar (same as call):
    $res = $client->getPet(petId => 42)->get;

=head1 DESCRIPTION

Builds requests from the same compiled OpenAPI document the server side
uses: parameters are validated client-side through the compiled
L<JSON::Schema::Fast> handles BEFORE any I/O (bad input croaks), the URL,
query, headers, cookies and JSON body are assembled in C, and the request is
fired through L<Fetch>'s C ABI. Every call returns a L<Fetch::Future>: C<get>
awaits it synchronously, or pass C<< loop => >> at construction to share an
event loop and run calls concurrently.

The future resolves to a hashref: C<status>, C<headers> (lowercased names),
C<data> (JSON-decoded body when the response is C<application/json>, raw bytes
otherwise), and on failure C<error> (with C<status> 0 for transport errors).
With C<< validate => 1 >>, a response that does not match the operation's
response schema gets C<error> and C<errors> set.

=head1 CONSTRUCTOR

    Open::API::Client->new(%opts);

C<api> (an L<Open::API>) or C<spec> (anything L<Open::API/new> accepts) is
required, as is C<base_url>. C<validate> (default 0) checks response bodies
against the spec. All other options (C<timeout>, C<tls_verify>, C<pool_size>,
C<loop>, ...) are passed to L<Fetch>'s constructor on first use.

=head1 METHODS

=head2 call

    my $future = $client->call($operationId, %params);

Flat C<%params> are matched to the operation's declared parameters by name
(C<body> is the request body). Croaks before any I/O when a required
parameter is missing or a value fails its schema.

=head2 api

The underlying L<Open::API> object.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
