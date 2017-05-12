package TL1ng::Source::Telnet;

use strict;
use warnings;

=pod

This package implements the sending and collection of TL1 messages to and from 
a Telnet (or telnet-like) connection via use of Net::Telnet. Technically, it
'inherits' from TL1ng::Source. If Perl supported proper OO interfaces, that 
would mean it implements methods _read_msg() and _send_cmd() and timeout()
(it does, as should any class 'implementing' TL1ng::Source)

Any other methods are specific to the particular type of 'Source'. Therefore, 
a calling script or a device-specific subclass of TL1ng that may use them
should always check the isa() and/or the can() of $tll->source() before-hand.

=cut

our $VERSION = '0.07';

use base qw(TL1ng::Source);

our $DEBUG = 0; # Debugging level... someday I'll figger out AOP with Perl...

use Net::Telnet;
use Carp;

=head2 new

Initalizes the object used to manage the telnet connection to a TL1 NE/GNE.

TODO: Add info on the valid parameters.

=cut

sub new {
    my ($class, $params) = @_;
	croak "Parameter list must be an anonymous hash!\n" if $params && ref $params ne "HASH";
	$params = {} if ! $params;

    # Connect = Establish the Telnet connection now, instead 
    # of waiting for the user to call the connect method.
    my $connect_now = defined $params->{Connect} ? $params->{Connect} : 0;
    delete $params->{Connect} if defined $params->{Connect};
    
    # Default timeout is 60 seconds
    my $timeout = defined $params->{Timeout} ? $params->{Timeout} : 60;
    delete $params->{Timeout} if defined $params->{Timeout};
    
    # Default hostname is blank.
    my $hostname = defined $params->{Host} ? $params->{Host} : '';
    delete $params->{Host} if defined $params->{Host};
    
    # Default port is blank.
    my $port = defined $params->{Port} ? $params->{Port} : '';
    delete $params->{Port} if defined $params->{Port};
    
    # Defaults for this sub-class.
    my %self_params = (
		timeout  => $timeout,   # Timeout for connection and other operations
        hostname => $hostname,  # Hostname or IP address of the NE/GNE telnet interface
        port     => $port,      # TCP port to connect to on the NE/GNE
        %$params,               # Merge additional params into this hash.
        prompt   => '/[;><]/',  # Chars that match the end of a TL1 message...
		                        # Overriding the prompt could be bad.
    );

    my $self = bless( {%self_params}, $class );

    $self->_init_telnet();

	
    # Set up $self->{socket} with a Net::Telnet connection
    if ( $connect_now ) {
        return unless $self->connect();
    }
    return $self;
}

sub _init_telnet {
    my $self = shift;

    # 0 is a better default than auto for this 'cause it's more predictable.
    my $cmd_remove_mode =
      defined $self->{Cmd_remove_mode} ? $self->{Cmd_remove_mode} : 0;

    # Changed default from 0 to 1 for the Lucent nodes.
    my $telnetmode = defined $self->{Telnetmode} ? $self->{Telnetmode} : 1;

    $self->{telnet} = new Net::Telnet(
        Timeout         => $self->{timeout},
        Errmode         => 'return',
        Telnetmode      => $telnetmode,
        Cmd_remove_mode => $cmd_remove_mode,
        Prompt          => $self->{prompt},
    ) || croak "Couldn't set up telnet connection!";
	
	return 1;
}




=pod

=head2 _read_msg

Reads a TL1 message from the connection to the NE and returns it as a
multi-line string. 

 my $msg = $tl1->_read_msg();

=cut

