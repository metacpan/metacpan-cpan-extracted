# $Id: Server.pm,v 1.8 2008/10/21 16:11:18 turnstep Exp $

package Net::SSH::Perl::Subsystem::Server;
use strict;
use warnings;

use Net::SSH::Perl::Buffer;
use Carp qw( croak );
use Symbol qw( gensym );

sub new {
    my $class = shift;
    my $ss = bless { }, $class;
    $ss->init(@_);
}

sub buffer_class { 'Net::SSH::Perl::Buffer' }

sub init {
    my $ss = shift;
    my %param = @_;

    $ss->{in} = _dup('STDIN', '<');
    $ss->{out} = _dup('STDOUT', '>');

    $ss->{iq} = $ss->buffer_class->new( MP => 'SSH2' );
    $ss->{oq} = $ss->buffer_class->new( MP => 'SSH2' );

    if (my $log = $param{Log}) {
        my $fh = $ss->{log_fh} = gensym;
        open $fh, '>>', $log or die "Can't open logfile $log: $!";
        select((select($fh), $|=1)[0]);
    }

    $ss;
}

sub log {
    my $ss = shift;
    return unless my $fh = $ss->{log_fh};
    print $fh "$ss [$$] @_\n";
}

sub register_handler { $_[0]->{_handlers}{$_[1]} = $_[2] }
sub handler_for { $_[0]->{_handlers}{$_[1]} }

sub serve {
    my $ss = shift;

    while () {
        vec(my $rbits, fileno($ss->{in}), 1) = 1;
        vec(my $wbits, fileno($ss->{out}), 1) = 1 if $ss->{oq}->length;

        croak "select error: $!"
            unless select($rbits, $wbits, undef, undef);

        if (vec($rbits, fileno($ss->{in}), 1)) {
            my $len = sysread $ss->{in}, my $buf, 4*4096;
            warn("read eof"), return unless $len;
            croak "read error" unless $len > 0;
            $ss->{iq}->append($buf);
        }

        if ($ss->{oq}->length) {
            my $len = syswrite $ss->{out}, $ss->{oq}->bytes;
            croak "write error" if $len < 0;
            $ss->{oq}->bytes(0, $len, '');
        }

        $ss->process_incoming;
    }
}

sub process_incoming {
    my $ss = shift;
    my $iq = $ss->{iq};
    return unless $iq->length >= 5;
    my $len = unpack "N", $iq->bytes(0, 4);
    croak "Message too long" if $len > 256 * 1024;
    return if $iq->length < $len + 4;
    $iq->bytes(0, 4, '');
    my $msg = $ss->buffer_class->new( MP => 'SSH2' );
    $msg->append( $iq->bytes(0, $len, '') );
    my $type = $msg->get_int8;
    if (my $code = $ss->handler_for($type)) {
        $code->($ss, $msg);
    }
}

sub send_msg {
    my $ss = shift;
    my($msg) = @_;
    $ss->{oq}->put_int32($msg->length);
    $ss->{oq}->append($msg->bytes);
}

sub _dup {
    my($fh, $mode) = @_;
    my $dup = Symbol::gensym;
    my $str = "${mode}&$fh";
    open ($dup, $str) or die "Could not dupe: $!\n"; ## no critic
    $dup;
}

1;

=head1 NAME

Net::SSH::Perl::Subsystem::Server - Server infrastructure for SSH subsystems

=head1 SYNOPSIS

    use Net::SSH::Perl::Subsystem::Server;
    use base qw( Net::SSH::Perl::Subsystem::Server );

    use constant MSG_FOO => 1;

    sub init {
        my $ss = shift;
        $ss->SUPER::init(@_);

        $ss->register_handler(MSG_FOO, \&handle_foo);
    }

    sub handle_foo {
        my $ss = shift;
        my($msg) = @_;
        print "Got MSG_FOO message!\n";
    }

=head1 DESCRIPTION

