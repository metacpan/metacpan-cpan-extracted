package Net::SMTP::Pipelining;

use version; $VERSION = qv('0.0.4');

use strict;
use warnings;
use Net::Cmd;
use IO::Socket;

use base("Net::SMTP");

sub pipeline {
    my ( $self, $mail ) = @_;

    if ( !defined( $self->supports("PIPELINING") ) ) {
        my $message = qq(Server does not support PIPELINING, banner was ").$self->banner().qq(");
        push @{ ${*$self}{'smtp_pipeline_errors'} },
            {
             command => "EHLO",
             code    => "",
             message => $message,
         };
        warn $message;
        return;
    }

    my @rcpts =
        ref( $mail->{to} ) eq ref( [] )
        ? @{ $mail->{to} }
        : $mail->{to};

    my @send = ( "MAIL FROM: " . $self->_addr( $mail->{mail} ) );
    push @send, map { "RCPT TO: " . $self->_addr($_) } @rcpts;
    push @send, "DATA";

    ${*$self}{'smtp_pipeline_pending_answers'} += scalar(@send);
    delete ${*$self}{'net_cmd_last_ch'};
    ${*$self}{'smtp_pipeline_errors'} = [];
    ${*$self}{'smtp_pipeline_sent'}   = [];

    # RFC 2920:
    # "If nonblocking operation is not supported, however, client SMTP
    # implementations MUST also check the TCP window size and make sure
    # that each group of commands fits entirely within the window. The
    # window size is usually, but not always, 4K octets.  Failure to
    # perform this check can lead to deadlock conditions."
    #
    # We do use non-blocking IO, but there doesn't seem to be a good
    # way of obtaining the TCP window size from a socket. All the MTAs
    # I've examined seem to ignore this issue, except for Postfix, which
    # simply sets the send buffer to the attempted message length and
    # dies on error. We'll report the error and abort.
    #
    # TODO: Add a test for this
    my $length;
    my $total_msg = join( "\015\012", @send ) . "\015\012";
    do { use bytes; $length = length($total_msg); };
    if ( $length >= $self->sockopt(SO_SNDBUF) ) {
        if ( !$self->sockopt( SO_SNDBUF, $length ) ) {
            $self->reset();
            push @{ ${*$self}{'smtp_pipeline_errors'} },
                {
                command => $total_msg,
                code    => 599,
                message =>
                    "Message too large for TCP window and could not set SO_SNDBUF to length $length: $!"
                };
            push @{ ${*$self}{'smtp_pipeline_rcpts'}{'failed'} }, @rcpts;
            return;
        }
    }
    for (@send) {
        $self->command($_);
        push @{ ${*$self}{'smtp_pipeline_sent'} }, $_;
    }
    my $success = $self->_pipe_flush();
    my @codes   = @{ $self->pipe_codes() };

    my $prev_send = scalar(@codes) > scalar(@send) ? 1 : 0;

    my %failed;

    for my $i ( $prev_send .. $#codes ) {
        my $exp = $i == $#codes ? 3 : 2;
        my ($command) = ( $send[ $i - $prev_send ] =~ m/^(\w+)/ );
        if ( $codes[$i] =~ m/^$exp/ ) {
            if ( $command eq "RCPT" ) {
                push @{ ${*$self}{'smtp_pipeline_rcpts'}{'accepted'} },
                    $rcpts[ $i - $prev_send - 1 ];
            }
        } else {

            push @{ ${*$self}{'smtp_pipeline_errors'} },
                {
                command => $send[ $i - $prev_send ],
                code    => $codes[$i],
                message => ${*$self}{'smtp_pipeline_messages'}[$i],
                };
            if ( $command eq "RCPT" ) {
                push @{ ${*$self}{'smtp_pipeline_rcpts'}{'failed'} },
                    $rcpts[ $i - $prev_send - 1 ];
            } else {
                $failed{$command} = $codes[$i];
            }
        }
    }
    if ( exists $failed{"MAIL"} || exists $failed{"DATA"} ) {
        $self->reset();
        return;
    }

    if ( scalar @{ ${*$self}{'smtp_pipeline_rcpts'}{'failed'} } > 0 ) {
        if ( scalar @{ ${*$self}{'smtp_pipeline_rcpts'}{'accepted'} } > 0 ) {
            $success = undef;
        } else {

  #    From RFC 2920:
  #    "Client SMTP implementations that employ pipelining MUST check ALL
  #    statuses associated with each command in a group. For example, if
  #    none of the RCPT TO recipient addresses were accepted the client must
  #    then check the response to the DATA command -- the client cannot
  #    assume that the DATA command will be rejected just because none of
  #    the RCPT TO commands worked.  If the DATA command was properly
  #    rejected the client SMTP can just issue RSET, but if the DATA command
  #    was accepted the client SMTP should send a single dot."
  #
  #    Untested (because Net::Server::Mail doesn't apparently allow you
  #    to return a 354 after all recipients have failed), but this should work
            $self->_pipe_dataend();
            return;
        }
    }

    $success = $self->datasend( $mail->{data} ) ? $success : undef;

    push @{ ${*$self}{'smtp_pipeline_sent'} }, $mail->{data};

    ${*$self}{'smtp_pipeline_pending_answers'}++;

    $self->_pipe_dataend();

    return $success;
}

