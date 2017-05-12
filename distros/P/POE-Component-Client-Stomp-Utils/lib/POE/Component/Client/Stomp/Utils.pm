package POE::Component::Client::Stomp::Utils;

use 5.008;
use strict;
use warnings;

use Net::Stomp::Frame;

our $VERSION = '0.02';

# -------------------------------------------------------------------

sub new {
    my $proto = shift;

    my $self = {};
    my $class = ref($proto) || $proto;

    $self->{transaction_id} = 0;
    $self->{session_id} = 0;
    $self->{message_id} = 0;

    bless($self, $class);

    return $self;

}

# -------------------------------------------------------------------
# Mutators
# -----------------------------------------------------------

sub transaction_id {
    my ($self, $a) = @_;

    $self->{transaction_id} = $a if (defined $a);
    return $self->{transaction_id};

}

sub session_id {
    my ($self, $a) = @_;

    $self->{session_id} = $a if (defined $a);
    return $self->{session_id};

}

sub message_id {
    my ($self, $a) = @_;

    $self->{message_id} = $a if (defined $a);
    return $self->{message_id};

}

# -----------------------------------------------------------
# Methods
# -----------------------------------------------------------

sub connect {
    my ($self, $params) = @_;

    my $body = '';
    my $command = 'CONNECT';

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

sub subscribe {
    my ($self, $params) = @_;

    my $body = '';
    my $command = 'SUBSCRIBE';

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

sub unsubscribe {
    my ($self, $params) = @_;

    my $body = '';
    my $command = 'UNSUBSCRIBE';

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

sub begin {
    my ($self, $params) = @_;

    my $body = '';
    my $command = 'BEGIN';

    $self->transaction_id($params->{transaction});

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

sub commit {
    my ($self, $params) = @_;

    my $body = '';
    my $command = 'COMMIT';

    $params->{transaction} = $self->transaction_id;

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

sub ack {
    my ($self, $params) = @_;

    my $body = '';
    my $command = 'ACK';

    $params->{transaction} = $self->transaction_id 
        if ($self->{transaction_id} > 0);

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

sub abort {
    my ($self, $params) = @_;

    my $body = '';
    my $command = 'ABORT';

    $params->{transaction} = $self->transaction_id; 
    $self->{transaction_id} = 0;

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

sub disconnect {
    my ($self, $params) = @_;

    my $body = '';
    my $command = 'DISCONNECT';

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

sub send {
    my ($self, $params) = @_;

    my $body = $params->{data};
    my $command = 'SEND';

    delete $params->{data};
    $params->{'content-length'} = length($body);

    return(Net::Stomp::Frame->new({command => $command,
                                   headers => $params,
                                   body => $body}));

}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

POE::Component::Client::Stomp::Utils - A set of utility routines for POE clients
that wish to use a Message Queue server that understands the Stomp protocol.

=head1 SYNOPSIS

This module uses Net::Stomp::Frame to create frames for usage within POE based
programs that wish to communicate to Message Queue servers. 

=head1 DESCRIPTION

 Your program could use this module in the following fashion:

 use POE;
 use POE::Component::Client::Stomp;
 use POE::Component::Client::Stomp::Utils;

 my $stomp = POE::Component::Client::Stomp::Utils->new();
 my $frame = $stomp->connect({login => 'test', passcode => 'test'});
 $heap->{server}->put($frame);

The above examples creates a "CONNENCT" frame and sends it to the server. If
the connection suceeds, the server will send back a "CONNECTION" frame. The
handling of that frame is left up to your input handlers.

A Stomp frame consists of the following:

 COMMAND\012
 HEADERS\012
 BODY\000

Each command may have one or more headers. Some of those headers are
optional. For the most part, the parameters passed to these methods are 
literal translations of what the protocol needs for each of the frame 
commands. This was done, because the protocol is described as being in flux,
with a 1.0 version being available "real soon now". 

So, NO ERROR checking is done. How the server will handle protocol errors is 
highly dependent on the servers implementation. For example, the server that 
I have been testing against, quietly dies. You have been warned...

No serialization of data is done within these routines. You will need to 
decide what serialiazarion is needed and perform that serialization before 
calling these methods. I have found the JSON is a light, and efficent 
serialization method. And just about every other lanaguage has a JSON 
implementation readily avaiable.

Some terminology issues. I am using the term "channel" to describe the
communications pathway to named resources. The documentation for
some of the vaious Message Queue servers, are using terms such "queue", 
"topic" and other nouns to describe the same thing.  

=head1 METHODS

=over 4

=item new

This method initializes the base object. It also creates internal storage for
the session ID, the message ID and the transaction ID. If a transaction ID has
been set, it will be automatically passed to those methods that require one.

=over 4 

=item Example

 $stomp = POE::Component::Client::Stomp::Utils->new();

=back 

=item connect

This method creates a "connect" frame. This frame is used to initiate a
session with a Stomp server. 

=over 4 

=item Example

 $frame = $stomp->connect({login => 'test', passcode => 'test'});
 $heap->{server}->put($frame);

=back

=item disconnect

This method creates a "disconnect' frame. This framse is used to signal the
server that you no longer wish to communicate with it.

=over 4

=item Example

 $frame = $stomp->disconnect();
 $heap->{server}->put($frame);

=back

=item subscribe

This method create a "subscribe" frame. This frame is used to notify 
the server which channels you want to listen too. The naming of channels is 
left up to the server implementation. When a message is available on requested 
channels, it will be sent your program.

=over 4 Example

 $frame = $stomp->subscribe({destination => '/queue/test', 
                             ack => 'client'});
 $heap->{server}->put($frame);

=back

=item unsubscribe

This method creates an "unsubscribe" frame. This frame is used to notify the
server that you don't want to listen on that channel anymore. Subsequently
any messages left on that channel will no longer be sent to your program.

=over 4 Example

 $frame = $stomp->unsubcribe({destination => 'test'});
 $heap->{server}->put($frame);

=back

=item begin

This method creates a "begin" frame. This frame signals the server that a 
transaction is beginning. A transaction is either ended by a "commit" frame 
or an "abort" frame. Any other frame that is sent must have a transaction id
associated with them. This is handled internally. The transaction id can be 
anything that makes sense to you.

=over 4

=item Example

 $frame = $stomp->begin({transaction => '1234'});
 $heap->{server}->put($frame);

 $frame = $stomp->send({destination => 'test', 
                        data => 'this is my message'});
 $heap->{server}->put($frame);

 $frame = $stomp->commit();
 $heap->{server}->put($frame);

=back

=item commit

This method creates a "commit" frame. This frame signals the end of a 
transaction. See the above example on usage.

=item abort

This method creates an "abort" frame. This frame is used to signal the server
that the current transaction is to be aborted.

=over 4 

=item Example

 $frame = $stomp->abort();
 $heap->{server}->put($frame);

=back

=item send

This method create a "send" frame. This frame is the basis of communication
over your channel to the server.

=over 4

=item Example

 $frame = $stomp->send({destination => 'test', 
                        data => 'this is my packet'});
 $heap->{server}->put($frame);

or

 $message = objToJson($data);
 $frame = $stomp->send({destination => 'test', 
                        data => $message, 
                        receipt => 'abcd'});
 $heap->{server}->put($frame);

 sub input_handler {
     my ($heap, $frame) = @_[HEAP, ARG0 ];

     if (($frame->command eq 'RECEIPT') and 
         ($frame->headers->{'receipt-id'} eq 'abcd')) {

         print "Message was seccessfully sent!\n";

     }

 }

=back

=item ack

This method creates an "ack" frame. This frame is used to tell the server that 
the message was successfully received. It requires a message id.

=over 4

=item Example

 $frame = $stomp->ack({'message-id' => '1234'});
 $heap->{server}->put($frame);

or

 sub input_handler {
     my ($heap, $frame) = @_[HEAP, ARG0];

     if ($frame->command eq 'MESSAGE') {

         $stomp->message_id($frame->headers->{'message-id'});
         $poe_kernel->post('test' => srv_message => $frame);

    }

 }

 sub srv_message {
     my ($heap, $frame) = @_[HEAP, ARG0];

     my $frame = $stomp->ack({'message-id' => $stomp->message_id});
     my $data = jsonToObj($frame->body);

     handle_data($data);
     $heap->{server}->put($frame);

 }

=back

=head1 MUTATORS

=item transaction_id

This mutator will set/get the current transaction id. This transaction id will
be used automatically in other methods that require this parameter when
a transaction is in progress.

=over 4

=item Example

 $trans_id = $stomp->transaction_id;
 $stomp->transaction_id('1234');

=back

=item message_id

This mutator will set/get the current message id. 

=over 4

=item Example

 $msg_id = $stomp->message_id;
 $stomp->message_id('1234');

=back

=item session_id

This mutator will get/set the session_id. The session id is set once upon 
initial connection to the server.

=head1 EXPORT

None by default.

=head1 SEE ALSO

 Net::Stomp
 Net::Stomp::Frame
 POE::Component::Client::Stomp

 http://stomp.codehaus.org/Protocol

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
