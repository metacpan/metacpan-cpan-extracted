
package Net::OpenID::ExtensionMessage;
$Net::OpenID::ExtensionMessage::VERSION = '1.20';
use strict;

=head1 NAME

Net::OpenID::ExtensionMessage - Base class for extension messages

=head1 VERSION

version 1.20

=head1 DESCRIPTION

Instances of implementations of the interface provided by this
package are returned from various methods in L<Net::OpenID::Extension>
implementations.

=head1 METHODS

=head2 $emsg->extension_arguments

Return a hashref that maps extension namespace aliases as defined
in the corresponding L<Net::OpenID::Extension> to hashrefs of
key-value pairs for the arguments to include in that namespace.

=cut

sub extension_arguments {
    return {};
}

1;
