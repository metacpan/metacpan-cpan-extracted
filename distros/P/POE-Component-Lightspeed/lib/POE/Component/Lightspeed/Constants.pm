# Declare our package
package POE::Component::Lightspeed::Constants;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '1.' . sprintf( "%04d", (qw($Revision: 1082 $))[1] );

# We export some stuff
require Exporter;
our @ISA = qw( Exporter );
our %EXPORT_TAGS = ( 'ALL' => [ qw(
		DEST_KERNEL DEST_SESSION DEST_STATE
		FROM_KERNEL FROM_SESSION FROM_STATE FROM_FILE FROM_LINE
		MSG_TO MSG_FROM MSG_ACTION MSG_DATA MSG_TIMESTAMP MSG_REALTO
		POST_TO POST_FROM POST_ARGS
		CALL_TO CALL_FROM CALL_ARGS CALL_RSVP
		HELLO_EDGES
		ROUTENEW_EDGES
		LINKDOWN_TO LINKDOWN_FROM
		CALLREPLY_TO CALLREPLY_FROM CALLREPLY_ARGS
		INTROSPECTION_WHAT INTROSPECTION_FROM INTROSPECTION_RSVP INTROSPECTION_ARGS
		ACTION_POST ACTION_CALL ACTION_CALLREPLY ACTION_ROUTENEW ACTION_ROUTEDEL ACTION_HELLO ACTION_INTROSPECTION
) ] );
Exporter::export_ok_tags( 'ALL' );

# Message specifiers
sub MSG_TO		() { 0 }
sub MSG_FROM		() { 1 }
sub MSG_ACTION		() { 2 }
sub MSG_DATA		() { 3 }
sub MSG_REALTO		() { 4 }
sub MSG_TIMESTAMP	() { 5 }

# The destination specifiers
sub DEST_KERNEL		() { 0 }
sub DEST_SESSION	() { 1 }
sub DEST_STATE		() { 2 }

# The from specifiers
sub FROM_KERNEL		() { 0 }
sub FROM_SESSION	() { 1 }
sub FROM_STATE		() { 2 }
sub FROM_FILE		() { 3 }
sub FROM_LINE		() { 4 }

# Action specifiers
sub POST_TO		() { 0 }
sub POST_FROM		() { 1 }
sub POST_ARGS		() { 2 }

sub CALL_TO		() { 0 }
sub CALL_FROM		() { 1 }
sub CALL_RSVP		() { 2 }
sub CALL_ARGS		() { 3 }

sub CALLREPLY_TO	() { POST_TO }
sub CALLREPLY_FROM	() { POST_FROM }
sub CALLREPLY_ARGS	() { POST_ARGS }

sub INTROSPECTION_WHAT	() { 0 }
sub INTROSPECTION_FROM	() { 1 }
sub INTROSPECTION_RSVP	() { 2 }
sub INTROSPECTION_ARGS	() { 3 }

# Action constants
sub ACTION_POST			() { 0 }
sub ACTION_CALL			() { 1 }
sub ACTION_CALLREPLY		() { 2 }
sub ACTION_ROUTENEW		() { 3 }
sub ACTION_ROUTEDEL		() { 4 }
sub ACTION_HELLO		() { 5 }
sub ACTION_INTROSPECTION	() { 6 }

# End of module
1;
__END__
