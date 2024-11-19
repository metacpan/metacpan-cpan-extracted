package STIX::Observable::Extension::HTTPRequest;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str InstanceOf Int HashRef);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    request_method
    request_value
    request_version
    request_header
    message_body_length
    message_body_data_ref
]);

use constant EXTENSION_TYPE => 'http-request-ext';

has request_method        => (is => 'rw', required => 1, isa => Str);
has request_value         => (is => 'rw', required => 1, isa => Str);
has request_version       => (is => 'rw', isa      => Str);
has request_header        => (is => 'rw', isa      => HashRef);
has message_body_length   => (is => 'rw', isa      => Int);
has message_body_data_ref => (is => 'rw', isa      => InstanceOf ['STIX::Observable::Artifact']);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::HTTPRequest - STIX Cyber-observable Object (SCO) - HTTP Request Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::HTTPRequest;

    my $http_request_ext = STIX::Observable::Extension::HTTPRequest->new();


=head1 DESCRIPTION

The HTTP request extension specifies a default extension for capturing network
traffic properties specific to HTTP requests.


=head2 METHODS

L<STIX::Observable::Extension::HTTPRequest> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::HTTPRequest->new(%properties)

Create a new instance of L<STIX::Observable::Extension::HTTPRequest>.

=item $http_request_ext->request_method

Specifies the HTTP method portion of the HTTP request line, as a lowercase string.

=item $http_request_ext->request_value

Specifies the value (typically a resource path) portion of the HTTP request line.

=item $http_request_ext->request_version

Specifies the HTTP version portion of the HTTP request line, as a lowercase string.

=item $http_request_ext->request_header

Specifies all of the HTTP header fields that may be found in the HTTP client
request, as a dictionary.

=item $http_request_ext->message_body_length

Specifies the length of the HTTP message body, if included, in bytes.

=item $http_request_ext->message_body_data_ref

Specifies the data contained in the HTTP message body, if included.

=back


=head2 HELPERS

=over

=item $http_request_ext->TO_JSON

Helper for JSON encoders.

=item $http_request_ext->to_hash

Return the object HASH.

=item $http_request_ext->to_string

Encode the object in JSON.

=item $http_request_ext->validate

Validate the object using JSON Schema (see L<STIX::Schema>).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
