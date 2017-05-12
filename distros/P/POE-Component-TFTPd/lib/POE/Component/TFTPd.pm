package POE::Component::TFTPd;

=head1 NAME

POE::Component::TFTPd - A tftp-server, implemented through POE

=head1 VERSION

0.0302

=head1 SYNOPSIS

 POE::Session->create(
     inline_states => {
         _start        => sub {
             POE::Component::TFTPd->create;
             $_[KERNEL]->post($alias => 'start');
         },
         tftpd_init    => sub {
             my($client, $fh) = ($_[ARG0], undef);
             open($fh, "<", $client->filename) if($client->rrq);
             open($fh, ">", $client->filename) if($client->wrq);
             $client->{'fh'} = $fh;
         },
         tftpd_done    => sub {
             my $client = $_[ARG0];
             close $client->{'fh'};
         },
         tftpd_send    => sub {
             my $client = $_[ARG0];
             if ($client->{'fh'}) {
                 seek $client->{'fh'}, $client->last_block * $client->block_size, 0;
                 read $client->{'fh'}, my $data, $client->block_size;
                 $_[KERNEL]->post($alias => send_data => $client, $data);
             }
         },
         tftpd_receive => sub {
             my($client, $data) = @_[ARG0,ARG1];
             print { $client->{'fh'} } $data;
             $_[KERNEL]->post($alias => send_ack => $client);
         },
         tftpd_log     => sub {
             my($level, $client, $msg) = @_[ARG0..ARG2];
             warn(sprintf "%s - %s:%i - %s\n",
                 $level, $client->address, $client->port, $msg,
             );
         },
     },
 );

=cut

use warnings;
use strict;
use POE::Component::TFTPd::Client;
use POE qw/Wheel::UDP Filter::Stream/;

our $VERSION = eval '0.0302';
our %TFTP_ERROR = (
    not_defined         => [0, "Not defined, see error message"],
    unknown_opcode      => [0, "Unknown opcode: %s"],
    no_connection       => [0, "No connection"],
    file_not_found      => [1, "File not found"],
    access_violation    => [2, "Access violation"],
    disk_full           => [3, "Disk full or allocation exceeded"],
    illegal_operation   => [4, "Illegal TFTP operation"],
    unknown_transfer_id => [5, "Unknown transfer ID"],
    file_exists         => [6, "File already exists"],
    no_such_user        => [7, "No such user"],
);

=head1 METHODS

=head2 create(%args)

Component constructor.

Args:

 Name        => default   # Comment
 --------------------------------------------------------------------
 alias       => TFTPd     # Alias for the POE session
 address     => 127.0.0.1 # Address to listen to
 port        => 69        # Port to listen to
 timeout     => 10        # Seconds between block sent and ACK
 retries     => 3         # How many retries before giving up on host
 max_clients => undef     # Maximum concurrent connections

=cut

sub create {
    my $class = shift;
    my %args  = @_;
    my $self  = bless \%args, $class;

    $self->{'alias'}    ||= 'TFTPd';
    $self->{'address'}  ||= '127.0.0.1';
    $self->{'port'}     ||= 69;
    $self->{'timeout'}  ||= 10;
    $self->{'retries'}  ||= 3;
    $self->{'clients'}    = {};
    $self->{'session'}    = POE::Session->create(
        inline_states => {
            _start => sub {
                $_[KERNEL]->alias_set($self->alias);
                $_[KERNEL]->delay(check_connections => 1);
            },
        },
        object_states => [
            $self => [ qw/start stop send_error input check_connections/ ],
            $self => {
                init_rrq  => 'init_request',
                init_wrq  => 'init_request',
                get_ack   => 'get_data',
                get_data  => 'get_data',
                send_ack  => 'send_data',
                send_data => 'send_data',
            },
        ],
    );

    return $self;
}

=head2 clients

Returns a hash-ref, containing all the clients:

 $client_id => $client_obj

See C<POE::Component::TFTPd::Client> for details

=head2 max_clients

Pointer to max number of concurrent clients:

 print $self->max_clients;
 $self->max_clients = 4;