sub pipe_recipients {
    return ${ *{ $_[0] } }{'smtp_pipeline_rcpts'};
}

sub pipe_rcpts_failed {
    return ${ *{ $_[0] } }{'smtp_pipeline_rcpts'}{'failed'};
}

sub pipe_rcpts_succeeded {
    return ${ *{ $_[0] } }{'smtp_pipeline_rcpts'}{'succeeded'};
}

sub pipe_sent {
    return ${ *{ $_[0] } }{'smtp_pipeline_sent'};
}

sub pipe_errors {
    return ${ *{ $_[0] } }{'smtp_pipeline_errors'};
}

sub _pipe_dataend {
    my $self = shift;
    my $end  = "\015\012.\015\012";

    # TODO: add test for failed write
    syswrite( $self, $end, 5 ) or warn "Last character not sent: $!";
    $self->debug_print( 1, ".\n" )
        if ( $self->debug );
}

sub pipe_flush {
    my $self = shift;
    ${*$self}{'smtp_pipeline_sent'} = [];
    $self->_pipe_flush();
}

sub _pipe_flush {
    my $self = shift;

    ${*$self}{'smtp_pipeline_messages'} = [];
    ${*$self}{'smtp_pipeline_codes'}    = [];
    ${*$self}{'net_cmd_resp'}           = [];

    while (
        scalar @{ ${*$self}{'smtp_pipeline_messages'} }
        < ${*$self}{'smtp_pipeline_pending_answers'} )
    {
        $self->response();
        push @{ ${*$self}{'smtp_pipeline_messages'} }, [ $self->message() ];
        push @{ ${*$self}{'smtp_pipeline_codes'} }, $self->code();
        ${*$self}{'net_cmd_resp'} = [];
    }
    push @{ ${*$self}{'net_cmd_resp'} },
        ${*$self}{'smtp_pipeline_messages'}[-1];
    ${*$self}{'smtp_pipeline_pending_answers'} = 0;
    delete ${*$self}{'net_cmd_last_ch'};

    if (scalar( @{ $self->pipe_codes() } )
        > scalar( @{ $self->pipe_sent() } ) )
    {
        my $prev_code = ${*$self}{'smtp_pipeline_codes'}[0];
        my $prev_resp = ${*$self}{'smtp_pipeline_messages'}[0];
        if ( $prev_code =~ m/^2/ ) {
            @{ ${*$self}{'smtp_pipeline_rcpts'}{'succeeded'} } =
                @{ ${*$self}{'smtp_pipeline_rcpts'}{'accepted'} };
            ${*$self}{'smtp_pipeline_rcpts'}{'failed'} = [];
        } else {
            ${*$self}{'smtp_pipeline_rcpts'}{'succeeded'} = [];
            @{ ${*$self}{'smtp_pipeline_rcpts'}{'failed'} } =
                @{ ${*$self}{'smtp_pipeline_rcpts'}{'accepted'} };
            push @{ ${*$self}{'smtp_pipeline_errors'} },
                {
                command => "DATA",
                code    => $prev_code,
                message => $prev_resp,
                };
        }
    } else {
        ${*$self}{'smtp_pipeline_rcpts'}{'failed'}    = [];
        ${*$self}{'smtp_pipeline_rcpts'}{'succeeded'} = [];
    }
    ${*$self}{'smtp_pipeline_rcpts'}{'accepted'} = [];

    if ( grep { $_ !~ /^[23]/ } @{ $self->pipe_codes() } ) {
        return;
    } else {
        return 1;
    }
}

