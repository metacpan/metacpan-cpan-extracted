################################################################################
#
# STUN::RFC_5389
#
# Perl implementation of RFC 5389, Session Traversal Utilities for NAT (STUN)
#
#
# This module is Copyright (C) 2010, Detlef Pilzecker, deti@cpan.org
# All Rights Reserved.
# This module is free software. It may be used, redistributed and/or modified
# under the same terms as Perl itself.
#
################################################################################



package STUN::RFC_5389;

use strict;
use Socket;

$STUN::RFC_5389::VERSION = '0.1';




################################################################################
# STUN Attribute Registry
################################################################################
%STUN::RFC_5389::attribute_registry = (
# Comprehension-required range (0x0000-0x7FFF):
	# '0000' => (Reserved)
	'0001' => 'MAPPED-ADDRESS',
	# '0002' => (Reserved; was RESPONSE-ADDRESS)
	# '0003' => (Reserved; was CHANGE-ADDRESS)
	# '0004' => (Reserved; was SOURCE-ADDRESS)
	# '0005' => (Reserved; was CHANGED-ADDRESS)
	'0006' => 'USERNAME',
	# '0007' => (Reserved; was PASSWORD)
	'0008' => 'MESSAGE-INTEGRITY',
	'0009' => 'ERROR-CODE',
	'000A' => 'UNKNOWN-ATTRIBUTES',
	# '000B' => (Reserved; was REFLECTED-FROM)
	'0014' => 'REALM',
	'0015' => 'NONCE',
	'0020' => 'XOR-MAPPED-ADDRESS',

# Comprehension-optional range (0x8000-0xFFFF)
	'8022' => 'SOFTWARE',
	'8023' => 'ALTERNATE-SERVER',
	'8028' => 'FINGERPRINT',
);




