package Net::OpenID::JanRain::Stores;

# vi:ts=4:sw=4

use warnings;
use strict;

use Carp;

########################################################################
# A model for a real store...
package Net::OpenID::JanRain::OpenIDStore;

# XXX do something else with this?
our $AUTH_KEY_LEN = 20;

sub storeAssociation {
	my $self = shift;
	my ($association) = @_;
	die "Not Implemented";
} # end storeAssociation
########################################################################
sub getAssociation {
	my $self = shift;
	my ($server_url) = @_;
	die "Not Implemented";
} # end getAssociation
########################################################################
sub removeAssociation {
	my $self = shift;
	my ($server_url, $handle) = @_;
	die "Not Implemented";
} # end removeAssociation
########################################################################
sub storeNonce {
	my $self = shift;
	my ($nonce) = @_;
	die "Not Implemented";
} # end storeNonce
########################################################################
sub useNonce {
	my $self = shift;
	my ($nonce) = @_;
	die "Not Implemented";
} # end useNonce
########################################################################
sub getAuthKey {
	my $self = shift;
	die "Not Implemented";
} # end getAuthKey
########################################################################
sub isDumb {
	my $self = shift;
	return(undef());
} # end isDumb
########################################################################
1;