sub pipe_codes {
    my $self = shift;
    ${*$self}{'smtp_pipeline_codes'};
}

sub pipe_messages {
    my $self = shift;
    ${*$self}{'smtp_pipeline_messages'};
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::SMTP::Pipelining - Send email using ESMTP PIPELINING extension


=head1 VERSION

This document describes Net::SMTP::Pipelining version 0.0.4


=head1 SYNOPSIS

    use Net::SMTP::Pipelining;

    my $smtp = Net::SMTP::Pipelining->new("localhost");

    my $sender = q(sender@example.com);
    my (@successful,@failed);
    for my $address (q(s1@example.com), q(s2@example.com), q(s3@example.com)) {
        $smtp->pipeline({ mail => $sender,
                          to   => $address,
                          data => qq(From: $sender\n\nThis is a mail to $address),
                        }) or push @failed,@{$smtp->pipe_rcpts_failed()};
        push @successful, @{$smtp->pipe_rcpts_succeeded()};
    }

    $smtp->pipe_flush() or push @failed,@{$smtp->pipe_rcpts_failed()};

    push @successful, @{$smtp->pipe_rcpts_succeeded()};

    print "Sent successfully to the following addresses: @successful\n";
    warn "Failed sending to @failed\n" if scalar(@failed) >0;

    # More intricate error handling
    if (!$smtp->pipeline({ mail => $sender,
                          to   => $address,
                          data => qq(From: $sender\n\nThis is a mail to $address),
                        })) {
        my $errors = $smtp->pipe_errors();

        for my $e (@$errors) {
            print "An error occurred:, we said $e->{command} ";
            print "and the server responded $e->{code} $e->{message}\n"
        }
    }

=head1 DESCRIPTION

This module implements the client side of the SMTP PIPELINING extension, as
specified by RFC 2920 (http://tools.ietf.org/html/rfc2920). It extends the
popular Net::SMTP module by subclassing it, you can use Net::SMTP::Pipelining
objects as if they were regular Net::SMTP objects.

SMTP PIPELINING increases the efficiency of sending messages over a high-latency
network connection by reducing the number of command-response round-trips in
client-server communication. To highlight the way regular SMTP differs from
PIPELINING (and also the way of working with this module), here is a comparison
($s is the Net::SMTP or Net::SMTP::Pipelining object, $from the sender and $to
the recipient):

Regular SMTP using Net::SMTP:

    Perl code             Client command        Server response
    $s->mail($from);      MAIL FROM: <fr@e.com>
                                                250 Sender <fr@e.com> ok
    $s->to($to);          RCPT TO: <to@e.com>
                                                250 Recipient <to@e.com> ok
    $s->data();           DATA
                                                354 Start mail,end with CRLF.CRLF
    $s->datasend("text"); text
    $s->dataend();        .
                                                250 Message accepted

Sending this message requires 4 round-trip exchanges between client and server.
In comparison, Pipelined SMTP using Net::SMTP::Pipelining (when sending more than
one message) only requires 2 round-trips for the last message and 1 round-trip
for the others:

    Perl code             Client command        Server response
    $s->pipeline(
      { mail => $from,
        to   => $to,
        data => "text",
       });
                          MAIL FROM: <fr@e.com>
                          RCPT TO: <to@e.com>
                          DATA
                                                250 Sender <fr@e.com> ok
                                                250 Recipient <to@e.com> ok
                                                354 Start mail,end with CRLF.CRLF
                          text
                          .
    $s->pipeline(
      { mail => $from,
        to   => $to,
        data => "text",
       });
                          MAIL FROM: <fr@e.com>
                          RCPT TO: <to@e.com>
                          DATA
                                                250 Message sent
                                                250 Sender <fr@e.com> ok
                                                250 Recipient <to@e.com> ok
                                                354 Start mail,end with CRLF.CRLF
                          text
                          .
     $s->pipe_flush();
                                                250 Message sent

As you can see, the C<pipeline> call does not complete the sending of a single
message. This is because a.) RFC 2920 mandates that DATA be the last command in
a pipelined command group and b.) it is at this point uncertain whether another
message will be sent afterwards. If another message is sent immediately
afterwards, the MAIL, RCPT and DATA commands for this message can be included in
the same command group as the text of the previous message, thus saving a
round-trip. If you want to handle messages one after the other without mixing
them in the same command group, you can call C<pipe_flush> after every call to
C<pipeline>, that will work fine but be less efficient (the client-server
communication then requires two round-trips per message instead of one).