################################################################################
# STUN Attribute subroutines
# Args:
#   attribute value string (client) | hashref with values for the sub (server)
# Return:
#   hashref with values of the attribute (c)| attribute string in hex format (s)
################################################################################
my %attribute_sub = (
	'MAPPED-ADDRESS' => sub {
		my $attr_value = shift;

		# build attribute
		if ( ref $attr_value ) {
			my $value = '00';
			# IPv4
			if ( $$attr_value{host} =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
				# family 0x01
				$value .= '01';
				# X-port
				$value .= sprintf( "%04x", $$attr_value{port} );
				# X-address
				$value .= sprintf( "%08x", unpack( "N", inet_aton( $$attr_value{host} ) ) );
			}
			# IPv6
			else {
				$STUN::RFC_5389::error .= "IPv6 is not supported at the moment!\n";
				return '';
				# family 0x02
				#$value .= '02';
				# X-Port
				#$value .= sprintf( "%04x", $$attr_value{port} );
				# X-Address
				#$value .= sprintf( "%032x", $$attr_value{host} ^ 0x2112a442 .  );
			}

			return join_attribute( '0001', $value );
		}


		# parse attribute value
		my %values;

		# 0x0001:IPv4
		if ( $attr_value =~ s/^00(01)(....)// ) {
			$values{family} = $1;
			# X-Port
			$values{port} = hex( $2 );
			# X-Address
			$values{address} = inet_ntoa( pack( "N", hex( $attr_value ) ) );
		}
		# 0x0002:IPv6
		elsif ( $attr_value =~ s/^00(02)(....)// ) {
			$STUN::RFC_5389::error .= "IPv6 is not supported at the moment!\n";
			#$values{family} = $1;
			# X-Port
			#$values{port} = hex( $2 );
			# X-Address
			#$values{address} = inet_ntoa( pack( "N", hex( $attr_value ) ) );
		}

		return \%values;
	},

	'USERNAME' => sub {
		my $attr_value = shift;
# XXXX not coded jet, returns just an empty string/hashref for now
		# build attribute
		if ( ref $attr_value ) {
			my $value = '';

			return join_attribute( '0006', $value );
		}


		# parse attribute value
		my %values;

		return \%values;
	},

	'MESSAGE-INTEGRITY' => sub {
		my $attr_value = shift;
# XXXX not coded jet, returns just an empty string/hashref for now
		# build attribute
		if ( ref $attr_value ) {
			my $value = '';

			return join_attribute( '0008', $value );
		}


		# parse attribute value
		my %values;

		return \%values;
	},

	'ERROR-CODE' => sub {
		my $attr_value = shift;
# XXXX not coded jet, returns just an empty string/hashref for now
		# build attribute
		if ( ref $attr_value ) {
			my $value = '';

			return join_attribute( '0009', $value );
		}


		# parse attribute value
		my %values;

		return \%values;
	},

	'UNKNOWN-ATTRIBUTES' => sub {
		my $attr_value = shift;
# XXXX not coded jet, returns just an empty string/hashref for now
		# build attribute
		if ( ref $attr_value ) {
			my $value = '';

			return join_attribute( '000a', $value );
		}


		# parse attribute value
		my %values;

		return \%values;
	},

	'REALM' => sub {
		my $attr_value = shift;
# XXXX not coded jet, returns just an empty string/hashref for now
		# build attribute
		if ( ref $attr_value ) {
			my $value = '';

			return join_attribute( '0014', $value );
		}


		# parse attribute value
		my %values;

		return \%values;
	},

	'NONCE' => sub {
		my $attr_value = shift;
# XXXX not coded jet, returns just an empty string/hashref for now
		# build attribute
		if ( ref $attr_value ) {
			my $value = '';

			return join_attribute( '0015', $value );
		}


		# parse attribute value
		my %values;

		return \%values;
	},

	'XOR-MAPPED-ADDRESS' => sub {
		my $attr_value = shift;

		# build attribute
		if ( ref $attr_value ) {
			my $value = '00';
			# IPv4
			if ( $$attr_value{host} =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
				# family 0x01
				$value .= '01';
				# X-port
				$value .= sprintf( "%04x", $$attr_value{port} ^ 0x2112 );
				# X-address
				$value .= sprintf( "%08x", unpack( "N", inet_aton( $$attr_value{host} ) ) ^ 0x2112a442 );
			}
			# IPv6
			else {
				$STUN::RFC_5389::error .= "IPv6 is not supported at the moment!\n";
				return '';
				# family 0x02
				#$value .= '02';
				# X-Port
				#$value .= sprintf( "%04x", $$attr_value{port} ^ 0x2112 );
				# X-Address
				#$value .= sprintf( "%032x", $$attr_value{host} ^ 0x2112a442 .  );
			}

			return join_attribute( '0020', $value );
		}


		# parse attribute value
		my %values;

		# 0x0001:IPv4
		if ( $attr_value =~ s/^00(01)(....)// ) {
			$values{family} = $1;
			# X-Port
			$values{port} = hex( $2 ) ^ 0x2112;
			# X-Address
			$values{address} = inet_ntoa( pack( "N", hex( $attr_value ) ^ 0x2112a442 ) );
		}
		# 0x0002:IPv6
		elsif ( $attr_value =~ s/^00(02)(....)// ) {
			$STUN::RFC_5389::error .= "IPv6 is not supported at the moment!\n";
			#$values{family} = $1;
			# X-Port
			#$values{port} = hex( $2 ) ^ 0x2112;
			# X-Address
			#$values{address} = inet_ntoa( pack( "N", hex( $attr_value ) ^ 0x2112a442 ) );
		}

		return \%values;
	},

	'SOFTWARE' => sub {
		my $attr_value = shift;

		# build attribute
		if ( ref $attr_value ) {
			# It MUST be a UTF-8 [RFC3629] encoded sequence of less than 128 characters
			my $value = $$attr_value{software} ||
				"Perl - STUN::RFC_5389 version $STUN::RFC_5389::VERSION at CPAN, by Detlef Pilzecker.";

			return join_attribute( '8022', unpack( "H*", sprintf( "%.128s", $value ) ) );
		}


		# parse attribute value
		my %values;

		$values{software} = pack( "H*", $attr_value );

		return \%values;
	},

	'ALTERNATE-SERVER' => sub {
		my $attr_value = shift;
# XXXX not coded jet, returns just an empty string/hashref for now
		# build attribute
		if ( ref $attr_value ) {
			my $value = '';

			return join_attribute( '8023', $value );
		}


		# parse attribute value
		my %values;

		return \%values;
	},

	'FINGERPRINT' => sub {
		my $attr_value = shift;
# XXXX not coded jet, returns just an empty string/hashref for now
		# build attribute
		if ( ref $attr_value ) {
			my $value = '';

			return join_attribute( '8028', $value );
		}


		# parse attribute value
		my %values;

		return \%values;
	},
);




