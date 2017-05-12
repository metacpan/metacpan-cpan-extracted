package Net::AIM::TOC;

$VERSION = '0.97';

use strict;

use Net::AIM::TOC::Config;

sub new {
	my $class = shift;

	my $self = {
		_conn => undef,
	};
	bless $self, $class;

	return( $self );
};

sub connect {
	my $self = shift;
	my $args = shift;

	my $conn = Net::AIM::TOC::Connection->new( $args );

	$self->{_conn} = $conn;

	return( 1 );
};

sub sign_on {
	my $self = shift;
	my $screenname = shift;
	my $password = shift;

	if( !defined($screenname) || !defined($password) ) {
		throw Net::AIM::TOC::Error( -text => 'Username/password not defined' );
	};

	my $ret = $self->{_conn}->send_signon( $screenname, $password );

	return( $ret );
};


sub send_im_to_aol {
	my $self = shift;
	my $user = shift;
	my $msg = shift;

	my $ret = $self->{_conn}->sendIMToAOL( $user, $msg );

	return( $ret );
};


sub send_to_aol {
	my $self = shift;
	my $msg = shift;

	my $ret = $self->{_conn}->sendToAOL( $msg );

	return( $ret );
};


sub recv_from_aol {
	my $self = shift;

	my( $msgObj ) = $self->{_conn}->recvFromAOL;

	return( $msgObj );
};


sub disconnect {
	my $self = shift;

	$self->{_conn}->disconnect;

	return( 1 );
};


=pod

=head1 NAME

Net::AIM::TOC - Perl implementation of the AIM TOC protocol
    
=head1 DESCRIPTION

The C<Net::AIM::TOC> module implements in AIM TOC protocol in such a way which make it simple for using when writing bots or AIM clients in Perl.

All of the code regarding the connection is abstracted in order to simplify the AIM connection down to merely sending and receiving instant messages and toc commands.

=head1 SYNOPSIS

  use Error qw( :try );
  use Net::AIM::TOC;

  try {
    my $aim = Net::AIM::TOC->new;
    $aim->connect;
    $aim->sign_on( $screenname, $password );

    my $msgObj = $aim->recv_from_aol;
    print $msgObj->getMsg, "\n";
    $aim->send_im_to_aol( $buddy, $msg );

    $aim->disconnect;
    exit( 0 );

  }
  catch Net::AIM::TOC::Error with {
    my $err = shift;
    print $err->stringify, "\n";

  };


=head1 CLASS INTERFACE

=head2 CONSTRUCTORS

A C<Net::AIM::TOC> object is created by calling the new constructor without arguments. A reference to the newly created object is returned, however, no connection to AIM has yet been made. One first is required to called C<connect> and C<sign_on> before attempting to send/receive instant messages.

=over 4

=item new ()

Returns C<Net::AIM::TOC> object but does not create a connection or sign on to the AIM service.

=back

=head2 OBJECT METHODS

=over 4

=item connect ( ARGS )

The connect method can be called without arguments to connect to the AIM service using the default AIM servers.

Alternatively, a hash containing any of the following keys can be passed in to connect to another service using the TOC protocol:

  -tocServer
  -tocPort
  -authServer
  -authPort

=item sign_on ( ARGS )

C<sign_on> is called to sign on to the AIM service. The arguments to be passed in are the screen name and password to be used to sign on to the service. 

=item send_im_to_aol ( ARGS )

Sends an instant message. The first argument should be the name of the receipient buddy and the second argument is the message which you are sending.

=item send_to_aol ( ARGS )

Sends whatever string is passed in on to the AIM service. Useful for sending toc commands.

=item recv_from_aol ()

Receives any data sent from the AIM service. This includes all TOC protocol messages (including instant messages), however, PAUSE And SIGN_ON messages are handled internally.

This method returns a C<Net::AIM::TOC::Messages> object. See the documentation for this object is to be used.

=item disconnect ()

Disconnects from the AIM service.

=back

=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 SEE ALSO

C<Net::AIM::TOC::Messages>

=head1 AUTHOR