=head1 INTERFACE 

=head2 CONSTRUCTOR

=over 4

=item new ( [ HOST ] [, OPTIONS ] )

    $smtp = Net::SMTP::Pipelining->new( @options );

This is inherited from Net::SMTP and takes exactly the same parameters, see the
documentation for that module.

=back

=head2 METHODS

=over 4

=item pipeline ( PARAMETERS )

    $smtp->pipeline({ mail => $from, to => $to, data => $text })
        or warn "An error occurred";

Sends a message over the connection. Accepts and requires the following
parameters passed in a hash reference:

    "mail" - the sender address
    "to"   - the recipient address
    "data" - the text of the message

Server response messages after the DATA command are checked. On success,
C<pipeline> returns true, otherwise false. False is returned if there is any
error at all during the sending process, regardless whether a message was
sent despite these errors. So for example, sending a message to two recipients,
one of which is rejected by the server, will return false, but the message will
be sent to the one valid recipient anyway. See below methods for determining
what exactly happens during the SMTP transaction.

If the server does not support PIPELINING (according to the initial connection
banner), C<pipeline> returns false, throws a warning (s.below DIAGNOSTICS
section) and puts the warning message into $smtp->pipe_errors()->[0]{message};

=item pipe_flush ()

    $smtp->pipe_flush() or warn "an error occurred";

Reads the server response, thereby terminating the command group (after a
message body has been sent). Will also return false on any error returned by
the server, true if no error occurred.

=item pipe_codes ()

    $codes = $smtp->pipe_codes();
    print "SMTP codes returned: @$codes\n";

Returns the SMTP codes in server responses to the previous call of C<pipeline>
or C<pipe_flush> in an array reference, in the order they were given.

=item pipe_messages ()

    $messages = $smtp->pipe_messages();
    print "@$_" for @$messages;

Returns the messages in server responses to the previous call of C<pipeline> or
C<pipe_flush> in a reference to an array of arrays. Each server response is an
element in the top-level array (in the order they were given), each line in that
response is an element in the array beneath that.

=item pipe_sent ()

    $sent = $smtp->pipe_sent();
    print "I said: ".join("\n",@$sent)."\n";