=head2 retries

Pointer to the number of retries:

 print $self->retries;
 $self->retries = 4;

=head2 timeout

Pointer to the timeout in seconds:

 print $self->timeout;
 $self->timeout = 4;

=head2 address

Returns the address the server listens to.

=head2 alias

The alias for the POE session.

=head2 kernel

Method alias for C<$_[KERNEL]>.

=head2 port

Returns the local port

=head2 sender

Returns the sender session.

=head2 server

Returns the server: C<POE::Wheel::UDP>.

=head2 session

Returns this session.

=cut

BEGIN {
    no strict 'refs';

    my @lvalue = qw/retries timeout max_clients/;
    my @get    = qw/alias address port clients kernel server sender session/;

    for my $sub (@lvalue) {
        *$sub = sub :lvalue { shift->{$sub} };
    }

    for my $sub (@get) {
        *$sub = sub { shift->{$sub} };
    }
}

=head2 cleanup

 1. Logs that the server is done with the client
 2. deletes the client from C<$self-E<gt>clients>
 3. Calls C<tftpd_done> event in sender session

=cut

sub cleanup {
    my $self   = shift;
    my $client = shift;

    $self->log(trace => $client, 'done');
    $self->kernel->post($self->sender => tftpd_done => $client);
    delete $self->clients->{ $client->id };
}

=head2 log

Calls SENDER with event name 'tftpd_log' and these arguments:

  $_[ARG0] = $level
  $_[ARG1] = $client
  $_[ARG2] = $msg

C<$level> is the same as C<Log::Log4perl> use.

=cut

sub log {
    my $self = shift;
    $self->kernel->post($self->sender => tftpd_log => @_);
}

=head1 STATES

=head2 start

Starts the server, by setting up C<POE::Wheel::UDP>.

=cut

sub start {
    my $self   = $_[OBJECT];
    my $kernel = $_[KERNEL];

    $self->{'sender'} = $_[SENDER];
    $self->{'kernel'} = $_[KERNEL];
    $self->{'server'} = POE::Wheel::UDP->new(
                            Filter     => POE::Filter::Stream->new,
                            LocalAddr  => $self->address,
                            LocalPort  => $self->port,
                            InputEvent => 'input',
                        );
}

=head2 stop

Stops the TFTPd server, by deleting the UDP wheel.

=cut

sub stop {
    delete $_[OBJECT]->{'server'};
    $_[KERNEL]->alias_remove($_[OBJECT]->alias);
    $_[KERNEL]->alarm_remove_all;
}

=head2 check_connections

Checks for connections that have timed out, and destroys them. This is done
periodically, every second.

=cut

sub check_connections {
    my $self    = $_[OBJECT];
    my $kernel  = $_[KERNEL];
    my $clients = $self->clients;

    CLIENT:
    for my $client (values %$clients) {
        if($client->retries <= 0) {
            $self->log(info => $client, 'timeout');
            delete $clients->{ $client->id };
        }
        if($client->timestamp < time - $self->timeout) {
            $self->log(trace => $client, 'retry');
            $client->retries--;
            $kernel->post($self->sender => tftpd_send => $client);
        }
    }

    $kernel->delay(check_connections => 1);
}

=head2 input

Takes some input, figure out the opcode and pass the request on to the next
stage.

 opcode | event    | method
 -------|----------|-------------
 rrq    | init_rrq | init_request
 wrq    | init_wrq | init_request
 ack    | get_ack  | get_data
 data   | get_data | get_data

=cut