Alistair Francis, http://search.cpan.org/~friffin/

=cut


# Net::AIM::TOC::Connection package.
# Nothing to see here, please move along

package Net::AIM::TOC::Connection;

use strict;

use Net::AIM::TOC::Message;

use IO::Socket::INET;

sub new {
	my $class = shift;
	my $args = shift;

	my $self = {
		_sock	=> undef,
		_screenName	=> undef,
		_tocServer	=> $args->{tocServer} || Net::AIM::TOC::Config::TOC_SERVER,
		_tocPort	=> $args->{tocPort} || Net::AIM::TOC::Config::TOC_PORT,
		_authServer	=> $args->{authServer} || Net::AIM::TOC::Config::AUTH_SERVER,
		_authPort	=> $args->{authPort} || Net::AIM::TOC::Config::AUTH_PORT,
		_outseq	=> int(rand(100000)),
	};

	my $sock = IO::Socket::INET->new(
		PeerAddr	=> $self->{_tocServer},
		PeerPort	=> $self->{_tocPort},
		Type		=> SOCK_STREAM,
		Proto		=> 'tcp'
	);

	if( !defined($sock) ) {
		my $err_msg = 'Unable to connect to '. $self->{_tocServer} .' on port '. $self->{_tocPort};
		throw Net::AIM::TOC::Error( -text => $err_msg );
	};

	$self->{_sock} = $sock;
	bless $self, $class;

	return( $self );
};


sub send_signon {
	my $self = shift;
	my $screen_name = shift;
	my $password = shift;

	$self->{_screenName} = $screen_name;

	Net::AIM::TOC::Utils::printDebug( "send_signon: $screen_name" );

	my $data_out = "FLAPON\r\n\r\n";
	$self->{_sock}->send( $data_out );

	my( $msgObj ) = $self->recvFromAOL;
	Net::AIM::TOC::Utils::printDebug( $msgObj->getRawData );

	my $signon_data = pack "Nnna".length($screen_name), 1, 1, length($screen_name) , $screen_name;

	my $msg = pack "aCnn", '*', 1, $self->{_outseq}, length($signon_data);
	$msg .= $signon_data;

	my $ret = $self->{_sock}->send( $msg, 0 );

	if( !defined($ret) ) {
		throw Net::AIM::TOC::Error( -text => "syswrite: $!" );
	};

	my $login_string = $self->_getLoginString( $screen_name, $password );

	$ret = $self->sendToAOL( $login_string );

	# receive SIGNON data from AOL
	$msgObj = $self->recvFromAOL;
	Net::AIM::TOC::Utils::printDebug( $msgObj->getRawData );

	# Sending of sign on data is performed by 'recvFromAOL' to ensure
	# correct handling of PAUSE messages

	return( 1 );
};


sub _sendSignOnData {
	my $self = shift;

	# These lines are required in order to sign on
	my $ret = $self->sendToAOL( "toc_add_buddy $self->{_screenName}" );
	$ret = $self->sendToAOL( 'toc_set_config {m 1}' );

	# We're done with the signon process
	$ret = $self->sendToAOL( 'toc_init_done' );

	# remove the buddy we were required to add earlier
	$ret = $self->sendToAOL( "toc_remove_buddy $self->{_screenName}" );

	return;
};

sub _getLoginString {
	my $self = shift;
	my $screen_name = shift;
	my $password = shift;

	my $login_string = 'toc_signon '. $self->{_authServer} .' '. $self->{_authPort} .' '. $screen_name .' '. Net::AIM::TOC::Utils::encodePass( $password ) .' english '. Net::AIM::TOC::Utils::encode( Net::AIM::TOC::Config::AGENT );

	return( $login_string );
};