################################################################################
# join_attribute( $attr_type, $attr_value )
# join type, length and value of the attribute and will fix the length to
# become a 32-bit boundary length
# Args:
#   $attr_type: attribute type in hex-format
#   $attr_value: attribute value in hex-format
# Return: attribute string in hex format
################################################################################
sub join_attribute {
	my ( $attr_type, $attr_value ) = @_;

	my $a_len = length( $attr_value );
	if ( $a_len % 2 != 0 ) {
		$attr_value = '0' . $attr_value;
		$a_len++;
	}

	return $attr_type . sprintf( "%04x", $a_len / 2 ) . $attr_value . 0 x ( 8 - ( $a_len % 8 || 8 ) );
}




################################################################################
# Client( $message_req_ind )
# do the RFC 5389 for the client
# Args:
#   $message_req_ind: can be the received message from the STUN server or
#      a hash_ref with attributes 'request' => 1 or 'indication' => 1
# Returns:
#   hash reference with the STUN-server answer or
#   STUN-client message to send if $message_req_ind was 'request' or
#     'indication' or
#   '' on error (error message in $STUN::RFC_5389::error)
################################################################################
sub Client {
	$STUN::RFC_5389::error = '';

	my $message = shift;
	$message = $message ne 'STUN::RFC_5389' ? $message : shift; # strip the class

	# message to send
	if ( ref $message ) {
		my $message_type;
		if ( $message->{request} ) {
			$message_type = '0001';
		}
		elsif ( $message->{indication} ) {
			$message_type = '0011';
		}
		else {
			$STUN::RFC_5389::error .= "No hash-key with value 'request' or 'indication' set to true in hashref!\n";
			return '';
		}

		# No attributes jet coded for the client to send
		my $message_length = 0;

		# In RFC 5389 the magic cookie field MUST contain this fixed value
		my $magic_cookie = '2112a442';

		# The transaction ID is a 96-bit identifier, used to uniquely identify
		# STUN transactions
		my $transaction_id;
		for ( my $i = 0; $i < 6; $i++ ) { $transaction_id .= sprintf("%04x", int( rand( 65536 ) ) ) }

		return pack( "H4nH8H24", $message_type, $message_length, $magic_cookie, $transaction_id );
	}


	# received message
	my %received;
	@received{ qw( message_type message_length magic_cookie transaction_id attributes ) } = unpack( "H4nH8H24H*", $message );

	return '' unless true_stun_message( @received{ qw( message_type message_length magic_cookie transaction_id attributes ) }, 0 );

	$received{attributes} = parse_attributes( $received{attributes} );

	return \%received;
}




################################################################################
# parse_attributes( $attributes )
# parse all attributes
# Args:
#   $attributes: stun message attributes in hex format
# Return: hashref with all attributes and its values in a hashref
################################################################################
sub parse_attributes {
	my $attributes = shift;

	my %attr;
	while ( $attributes =~ s/^(....)(....)// ) {
		my ( $type, $length ) = ( $1, $2 );

		$length = hex( $length ) * 2;
		my $fixed_length = 8 - ( $length % 8 || 8 );
		last if ( $length + $fixed_length ) > length( $attributes );

		my $attr_value = substr( $attributes, 0, $length, '' );
		substr( $attributes, 0, $fixed_length, '' ) if $fixed_length;

		if ( length( $attr_value ) == $length && ( my $type_name = $STUN::RFC_5389::attribute_registry{ $type } ) ) {
			$attr{ $type_name } = $attr{ $type } = $attribute_sub{ $type_name }->( $attr_value );
		}
	}

	return \%attr;
}




