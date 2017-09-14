package Patro::N1;
use strict;
use warnings;

# Patro::N1. Proxy class for HASH type references

# we must keep this namespace very clean
use Carp ();

use overload
    '%{}' => sub { ${$_[0]}->{hash} },
    'nomethod' => \&Patro::LeumJelly::overload_handler,
    ;

# override UNIVERSAL methods
foreach my $umethod (keys %UNIVERSAL::) {
    no strict 'refs';
    *{$umethod} = sub {
	my $proxy = shift;
	if (!CORE::ref($proxy)) {
	    package
		UNIVERSAL;
	    return &$umethod($proxy,@_);
	}
	my $context = defined(wantarray) ? 1 + wantarray : 0;
	return Patro::LeumJelly::proxy_request( $$proxy,
	    { id => $$proxy->{id}, topic => 'METHOD', command => $umethod,
	      has_args => @_ > 0, args => [ @_ ], context => $context }, @_ );
    };
}

sub AUTOLOAD {
    my $method = $Patro::N1::AUTOLOAD;
    $method =~ s/.*:://;

    my $self = shift;
    my $has_args = @_ > 0;
    my $args = [ @_ ];

    my $context = defined(wantarray) ? 1 + wantarray : 0;

    return Patro::LeumJelly::proxy_request( $$self, 
	{ id => $$self->{id},
	  topic => 'METHOD',
	  command => $method,
	  has_args => $has_args,
	  args => $args,
	  context => $context,
	  _autoload => 1 }, @_ );
}

sub DESTROY {
    my $self = shift;
    if ($$self->{_DESTROY}++) {
	return;
    }
    my $socket = $$self->{socket};
    if ($socket) {

	# XXX - shouldn't disconnect on every object destruction,
	# only when all of the wrapped objects associated with a
	# client have been destroyed, or during global
	# destruction

	my $response = Patro::LeumJelly::proxy_request(
	    $$self,
	    { id => $$self->{id},
	      topic => 'META',
	      #command => 'disconnect' } );
	      command => 'destroy' } );
	if ($response->{disconnect_ok}) {
	    close $socket;
	    delete $$self->{socket};
	}
    }
}

############################################################

# tie class for hash proxy object. Operations on the proxy
# are forwarded to the remote server

sub Patro::Tie::HASH::TIEHASH {
    my ($pkg,$proxy) = @_;
    return bless { obj => $proxy, id => $proxy->{id} }, $pkg;
}

sub Patro::Tie::HASH::__ {
    my $tied = shift;
    my $name = shift;
    my $context = shift;
    if (!defined($context)) {
	$context = defined(wantarray) ? 1 + wantarray : 0;
    }
    return Patro::LeumJelly::proxy_request(
	$tied->{obj},
	{ topic => 'HASH',
	  command => $name,
	  context => $context,
	  has_args => @_ > 0,
	  args => [ @_ ],
	  id => $tied->{id} }, @_ );
}

sub Patro::Tie::HASH::FETCH { return shift->__('FETCH',1,@_) }
sub Patro::Tie::HASH::STORE { return shift->__('STORE',0,@_) }
sub Patro::Tie::HASH::DELETE { return shift->__('DELETE',1,@_) }
sub Patro::Tie::HASH::CLEAR { return shift->__('CLEAR',0) }
sub Patro::Tie::HASH::EXISTS { return shift->__('EXISTS',1,@_) }
sub Patro::Tie::HASH::FIRSTKEY { return shift->__('FIRSTKEY',1,@_) }
sub Patro::Tie::HASH::NEXTKEY { return shift->__('NEXTKEY',1,@_) }
sub Patro::Tie::HASH::SCALAR { return shift->__('SCALAR',1) }

1;
