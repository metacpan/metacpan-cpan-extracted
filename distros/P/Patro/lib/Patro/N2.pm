package Patro::N2;
use strict;
use warnings;

# Patro::N2. Proxy class for SCALAR type references

# we must keep this namespace very clean
use Carp ();

use overload
    '${}' => sub { $_[0]->{scalar} },
    'nomethod' => \&Patro::LeumJelly::overload_handler,
    '@{}' => \&Patro::LeumJelly::array_deref_handler,
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
	return Patro::LeumJelly::proxy_request( $proxy,
	    { id => $proxy->{id}, topic => 'METHOD', command => $umethod,
	      has_args => @_ > 0, args => [ @_ ], context => $context }, @_ );
    };
}

sub AUTOLOAD {
    my $method = $Patro::N2::AUTOLOAD;
    $method =~ s/.*:://;

    my $self = shift;
    my $has_args = @_ > 0;
    my $args = [ @_ ];

    my $context = defined(wantarray) ? 1 + wantarray : 0;

    return Patro::LeumJelly::proxy_request( $self, 
	{ id => $self->{id},
	  topic => 'METHOD',
	  command => $method,
	  has_args => $has_args,
	  args => $args,
	  context => $context,
	  _autoload => 1 }, @_ );
}

sub DESTROY {
    my $self = shift;
    return if $self->{_DESTROY}++;
    my $socket = $self->{socket};
    if ($socket) {

	# XXX - shouldn't disconnect on every object destruction,
	# only when all of the wrapped objects associated with a
	# client have been destroyed, or during global
	# destruction

	Patro::LeumJelly::proxy_request( $self,
	    { id => $self->{id},
	      topic => 'META',
	      command => 'disconnect' } );
	close $socket;
    }
}

# tie class for proxy object. Operations on the proxy object
# are forwarded to the remote server

sub Patro::Tie::SCALAR::TIESCALAR {
    my ($pkg,$proxy) = @_;
    return bless { obj => $proxy, id => $proxy->{id} }, $pkg;
}

sub Patro::Tie::SCALAR::__ {
    my $tied = shift;
    my $name = shift;
    my $context = shift;
    if (!defined($context)) {
	$context = defined(wantarray) ? 1 + wantarray : 0;
    }
    return Patro::LeumJelly::proxy_request( $tied->{obj},
	{ topic => 'SCALAR',
	  command => $name,
	  context => $context,
	  has_args => @_ > 0,
	  args => [ @_ ],
	  id => $tied->{id} }, @_ );
}

sub Patro::Tie::SCALAR::FETCH { return shift->__('FETCH',1) }
sub Patro::Tie::SCALAR::STORE { return shift->__('STORE',0,@_) }

1;