################################################################################
# Server( $message, $port, $host )
# do the RFC 5389 for the server
# Args:
#   $message: binary message string received from the client
#   $port: port from which the message came
#   $host: host IP from which the message came
# Returns:
#   STUN-server message to send back or
#   '' on error (error message in $STUN::RFC_5389::error) or
#   <undef> if it was an indication
################################################################################
sub Server {
	$STUN::RFC_5389::error = '';

	my $message = shift;
	$message = $message ne 'STUN::RFC_5389' ? $message : shift; # strip the class

	my ( $message_type, $message_length, $magic_cookie, $transaction_id, $attributes ) = unpack( "H4nH8H24H*", $message );


	return '' unless true_stun_message( $message_type, $message_length, $magic_cookie, $transaction_id, $attributes, 1 );

	# No response is generated for an indication
	return if $message_type eq '0011';


	# Success response
	$message_type = '0101';

	$attributes = '';

	# RFC 5389
	if ( $magic_cookie eq '2112a442' ) {
		# XOR-MAPPED-ADDRESS
		$attributes .= $attribute_sub{'XOR-MAPPED-ADDRESS'}->( { port => shift, host => shift } );

		# SOFTWARE
		$attributes .= $attribute_sub{'SOFTWARE'}->( {} );
	}
	# Probably RFC 3489
	else {
		# MAPPED-ADDRESS
		$attributes .= $attribute_sub{'MAPPED-ADDRESS'}->( { port => shift, host => shift } );
	}

	return pack( "H4nH8H24H*", $message_type, length( $attributes ) / 2, $magic_cookie, $transaction_id, $attributes );
}




################################################################################
# true_stun_message( $message_type, $message_length, $magic_cookie, $transaction_id, $attributes, $i_am_server )
# check the message for errors
# Args:
#   ...: unpacked stun message in an array with 5 values
#   $i_am_server: set to true if check is done for server
# Return: <undef> (error) or 1 (success)
################################################################################
sub true_stun_message {
	my ( $message_type, $message_length, $magic_cookie, $transaction_id, $attributes, $i_am_server ) = @_;

	if ( $message_type !~ /^[0-3]/ ) {
		$STUN::RFC_5389::error .= "The most significant 2 bits of every STUN message MUST be zeroes. Was 0x$message_type\n";
		return;
	}
	if ( $message_length % 4 != 0 ) {
		$STUN::RFC_5389::error .= "Message length was not correct: $message_length. All STUN attributes (and therefore the message length) MUST be padded to a multiple of 4 bytes!\n";
		return;
	}
	if ( ( $message_length && ! $attributes ) ||
	     ( ! $message_length && $attributes ) ||
		 ( $message_length != length( $attributes ) / 2 ) ) {
		$STUN::RFC_5389::error .= "Message length ($message_length) was not set correct. Must be (attributes length): " . ( $attributes ? length( $attributes ) / 2 : 0 ) . "\n";
		return;
	}
	if ( $magic_cookie ne '2112a442' ) {
		$STUN::RFC_5389::error .= "The magic cookie field MUST contain the fixed value 0x2112a442 to be RFC 5389 conform. I assume RFC 3489 here and let it pass. The value was: 0x$magic_cookie\n";
		# Do not return; here because it's not explicitly an error
	}
	if ( $message_type ne '0001' &&  # Binding request
	     $message_type ne '0011' &&  # Binding indication
	     $message_type ne '0101' &&  # Binding success response
	     $message_type ne '0111' ) { # Binding error response
		$STUN::RFC_5389::error .= "Message type (class and method) not recognised! Was: 0b$message_type\n";
		return;
	}
	if ( $i_am_server &&
	     $message_type ne '0001' && $message_type ne '0011' ) {
		$STUN::RFC_5389::error .= "Message type (class and method) are not for the server! Was: 0b$message_type\n";
		return;
	}
	elsif ( ! $i_am_server &&
	     $message_type ne '0101' && $message_type ne '0111' ) {
		$STUN::RFC_5389::error .= "Message type (class and method) are not for the client! Was: 0b$message_type\n";
		return;
	}

	return 1;
}

1;