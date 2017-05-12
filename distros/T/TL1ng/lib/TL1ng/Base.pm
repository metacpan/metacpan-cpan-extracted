
=pod

=head1 DESCRIPTION

Base class for device-specific TL1ng classes. Provides the most basic 
functionality required for working with TL1. Sub-classes typically would not 
override the methods here, rather they would use those methods to build 'macros'
for working with a specific device.<br>
<br>
I plan on writing an example device-specific sub-class in the near future to
demonstrate what I mean.

=cut

package TL1ng::Base;

use strict;
use warnings;

use Carp;

our $VERSION = '0.08';

use TL1ng::Parser;

our $DEBUG = 2;

=pod

=head2 new

Create a new TL1 object representing the connection to the TL1 NE/GNE.<BR>
<BR>
Right now I've only written a TL1ng::Source subclass to support working over a Telnet 
connection but in the future I may add the ability to use a serial port or 
named pipe or something...

=cut

sub new {
    my ($class, $params) = @_;
    $class = ref($class) || $class;

	croak "Parameter list must be an anonymous hash!\n" if $params && ref $params ne "HASH";
	$params = {} if ! $params;
	
	# Determine the class of the 'source' object... Telnet is the default.
	my $source_class = defined $params->{Source} 
		? "TL1ng::Source::" . $params->{Source} : "TL1ng::Source::Telnet";
	
	# Clean up parameters we've used here - anything left over would 
	# go to the TL1ng::Source class
	$params->{Source} and delete $params->{Source};
	
	# Unpacking the params hashref into an anonymous hashref so it 
	# doesn't get blessed and confuse the Source object's constructor.
	my $self = bless( { %$params }, $class );
	
	# Instantiate the Source object
	### I have no clue if this is a good way to do this or not.
	eval "use $source_class;";
	$self->{source} = $source_class->new( $params )
    	|| return; #croak "Couldn't initialize the $source_class module!";

	
    # Set up a parser:
    $self->{parser} = TL1ng::Parser->new();

    # Set up a queue for response messages that get read in, but haven't
    # been retrieved by the calling app. These can be any type of TL1 message.
    $self->{response_queue} = [];

    return $self;
}

=pod

=head2 get_next

Retrieves the next available message, regardless of it's type.
Will wait up to $timeout seconds for a message, defaulting to 
whatever the source's current timeout is. If no messages become 
available, returns undef. 

 my $timeout = $tl1->source->timeout();
 my $msg     = $tl1->get_next();  # waits $timeout seconds
 
 my $msg     = $tl1->get_next(5);  # waits 5 seconds
 
=cut

sub get_next {
    my $self = shift;
    my $timeout = shift;

    my $msg = shift( @{ $self->{response_queue} } );;

    # If there was no message in the queue, 
    # try to fetch one from the source.
    if ( ! $msg )
    {
        # Set a new timeout value if necessary, and save the old one.
        my $old_timeout;
        if ( defined $timeout ) {
            $old_timeout = $self->source->timeout();
            $self->source->timeout($timeout)
        }
        
        $msg = $self->{parser}->parse_string( $self->{source}->_read_msg() );
        
        # If necessary, put back the old timeout value.
        if ( defined $timeout ) {
             $self->source->timeout($old_timeout)  
        }
    } 
    return $msg;
}

=pod

=head2 get_auto

Retrieves the next available autonomous message. Will wait until $timeout 
seconds or default to $self->timeout(). If no autonomous message can be
retrieved, returns false. 

 my $msg = $tl1->get_auto();
 
=cut

sub get_auto {
    my $self = shift;

    my $timeout = shift;
    $timeout = $self->{source}->timeout() unless defined $timeout;
    my $start = time;

    # Search the response queue
    my $queue = $self->{response_queue};
    for ( my $x = 0 ; $x < @$queue ; $x++ ) {
        if ( exists $queue->[$x]{type} and $queue->[$x]{type} eq 'AUT' ) {
            return splice @$queue, $x, 1;
        }
    }

    # If that didn't work attempt to retrieve messages until the
    # timeout is exceeded.
    while ( time < $start + $timeout ) {
        if ( my $msg = $self->{parser}->parse_string( $self->{source}->_read_msg() ) ) {
            return $msg if exists $msg->{type} and $msg->{type} eq 'AUT';
            push @$queue, $msg if $msg;
        }
    }

    return;
}

=pod

=head2 get_resp

Retrieves the next available message that is a response to the given CTAG.
(Remember, all TL1 commands must have a CTAG for identifying the response
messages to the command) If $timeout is specified, waits that many seconds
for a matching message. If no timeout is specified, uses $self->timeout().
If no matching message is found, returns false. 

 my $CTAG = '12345';
 my $timeout = 60;
 my $msg = $tl1->get_resp($CTAG, $timeout);

=cut

sub get_resp {
    my $self = shift;
    my $CTAG = shift;

    my $timeout = shift;
    $timeout = $self->{source}->timeout() unless defined $timeout;
    
    # Search the response queue for command responses that match.
    # but make sure it's a command response, and not just an ack.
    my $queue = $self->{response_queue};
    for ( my $x = 0 ; $x < @$queue ; $x++ ) {
        if ( 
                 exists $queue->[$x]{CTAG} 
             and $queue->[$x]{CTAG} eq "$CTAG"
             and exists $queue->[$x]{type}
             and $queue->[$x]{type} eq 'CMD'
            ) 
        {
            return splice @$queue, $x, 1;
        }
    }

    # If that didn't work attempt to retrieve messages until the
    # timeout is exceeded.
    my $start = time;
    while ( time < $start + $timeout ) {
        last unless $self->source->connected();
        if ( my $msg = $self->{parser}->parse_string( $self->{source}->_read_msg() ) ) {
            return $msg if exists $msg->{CTAG} and $msg->{CTAG} eq "$CTAG" 
                       and exists $msg->{type} and $msg->{type} eq 'CMD';
            push @$queue, $msg if $msg;
        }
    }

    return;
}

=pod

=head2 send_cmd

Sends a TL1 command string to the connected NE. This method will NOT wait for 
the NE to return any response, but my experience shows that this 
response may or not be useful, or even related to the issued command! 
Therefore, after sending the command this method returns the status of the
output operation.(almost *always* true) Any responses to this command 
(or whatever the NE sends next) can be retrieved with get_next().

 my $cmd = 'rtrv-alm-all:andvmael3001::1;';
 $tl1->send_cmd($cmd);
 my $resp = $tl1->get_next();

Just a trick - this method (on success) actually returns $self, so you can 
chain it with another method, like this...

 my $ctag = '1234';
 my $cmd = 'rtrv-alm-all:andvmael3001::${ctag};';
 my $resp = $tl1->send_cmd($cmd)->get_resp($ctag);

=cut

sub send_cmd {
    my $self = shift;
    my $cmd = shift;
    $self->{last_ctag} = (split ':|;', $cmd)[3]; # Parse out the CTAG and remember it.
    $self->{source}->_send_cmd($cmd) 
        and return $self;
    return;
}

=pod

=head2 source

Returns a reference to the module that provides access to the TL1 NE.

 $tl1->source->connect();
 $tl1->source->is_connected();
 # etc...

=cut

sub source { return shift->{source} }

=head2 rand_ctag

Generates a random valid CTAG.

=cut

sub rand_ctag { return int(rand() * 1000) }

=head2 last_ctag

Returns the last CTAG used with send_cmd() 
(which parses out the CTAG and remembers it.)

=cut

sub last_ctag { return shift->{last_ctag} || '' }

1;
