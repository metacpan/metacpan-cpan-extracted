use warnings;
use strict;
package RT::Authen::OAuth2::Unimplemented;

our $VERSION = '0.01';

use Net::OAuth2::Profile::WebServer;
use JSON;

=head1 NAME

RT::Authen::OAuth2::Unimplemented - stub to die on unimplemented integrations

=cut

sub Metadata {
    my ($self) = @_;
    die ("Error - Unimplemented OAuth2 identity provider.");    
}
