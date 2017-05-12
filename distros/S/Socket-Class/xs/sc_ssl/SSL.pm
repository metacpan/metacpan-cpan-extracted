package Socket::Class::SSL;
# =============================================================================
# Socket::Class::SSL - SSL support to Socket::Class
# Use "perldoc Socket::Class::SSL" for documenation
# =============================================================================

# uncomment for debugging
#use strict;
#use warnings;

use Socket::Class;

our( $VERSION, @ISA );

BEGIN {
	$VERSION = '1.403';
	@ISA = qw(Socket::Class);
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );
	*say = \&writeline;
	*startssl = \&starttls;
}

1; # return

sub include_path {
	return substr( __FILE__, 0, -20 ) . '/auto/Socket/Class/SSL';
}

__END__