Returns the lines Net::SMTP::Pipelining sent to the server in the previous call
to C<pipeline> in an array reference, in the order they were sent. The array
references in the value returned by C<pipe_sent> will always contain the same
number of elements (in the same order) as C<pipe_codes> and C<pipe_messages>,
so you can reconstruct the whole SMTP transaction from these.

=item pipe_errors ()

    $err = $smtp->pipe_errors();
    for ( @$err ) {
        print "Error! I said $_->{command}, server said: $_->{code} $_->{message}";
    }

Returns a reference to an array of hashes which contain information about any
exchange that resulted in an error being returned from the server. These errors
are in the order they occurred (however, there may of course have been
successful commands executed between them) and contain the following information:

    command - the command sent by Net::SMTP::Pipelining
    code    - the server return code
    message - the server return message

=item pipe_recipients ()

    $rcpts = $smtp->pipe_recipients();
    print "Successfully sent to @{$rcpts->{succeeded}}\n";
    print "Failed sending to @{$rcpts->{failed}}\n";
    print "Recipient accepted, send pending: @{$rcpts->{accepted}}\n";

Returns the recipients of messages from the last call to C<pipeline> or
C<pipe_flush>. Note that this may include recipients from messages pipelined
with a previous call to C<pipeline>, because success of a message delivery can
only be reported after the subsequent message is pipelined (or the pipe is
flushed). The recipients are returned in a reference to a hash of arrays, the
hash has the following keys:

    accepted  - Recipient has been accepted after the RCPT TO command, but no
                message has been sent yet.
    succeeded - Message to this recipient has been successfully sent
    failed    - Message could not be sent to this recipient (either because
                the recipient was rejected after the RCPT TO, or because the
                send of the whole message failed).

Each recipient of all messages sent will appear in either the "succeeded" or
"failed" list once, so if all you care about is success you only need to inspect
these two.

=item pipe_rcpts_succeeded ()

    $success = $smtp->pipe_rcpts_succeeded();
    print "Successfully sent to @success}\n";

Convenience method which returns C<< $smtp->pipe_recipients()->{succeeded} >>

=item pipe_rcpts_failed ()

    $failed = $smtp->pipe_rcpts_failed();
    print "Failed sending to @$failed\n";

Convenience method which returns C<< $smtp->pipe_recipients()->{failed} >>

=back

=head1 DIAGNOSTICS

=over

=item C<< Last character not sent: %s >>

Could not send the final <CRLF>.<CRLF> to terminate a message (value of $!
is given).

=item C<< Server does not support PIPELINING, banner was "%s" >>

The server did not report the PIPELININg extension in it's connection banner,
refusing to attempt a send via PIPELINING.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Net::SMTP::Pipelining requires no configuration files or environment variables.

=head1 DEPENDENCIES

Net::SMTP::Pipelining requires the following modules:

=over

=item *

version

=item *

Net::Cmd

=item *

Net::SMTP

=item *

IO::Socket

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-net-smtp-pipelining@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

Caveat:
While Net::SMTP::Pipelining is a wonderful piece of software (I'd say that,
wouldn't I?), you should consider whether it is the right thing for you. In
general, when sending email, you should not have to worry about the details
of the send process but rather push it out to a mail server near you as simply
as possible. That mail server can then take care of transmitting your email
to its destination (possibly using pipelining), and you won't have to worry
about it. Of course, if you're writing your own mail server in Perl or have any
other reason to want to use this module, you're more than welcome.

=head1 ACKNOWLEDGEMENTS

Many thanks to David Cantrell for letting me test on his FreeBSD/OS X boxes, that
helped shake out at least one bug. Also thanks to the good folks at
http://www.perlmonks.org, especially mr_mischief.

=head1 AUTHOR

Marc Beyer  C<< <japh@tirwhan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009-2013, Marc Beyer C<< <japh@tirwhan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