sub _read_msg {
    my $self = shift;
    my $recurse = shift || 0;

    my $msg;

    my ( $line, $terminator ) = $self->{telnet}->waitfor( $self->{prompt} );
    $msg = $line . $terminator if $line and $terminator;

    # Check for and handle errors reading frtom the telnet connection:
    if ( $self->{telnet}->timed_out() ) {

        # Timeout isn't inherently fatal.
        carp "Timed Out! (error not fatal)" if $DEBUG > 2;
    }
    elsif ( $self->{telnet}->eof() ) {
        carp "EOF detected. Connection failed?\n\t"
          . $self->{telnet}->errmsg('');
        $self->disconnect();
    }
    elsif ( $self->{telnet}->errmsg() ) {

        # Some other unknown type of error?
        carp "\t" . $self->{telnet}->errmsg('');
        $self->disconnect();
    }

    # if this message's terminator isn't on a line by itself,
    # this may be an echoed command... try getting the next message.
    elsif ( $msg !~ /^[;><]/xm ) {
        $msg = $self->_read_msg( ++$recurse ) unless $recurse;
    }

    return $msg;
}

sub _send_cmd {
    my $self = shift;
    my $cmd = shift;
    croak "Cannot send command. You are not connected to a telnet server."
        unless $self->connected();
    return $self->{telnet}->print($cmd);
}

=pod

=head2 connect

Connects to the TL1 port using Telnet. The settings for the session are usually 
set when creating the object (via new). Dies if the connection fails.<BR>
<BR>
I may change this method drastically in the future.

=cut

sub connect {
    my $self = shift;
    my $params = shift || {};

    $self->{telnet}->dump_log('telnet_dump.log')   if $DEBUG > 3;
    $self->{telnet}->input_log('telnet_input.log') if $DEBUG > 3;

    $self->{telnet}->open(
        Host => $self->{hostname},
        Port => $self->{port},
        %$params,
    ) || return;  # || die "Couldn't connect to " . "$self->{hostname}:$self->{port}\n";

    $self->{connected} = 1;
    print "Connected to $self->{hostname}:$self->{port}\n" if $DEBUG > 1;

    return 1;
}

=pod

=head2 connected

Use this to determine if the module is still connected to the TL1 data source.

 my $status = $tl1->connected();

=cut

sub connected { return shift->{connected} }

=pod

=head2 disconnect

Close the connection to the TL1 data source. Always returns 1.
 
 $tl1->disconnect();

=cut

sub disconnect {
    my $self = shift;
    $self->{telnet}->close() if $self->connected();
    $self->{connected} = undef;
    return 1;
}

=pod

=head2 timeout

Use this to set or get the amount of time this module will wait for input from 
the Telnet connection. See documentation on timeout() for the Net::Telnet 
module on CPAN for more info on valid values. When getting (no parameter 
passed), returns the current timeout value. When setting, returns $self. 

 # Get value
 my $timeout = $tl1->timeout();
 # Set value (returns $tl1, for chaining)
 $tl1->timeout($timeout);
 

=cut

sub timeout {
    my $self    = shift;
    my $timeout = @_ ? shift : -1; # force to invalid val if no param passed.

    # Net::Telnet's timeout can be set to some funky values, so the if
    # clause is kinda necessary. 0 is valid, undef is valid, negative numbers
    # are not valid. See the module's docs for an explanation.
    if ( ! defined $timeout || $timeout >= 0 ) {
		$self->{telnet}->timeout($timeout); 
		return $self;
	}

    return $self->{telnet}->timeout();
}

=pod

=head2 DESTROY

Some TL1 NE/GNE devices *really* don't like it when the connection isn't 
properly terminated. Therefore, the destructor helps prevent that from 
happening by calling disconnect().

=cut

sub DESTROY { return shift->disconnect() }

=pod

=head2 hostname

Sets or gets the hostname or IP address to connect to with Net::Telnet.

=cut

sub hostname {
    my $self = shift;
    $self->{hostname} = shift if @_;
    return $self;
}


=pod

=head2 port

Sets or gets the TCP port to connect to with Net::Telnet.

=cut

sub port {
	my $self = shift;
	$self->{port} = shift if @_;
	return $self;
}


1;
