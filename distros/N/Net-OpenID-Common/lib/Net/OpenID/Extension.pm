
package Net::OpenID::Extension;
$Net::OpenID::Extension::VERSION = '1.20';
use strict;

=head1 NAME

Net::OpenID::Extension - Base class for OpenID extensions

=head1 VERSION

version 1.20

=head1 METHODS

=head2 CLASS->namespace_uris

Return a hashref mapping namespace URIs to the aliases you will use
to refer to them in the other methods. For example:

    return {
        'http://example.com/some-extension' => 'someext',
    };

=head2 CLASS->new_request(@parameters)

When your extension is added to the L<Net::OpenID::ClaimedIdentity>
object in consumer-land, this method will be called to create
a request object. Any additional arguments passed when adding the
extension will be passed through verbatim in C<@parameters>.

The object you return here should at minimum provide the interface
defined in L<Net::OpenID::ExtensionMessage>.

You can return C<undef> here if you have nothing useful to return.

=head2 CLASS->received_request(\%args)

In server-land, when a caller asks for the request object for your
extension this method will be called to create a request object.
C<%args> maps the aliases you returned from the C<namespace_uris>
method to a hashref of the key-value pairs provided in that namespace.

The object you return here should at minimum provide the interface
defined in L<Net::OpenID::ExtensionMessage>, and should behave
identically to the corresponding object returned from C<new_request>.

You can return C<undef> here if you have nothing useful to return.

=head2 CLASS->new_response(@parameters)

When your extension is added to the response in server-land, this
method will be called to create a response object. Any additional
arguments passed when adding the extension will be passed through
verbatim in C<@parameters>.

You can return C<undef> here if you have nothing useful to return.

=head2 CLASS->received_response(\%args)

In consumer-land, when a caller asks for the request object for
your extension in L<Net::OpenID::VerifiedIdentity> this method
will be called to create a response object.
C<%args> maps the aliases you returned from the C<namespace_uris>
method to a hashref of the key-value pairs provided in that namespace.

You can return C<undef> here if you have nothing useful to return.

=cut

sub namespace_uris {
    return {};
}

sub new_request {
    return undef;
}

sub new_response {
    return undef;
}

sub received_request {
    return undef;
}

sub received_response {
    return undef;
}

1;
