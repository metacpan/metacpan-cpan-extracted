package Net::AIM::TOC::Message;

use strict;

use Net::AIM::TOC::Config;

sub new {
	my $class = shift;
	my $toc_type = shift;
	my $data = shift;

	my $self;

	if( $data =~ /^(ERROR):(\d*)(:(.*))?$/ ) {
		$self = Net::AIM::TOC::Message::ERROR->new( $1, $2, $4, $data );
	}
	elsif( $data =~ /^(IM_IN):(\w*):([T|F]):(.*)$/ ) {
		$self = Net::AIM::TOC::Message::IM_IN->new( $1, $2, $3, $4, $data );
	}
	elsif( $data =~ /^(UPDATE_BUDDY):(\w*):([T|F]):(\d):(\d+):(\d+):(.*)?$/ ) {
		$self = Net::AIM::TOC::Message::UPDATE_BUDDY->new( $1, $2, $3, $4, $5, $6, $7, $data );
	}
	elsif( $data =~ /^(NICK):(.*)$/ ) {
		$self = Net::AIM::TOC::Message::GENERIC->new( $1, $2 );
	}
	elsif( $data =~ /^(SIGN_ON):(.*)$/ ) {
		$self = Net::AIM::TOC::Message::GENERIC->new( $1, $2 );
	}
	elsif( $data =~ /^(PAUSE):(.*)$/ ) {
		$self = Net::AIM::TOC::Message::GENERIC->new( $1, $2 );
	}
	elsif( $data =~ // ) {
		$self = Net::AIM::TOC::Message::BLANK_MESSAGE->new( $data );
	}
	else {
		throw Net::AIM::TOC::Error( -text => "Invalid message format: $data" );
	};

	$self->{_tocType} = $toc_type;

	return( $self );
};

sub getTocType { return( $_[0]->{_tocType} ) };
sub getType { return( $_[0]->{_type} ) };
sub getMsg { return( $_[0]->{_text} ) };
sub getRawData { return( $_[0]->{_rawData} ) };



package Net::AIM::TOC::Message::IM_IN;

use strict;

@Net::AIM::TOC::Message::IM_IN::ISA = qw( Net::AIM::TOC::Message );

sub new {
	my $class = shift;
	my $type = shift;
	my $sender = shift;
	my $autoresponse = shift;
	my $msg = shift;
	my $data = shift;

	my $self = {
		_type	=> $type,
		_sender	=> $sender,
		_autoResponse	=> $autoresponse,
		_text	=> $msg,
		_rawData	=> $data
	};
	bless $self, $class;

	$self->_removeHtmlTags;

	return( $self );
};

sub _removeHtmlTags {
	my $self = shift;

	if( Net::AIM::TOC::Config::REMOVE_HTML_TAGS ) {
		$self->{_text} = Net::AIM::TOC::Utils::removeHtmlTags( $self->{_text} );
	};

	return;
}


sub isAutoResponse {
	my $self = shift;

	if( $self->{_autoResponse} eq 'T' ) {
		return( 1 );
	};
	
	return;
};

sub getSender { return( $_[0]->{_sender} ) };



package Net::AIM::TOC::Message::ERROR;

use strict;

@Net::AIM::TOC::Message::ERROR::ISA = qw( Net::AIM::TOC::Message );

sub new {
	my $class = shift;
	my $type = shift;
	my $value = shift;
	my $text = shift || '';
	my $data = shift || '';

	my $self = {
		_type	=> $type,
		_value	=> $value,
		_rawData	=> $data,
	};
	bless $self, $class;

	$self->{_text} = $self->_getErrorText( $text );

	unless( $self->isRecoverable ) {
		throw Net::AIM::TOC::Error( -text => $self->{_text} );
	};

	return( $self );
};

sub _getErrorText {
	my $self = shift;
	my $text = shift;

	my $raw_err = Net::AIM::TOC::Config::EVENT_ERROR_STRING( $self->{_value} );
	my $err_text = sprintf( $raw_err, $text );

	return( $err_text );
};

sub isRecoverable {
	my $self = shift;
	if( $self->{_value} =~ /^98[0-9]/ ) {
		return( 0 );
	}
	return( 1 );
};



package Net::AIM::TOC::Message::UPDATE_BUDDY;

use strict;

@Net::AIM::TOC::Message::UPDATE_BUDDY::ISA = qw( Net::AIM::TOC::Message );