I<Net::SSH::Perl::Subsystem::Server> is a generic subclass that can
be used to build servers for SSH-2 subsystems. A subsystem is a
network protocol that runs on top of a secure, encrypted SSH
connection between two machines: it allows the user and developer
to build a secure network protocol without worrying about the
details of that security, because it inherits the secure tunnel
from SSH.

I<Subsystem::Server> provides basic functionality needed by
all subsystem servers. A subsystem daemon is started up by the
sshd when a request comes in for that subsystem; sshd and the
subsystem daemon then talk to each other through pipes, and data
that the daemon wishes to send to the subsystem client is sent
over the network through the SSH secure tunnel. I<Subsystem::Server>
handles the talking to the sshd, and lets the application
developer focus on designing the network protocol and handling
requests from the subsystem client.

=head1 USAGE

I<Net::SSH::Perl::Subsystem::Server> is meant to be used as a base
class for subsystem servers. With that in mind, general usage should
follow the example above in the I<SYNOPSIS>:

=over 4

=item * Initialization

If you want your subclass to do anything, you'll want to override
the I<init> method so that you can set up handlers for specific
types of messages from the subsystem client. For each message
type, you need to associate the type with a subroutine reference
that will be invoked when a message of that type is received
by the core server. You do this by calling the I<register_handler>
method (see below).

=item * Message Handling

When the core server receives new messages from the client, it
grabs the first byte from the incoming stream; the first byte is
a packed 8-bit integer representing the type of the message. This
identifier is used to look up the message handler to handle this
particular type of message.

=back

These are the public methods in which your subclass will be most
interested:

=head2 $ss->init(%args)

Initializes the subsystem server object. This is where you'll
want to set up your message handlers (using I<register_handler>)
and perhaps perform any other protocol-specific initialization.

Make sure that your I<init> method returns the I<$ss> object
on success; failure to return I<init> should be an indication
of failure to calling code.

I<%args> can contain whatever you like it to contain. The base
class I<Net::SSH::Perl::Subsystem::Server> takes these
parameters in I<%args>:

=over 4

=item * Log

The location of a file on disk where you can write messages
to be logged. This is the file to which messages sent to
the I<log> method (below) will be written.

This is an optional argument; if not specified, no log file
will be used, and calls to I<log> will be silently ignored.

=back

=head2 $ss->register_handler($type, $code)

Configures the subsystem server I<$ss> such that any message
sent from the client whose type is I<$type> will automatically
invoke the subroutine reference I<$code>. This is how you build
protocol-specific functionality into your subsystem: you
associate message types with methods.

The subroutine reference I<$code> will be invoked and given
two arguments: I<$ss>, the instance of the subsystem server
that is blessed into your subclass, and I<$msg>, a buffer in
the class I<Net::SSH::Perl::Buffer> (although you can choose
a different buffer class--see I<buffer_class>, below).

=head2 $ss->send_msg($msg)

Sends the message I<$msg> to the client. Or, in more technical
terms, adds the message I<$msg> to the server's output queue, to
be written back to the client the next time through the select
loop.

I<$msg> should be a buffer in the class I<Net::SSH::Perl::Buffer>
(although you can choose a different buffer class--see
I<buffer_class>, below).

=head2 $ss->serve

Enters the select loop, waiting for requests from the client.
Users of your class should call this method when they're
ready to start serving clients.

=head2 $ss->log($message)

Writes the log message I<$message> to the log file, if one was
specified as the I<Log> argument to I<init> (or, rather, to the
constructor).

If a log file was not specified, returns silently.

=head2 $ss->buffer_class

By default, messages are represented by I<Net::SSH::Perl::Buffer>
objects. You can alter this by overriding the I<buffer_class>
method; it should return the name of an alternate class. Be aware
that this alternate class I<must> conform to the interface used
by I<Net::SSH::Perl::Buffer>, so you may be best off subclassing
that class and adding in your own functionality.

=head1 NOTES

It should be noted that the external interface (API) to this
module is alpha, and could change.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
