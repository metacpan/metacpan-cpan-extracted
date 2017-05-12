package Net::OpenID::JanRain::Consumer::Stores::DumbStore;

# vi:ts=4:sw=4

use warnings;
use strict;

use Carp;
use Digest::SHA1 qw(sha1);

use base qw(Net::OpenID::JanRain::Consumer::Stores);

sub new {
	my $caller = shift;
	my ($secret_phrase) = @_;
	my $class = ref($caller) || $caller;
	my $self = {
		auth_key => sha1($secret_phrase),
		};
	bless($self, $class);
	return($self);
} # end new

########################################################################
use constant {  # constant, method, accessor.  meh.
	# all of these just return undef
	storeAssociation  => undef(),
	getAssociation    => undef(),
	removeAssociation => undef(),
	storeNonce        => undef(),
	# and these are true
	useNonce          => 1,
	isDumb            => 1,
	};
########################################################################

sub getAuthKey {
	my $self = shift;
	return($self->{auth_key});
} # end getAuthKey
########################################################################

1;
