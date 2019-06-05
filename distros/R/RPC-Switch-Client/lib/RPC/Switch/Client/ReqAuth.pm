package RPC::Switch::Client::ReqAuth;

use Mojo::Base -base;

use Scalar::Util qw(blessed);

# subclasses are supposed to implement these:
sub logout {
	...
}

sub refresh {
	...
}

sub expiration {
	...
}

sub scope {
	...
}

# simplistic default:
sub _to_reqauth {
	my ($self) = @_;
	my %r = %$self;
	my ($at) = blessed($self) =~ /::(\w+)$/;
	$r{auth_type} = lc $at;
	return \%r;
}

1;
