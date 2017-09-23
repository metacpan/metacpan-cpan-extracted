package Patro::N6;
use strict;
use warnings;

# Patro::N6. Proxy class for REF type references

# we must keep this namespace very clean
use Carp ();

use overload
    '${}' => \&Patro::N6x::deref,
    'nomethod' => \&Patro::LeumJelly::overload_handler,
    '@{}' => sub { Patro::LeumJelly::deref_handler(@_,'@{}') },
    '%{}' => sub { Patro::LeumJelly::deref_handler(@_,'%{}') },
    '&{}' => sub { Patro::LeumJelly::deref_handler(@_,'&{}') },
    ;

# override UNIVERSAL methods
foreach my $umethod (keys %UNIVERSAL::) {
    no strict 'refs';
    *{$umethod} = sub {
	my $proxy = shift;
	if (!CORE::ref($proxy)) {
	    $umethod = "UNIVERSAL::" . $umethod;
	    return $umethod->($proxy,@_);
	}
	my $context = defined(wantarray) ? 1 + wantarray : 0;
	no overloading;
	return Patro::LeumJelly::proxy_request( $proxy,
	    { id => $proxy->{id}, topic => 'METHOD', command => $umethod,
	      has_args => @_ > 0, args => [ @_ ], context => $context }, @_ );
    };
}

sub AUTOLOAD {
    my $method = $Patro::N6::AUTOLOAD;
    $method =~ s/.*:://;

    my $self = shift;
    my $has_args = @_ > 0;
    my $args = [ @_ ];

    my $context = defined(wantarray) ? 1 + wantarray : 0;
    no overloading;

    return Patro::LeumJelly::proxy_request( $self, 
	{ id => $self->{id},
	  topic => 'METHOD',
	  command => $method,
	  has_args => $has_args,
	  args => $args,
	  context => $context,
	  _autoload => 1 }, @_ );
}

sub Patro::N6x::deref {
    my $proxy = shift;
    no overloading;
    my $resp = Patro::LeumJelly::proxy_request(
	$proxy,
	{ id => $proxy->{id},
	  topic => 'REF',
	  command => 'deref',
	  has_args => 0, args => [],
	  context => 1 } );
    return \$resp;
}

sub DESTROY {
    my $self = shift;
    no overloading;
    return if $self->{_DESTROY}++;
    my $socket = $self->{socket};
    my $id = $self->{id};
    
    if ($socket) {

	# XXX - shouldn't disconnect on every object destruction,
	# only when all of the wrapped objects associated with a
	# client have been destroyed, or during global
	# destruction

	Patro::LeumJelly::proxy_request( $self,
	    { id => $id,
	      topic => 'META',
	      command => 'disconnect' } );
	close $socket;
    }
}

1;

