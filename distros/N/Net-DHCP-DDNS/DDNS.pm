package Net::DHCP::DDNS;
use warnings;
use strict;

our $VERSION = '0.1';

use Carp;
use Net::DHCP::DDNS::API;
use Net::DHCP::DDNS::Lookup;

my %OBJ;


sub new {
	my $class = shift;

	$class = __PACKAGE__ unless $class;
	$class = ref($class) if ref($class);

	unless ( $class->isa( __PACKAGE__ ) ) {
		croak __PACKAGE__ . "::new($class) asinine!";
	}

	my $obj = bless {}, 'Net::DHCP::DDNS::API';
	my $oid;

	do {
		my $t = '';

		for ( my $i = 0; $i < 10; $i++ ) {
			$t .= int( rand( 10 ) );
		}

		$oid = $t;

	} until not defined $OBJ{$oid};

	$OBJ{$oid} = $obj;

	return bless \( my $this = $oid ), $class;
}


sub DESTROY {
	delete $OBJ{${(shift)}};
}


our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;

	croak "$AUTOLOAD: method not found"
		unless ref( $self );

	my $func = $AUTOLOAD;
	my @func = split /::/, $func;
	   $func = pop @func;

	croak "$AUTOLOAD: access to private method denied"
		if $func =~ /^_/;

	{
		no strict 'refs';
		*{$AUTOLOAD} = sub {
			$OBJ{${(shift)}}->$func( @_ );
		};
	}

	return $OBJ{$$self}->$func( @_ );
}


1;