sub recvFromAOL {
	my $self = shift;

	my $buffer;

	if( !defined($self->{_sock}) ) {
		throw Net::AIM::TOC::Error( -text => 'We are not connected' );
	};

	my $ret = $self->{_sock}->recv( $buffer, 6 );
	if( !defined($ret) ) {
		throw Net::AIM::TOC::Error( -text => "sysread: $!" );
	};
	Net::AIM::TOC::Utils::printDebug( "RAW IN (header): '$buffer'" );

	my ($marker, $type, $in_seq, $len) = unpack "aCnn", $buffer;
	Net::AIM::TOC::Utils::printDebug( "IN (header): '$marker', '$type', '$in_seq', '$len'" );

	$ret = $self->{_sock}->recv( $buffer, $len );
	if( !defined($ret) ) {
		throw Net::AIM::TOC::Error( -text => "sysread: $!" );
	};
	Net::AIM::TOC::Utils::printDebug( "RAW IN (data): '$buffer'" );

	my $data = unpack( 'a*', $buffer );
	Net::AIM::TOC::Utils::printDebug( "IN (data): '$data'" );

	my $msgObj = Net::AIM::TOC::Message->new( $type, $data );

	if( $msgObj->getType eq 'SIGN_ON' ) {
		$self->_sendSignOnData;
	};

	return( $msgObj );
};


sub sendToAOL {
	my $self = shift;
	my $msg = shift;

	if( !defined($self->{_sock}) ) {
		throw Net::AIM::TOC::Error( -text => 'We are not connected' );
	};

	$msg .= "\0";

	Net::AIM::TOC::Utils::printDebug( "RAW OUT: $msg" );
	my $data = pack "aCnna*", '*', 2, ++$self->{_outseq}, length($msg), $msg;
	Net::AIM::TOC::Utils::printDebug( "OUT: $data" );

	my $ret = $self->{_sock}->send( $data, 0 );

	if( !defined($ret) ) {
		throw Net::AIM::TOC::Error( -text => "syswrite: $!" );
	};

	return( $ret );
};


sub sendIMToAOL {
	my $self = shift;
	my $user = shift;
	my $msg = shift;

	if( !defined($user) || !defined($msg) ) {
		Net::AIM::TOC::Utils::printDebug( "User or msg not defined\n" );
		return;
	};

	$user = Net::AIM::TOC::Utils::normalize( $user );
	$msg = Net::AIM::TOC::Utils::encode( $msg );

	$msg = 'toc_send_im '. $user .' '. $msg;

	my $ret = $self->sendToAOL( $msg );

	return( $ret );
};


sub disconnect {
	my $self = shift;

	$self->{_sock}->close;

	return;
};


# Net::AIM::TOC::Error* packages.
# Nothing to see here, please move along

package Net::AIM::TOC::Error;

use strict;

@Net::AIM::TOC::Error::ISA = qw( Error );


package Net::AIM::TOC::Error::Message;

use strict;

@Net::AIM::TOC::Error::Message::ISA = qw( Net::AIM::TOC::Error );



# Net::AIM::TOC::Utils package.
# Nothing to see here, please move along

package Net::AIM::TOC::Utils;

use strict;

sub printDebug {
	my $msg = shift;

	if( Net::AIM::TOC::Config::DEBUG ) {
		print STDERR $msg, "\n";
	};

	return;
};

sub encodePass {
	my $password = shift;

	my @table = unpack "c*" , 'Tic/Toc';
	my @pass = unpack "c*", $password;

	my $encpass = '0x';
	foreach my $c (0 .. $#pass) {
		$encpass.= sprintf "%02x", $pass[$c] ^ $table[ ( $c % 7) ];
	};

	return( $encpass );
};

sub encode {
	my $str = shift;

	$str =~ s/([\\\}\{\(\)\[\]\$\"])/\\$1/g;
	return( "\"$str\"" );
};

sub normalize {
	my $data = shift;
    
	$data =~ s/[^A-Za-z0-9]//g;
	$data =~ tr/A-Z/a-z/;

	return( $data );
};


sub removeHtmlTags {
	my $string = shift;
	my $replacement = shift || '';

	$string =~ s/<.*?>/$replacement/g;

	return( $string );
};


sub getCurrentTime {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

	if( $sec < 10 ) { $sec = '0'.$sec };
	if( $min < 10 ) { $min = '0'.$min };

	return( "$hour:$min:$sec" );
};

1;