sub new {
	my $class = shift;
	my $type = shift;
	my $buddy = shift;
	my $online = shift;
	my $evil = shift;
	my $signon_time = shift;
	my $idle_time = shift;
	my $user_class = shift;
	my $data = shift;

	my $self = {
		_type		=> $type,
		_buddy		=> $buddy,
		_onlineStatus	=> $online,
		_evilAmount	=> $evil,
		_signonTime	=> $signon_time,
		_idleTime	=> $idle_time,
		_userClass	=> $user_class,
		_rawData	=> $data,
	};
	bless $self, $class;

	return( $self );
};

sub getBuddy { return( $_[0]->{_buddy} ) };
sub getOnlineStatus { return( $_[0]->{_onlineStatus} ) };
sub getEvilAmount { return( $_[0]->{_evilAmount} ) };
sub getSignonTime { return( $_[0]->{_signonTime} ) };
sub getIdleTime { return( $_[0]->{_idleTime} ) };
sub getUserClass { return( $_[0]->{_userClass} ) };



package Net::AIM::TOC::Message::GENERIC;

use strict;

@Net::AIM::TOC::Message::GENERIC::ISA = qw( Net::AIM::TOC::Message );

sub new {
	my $class = shift;
	my $type = shift;
	my $text = shift;

	my $self = {
		_type	=> $type,
		_text	=> $text,
		_rawData	=> $text,
	};
	bless $self, $class;

	return( $self );
};



# This sometimes comes through (esp. at signon)
package Net::AIM::TOC::Message::BLANK_MESSAGE;

use strict;

@Net::AIM::TOC::Message::BLANK_MESSAGE::ISA = qw( Net::AIM::TOC::Message );

sub new {
	my $class = shift;
	my $text = shift;

	my $self = {
		_type	=> 'BLANK_MESSAGE',
		_text	=> $text,
		_rawData	=> $text,
	};
	bless $self, $class;

	return( $self );
};



1;


=pod

=head1 NAME

Net::AIM::TOC::Message - AIM Message object
    
=head1 DESCRIPTION

The C<Net::AIM::TOC::Message> object is returned by the C<Net::AIM::TOC::recv_from_aol> method. It provides a simple means of interrogating a received message to find out if it is an incoming instant message, error message, etc.

It should never be necessary to create this object.

=head1 SYNOPSIS

  use Error qw( :try );
  use Net::AIM::TOC;

  try {
    my $aim = Net::AIM::TOC->new;
    $aim->sign_on( $screenname, $password );

    ...

    my $msgObj = $aim->recv_from_aol;
    if( $msgObj->getType eq 'IM_IN' ) {
      print $msgObj->getMsg, "\n";

    ...
  

=head1 CLASS INTERFACE

=head2 OBJECT METHODS

=over 4

=item getType ()

Returns the type of the message. The type can be one of the following (see the Toc PROTOCOL document for a full explanation):

    -IM_IN
    -ERROR
    -UPDATE_BUDDY
    -NICK

=item getMsg ()

Returns the content of the message (only available to IM_IN and ERROR messages).

=item getRawData ()

Returns the raw message as it was received.

=item getTocType ()

Returns the type of TOC of the message. The type returned is an integer which can be one of the following:

    -1 (SIGNON) 
    -2 (DATA)
    -5 (KEEPALIVE)

=item getSender ()

Returns sender of the instant message (only available to IM_IN messages).

=item isAutoResponse ()

Returns true if the message was an auto-generated response (only available to IM_IN messages).

=item getBuddy ()

Returns the buddy name (only available to UPDATE_BUDDY messages).

=item getOnlineStatus ()

Returns the online status of the buddy (only available to UPDATE_BUDDY messages).

=item getEvilAmount ()

Returns the evil amount of the buddy (only available to UPDATE_BUDDY messages).

=item getSignonTime ()

Returns the time (in epoch) at which the buddy signed on (only available to UPDATE_BUDDY messages).

=item getIdleTime ()

Returns the idle time (in minutes) of the buddy (only available to UPDATE_BUDDY messages).

=item getUserClass ()

Returns the user class of the buddy (only available to UPDATE_BUDDY messages).

=back

=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 SEE ALSO

C<Net::AIM::TOC>

=head1 AUTHOR

Alistair Francis, http://search.cpan.org/~friffin/

=cut