sub input {
    my $self           = $_[OBJECT];
    my $kernel         = $_[KERNEL];
    my $args           = $_[ARG0];
    my $client_id      = join ":", $args->{'addr'}, $args->{'port'};
    my($opcode, $data) = unpack "na*", shift @{ $args->{'payload'} };

    if($opcode eq &TFTP_OPCODE_RRQ) {
        $kernel->yield(init_rrq => $args, $opcode, $data);
        return;
    }
    elsif($opcode eq &TFTP_OPCODE_WRQ) {
        $kernel->yield(init_wrq => $args, $opcode, $data);
        return;
    }

    if(my $client = $self->clients->{$client_id}) {
        if($opcode == &TFTP_OPCODE_ACK) {
            $kernel->yield(get_ack => $client, $data);
        }
        elsif($opcode == &TFTP_OPCODE_DATA) {
            $kernel->yield(get_data => $client, $data);
        }
        elsif($opcode eq &TFTP_OPCODE_ERROR) {
            $self->log(error => $client, $data);
        }
        else {
            $kernel->yield(send_error => $client, 'unknown_opcode', [$opcode]);
        }
    }
    else {
        $client = POE::Component::TFTPd::Client->new($self, $args);
        $self->log(error => $client, 'no connection');
        $kernel->yield(send_error => $client, 'no_connection');
    }
}

=head2 send_data => $client, $data

Sends data to the client. Used for both ACK and DATA. It resends data
automatically on failure, and decreases C<$client-E<gt>retries>.

=cut

sub send_data {
    my $self    = $_[OBJECT];
    my $kernel  = $_[KERNEL];
    my $client  = $_[ARG0];
    my($opname) = $_[STATE] =~ /send_(\w+)/; # data/ack
    my($opcode, $data, $n, $done);

    if($opname eq 'data') {
        $opcode = &TFTP_OPCODE_DATA;
        $data   = $_[ARG1];
        $n      = $client->last_block + 1;
        $client->almost_done = length $data < $client->block_size;
    }
    elsif($opname eq 'ack') {
        $opcode = &TFTP_OPCODE_ACK;
        $data   = q();
        $client->retries = $self->retries;
        $n      = $client->last_block;
        $done   = $client->almost_done;
    }

    my $bytes = $self->server->put({
        addr    => $client->address,
        port    => $client->port,
        payload => [pack("nna*", $opcode, $n, $data)],
    });

    if($bytes) {
        $self->log(trace => $client, "sent $opname $n");
        $client->timestamp = time;
        $self->cleanup($client) if($done);
    }
    elsif($client->retries) {
        $client->retries--;
        $self->log(warning => $client, "failed to transmit $opname $n");
        $kernel->yield("send_$opname" => $client);
    }
}

=head2 get_data => $client, $data

Handles both ACK and DATA packets.

If correct packet-number:

 1. Logs the packet number
 2. Calls C<tftpd_receive> / C<tftpd_send> in sender session

On failure:

 1. Logs failure
 2. Resends the last packet

=cut

sub get_data {
    my $self      = $_[OBJECT];
    my $kernel    = $_[KERNEL];
    my $client    = $_[ARG0];
    my($opname)   = $_[STATE] =~ /get_(\w+)/; # data/ack
    my($n, $data) = unpack("na*", $_[ARG1]);
    my($this_state, $sender_state, $done);

    if($opname eq 'data') {
        $sender_state        = 'tftpd_receive';
        $this_state          = 'send_ack';
        $client->almost_done = length $data < $client->block_size;
    }
    elsif($opname eq 'ack') {
        $sender_state = 'tftpd_send';
        $this_state   = 'send_data';
        $done         = $client->almost_done;
    }

    if($n == $client->last_block + 1) { # get data
        $client->last_block ++;
        $self->log(trace => $client, "got $opname $n");
        $kernel->post($self->sender => $sender_state => $client, $data);
        $client->resent_block = 0;
        $self->cleanup($client) if($done);
    }
    else { # wrong block number
        # Check if we've already sent block and received an ack
        # this prevents "Sorcerers Apprentice Syndrome"
        if (!$client->resent_block) {
            $self->log(trace => $client, sprintf(
                "wrong %s %i (%i)", $opname, $n, $client->last_block + 1,
            ));
            $client->resent_block = 1;
            $kernel->post($self->sender => $sender_state => $client, $data);
        }
        else {
            $self->log(trace => $client, sprintf("Duplicate ack (%i, %i) - not responding", $n, $client->last_block + 1));

            # We dont want to talk to the client for this block again so return
            #$kernel->yield($this_state => $client);
            return;
        }
    }

    return;
}

=head2 init_request => $args, $opcode, $data

 1. Checks if max_clients limit is reached. If not, sets up

  $client->filename  = $file;    # the filename to read/write
  $client->mode      = uc $mode; # only OCTET is valid
  $client->rfc       = [ ... ];
  $client->timestamp = time;

 2. Calls C<tftpd_init> in sender session.

 3. Calls C<tftpd_send> in sender session, if read-request from client

=cut

sub init_request {
    my $self      = $_[OBJECT];
    my $kernel    = $_[KERNEL];
    my $args      = $_[ARG0];
    my $opcode    = $_[ARG1];
    my $datagram  = $_[ARG2];
    my($opname)   = $_[STATE] =~ /init_(\w+)/;
    my $client_id = join ":", $args->{'addr'}, $args->{'port'};
    my($client, $file, $mode, @rfc);

    if(my $n = $self->max_clients) {
        if(int keys %{ $self->clients } > $n) {
            $self->log(error => $client, 'too many connections');
            return;
        }
    }

    $client = POE::Component::TFTPd::Client->new($self, $args);
    $self->clients->{$client_id} = $client;

    ($file, $mode, @rfc) = split("\0", $datagram);
    $client->filename    = $file;
    $client->mode        = uc $mode;
    $client->rfc         = \@rfc;
    $client->timestamp   = time;

    if($client->mode ne 'OCTET') {
        $self->log(error => $client, 'mode not supported');
        $kernel->yield(send_error => $client, 'illegal_operation');
        return;
    }

    $self->log(info => $client, "$opname $file");

    $kernel->post($self->sender => tftpd_init => $client);

    if($opcode == &TFTP_OPCODE_RRQ) {
        $kernel->post($self->sender => tftpd_send => $client);
        $client->rrq = 1;
    }
    else {
        $kernel->yield(send_ack => $client);
        $client->wrq = 1;
    }
}

=head2 send_error => $client, $error_key [, $args]

Sends an error to the client.

 $error_key referes to C<%TFTP_ERROR>
 $args is an array ref that can be used to replace %x in the error string

=cut

sub send_error {
    my $self   = $_[OBJECT];
    my $client = $_[ARG0];
    my $key    = $_[ARG1];
    my $args   = $_[ARG2] || [];
    my $error  = $TFTP_ERROR{$key} || $TFTP_ERROR{'not_defined'};

    $self->log(error => $client, sprintf($error->[1], @$args));
    delete $self->clients->{$client->id};
 
    $self->server->put({
        addr    => $client->address,
        port    => $client->port,
        payload => [pack("nnZ*", &TFTP_OPCODE_ERROR, @$error)],
    });

    return;
}

=head1 FUNCTIONS

=head2 TFTP_MIN_BLKSIZE

=head2 TFTP_MAX_BLKSIZE

=head2 TFTP_MIN_TIMEOUT

=head2 TFTP_MAX_TIMEOUT

=head2 TFTP_DEFAULT_PORT

=head2 TFTP_OPCODE_RRQ

=head2 TFTP_OPCODE_WRQ

=head2 TFTP_OPCODE_DATA

=head2 TFTP_OPCODE_ACK

=head2 TFTP_OPCODE_ERROR

=head2 TFTP_OPCODE_OACK

=cut

sub TFTP_MIN_BLKSIZE  { return 512;  }
sub TFTP_MAX_BLKSIZE  { return 1428; }
sub TFTP_MIN_TIMEOUT  { return 1;    }
sub TFTP_MAX_TIMEOUT  { return 60;   }
sub TFTP_DEFAULT_PORT { return 69;   }
sub TFTP_OPCODE_RRQ   { return 1;    }
sub TFTP_OPCODE_WRQ   { return 2;    }
sub TFTP_OPCODE_DATA  { return 3;    }
sub TFTP_OPCODE_ACK   { return 4;    }
sub TFTP_OPCODE_ERROR { return 5;    }
sub TFTP_OPCODE_OACK  { return 6;    }

=head1 AUTHOR

Jan Henning Thorsen, C<< <jhthorsen-at-cpan-org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
1;
