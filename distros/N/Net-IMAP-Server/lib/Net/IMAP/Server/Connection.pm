package Net::IMAP::Server::Connection;

use warnings;
use strict;

use base 'Class::Accessor';

use Coro;
use AnyEvent;
use Scalar::Util qw/weaken/;

use Net::IMAP::Server::Error;
use Net::IMAP::Server::Command;

__PACKAGE__->mk_accessors(
    qw(server coro io_handle model auth
       timer commands pending
       selected_read_only
       _selected

       temporary_messages temporary_sequence_map
       ignore_flags
       _session_flags

       last_poll previous_exists in_poll
       _unsent_expunge _unsent_fetch
       )
);

=head1 NAME

Net::IMAP::Server::Connection - Connection to a client

=head1 DESCRIPTION

Maintains all of the state for a client connection to the IMAP server.

=head1 METHODS

=head2 new

Creates a new connection; the server will take care of this step.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(
        {   @_,
            state           => "unauth",
            _unsent_expunge => [],
            _unsent_fetch   => {},
            last_poll       => time,
            commands        => 0,
            coro            => $Coro::current,
            _session_flags  => {},
        }
    );
    $self->update_timer;
    return $self;
}

=head2 server

Returns the L<Net::IMAP::Server> that this connection is on.

=head2 coro

Returns the L<Coro> process associated with this connection.  For
things interacting with this connection, it will probably be the
current coroutine, except for interactions coming from event loops.

=head2 io_handle

Returns the IO handle that can be used to read from or write to the
client.

=head2 model

Gets or sets the L<Net::IMAP::Server::DefaultModel> or descendant
associated with this connection.  Note that connections which have not
authenticated yet do not have a model.

=head2 auth

Gets or sets the L<Net::IMAP::Server::DefaultAuth> or descendant
associated with this connection.  Note that connections which have not
authenticated yet do not have an auth object.

=cut

sub auth {
    my $self = shift;
    if (@_) {
        $self->{auth} = shift;
        $self->server->model_class->require || $self->log(1, $@);
        $self->update_timer;
        $self->model(
            $self->server->model_class->new( { auth => $self->{auth} } ) );
    }
    return $self->{auth};
}

=head2 client_id

When called with no arguments, returns a hashref of identifying
information provided by the client.  When key-value pairs are
provided, sets the client properties.  See RFC 2971.

=cut

sub client_id {
    my $self = shift;
    if (@_ > 1) {
        $self->{client} = {%{$self->{client} || {}}, @_};
    }
    return $self->{client} || {};
}

=head2 selected [MAILBOX], [READ_ONLY]

Gets or sets the currently selected mailbox for this connection.
Changing mailboxes triggers the sending of untagged notifications to
the client, as well as calling L<Net::IMAP::Server::Mailbox/close> and
L<Net::IMAP::Server::Mailbox/select>.

=cut

sub selected {
    my $self = shift;
    my ($mailbox, $read_only) = @_;

    # This is just being called as a getter
    return $self->_selected unless @_;

    # This is a setter, but isn't actually changing the mailbox, nor
    # changing the read-only-ness.
    return $self->_selected if ($mailbox || "") eq ($self->_selected || "")
        and ($self->selected_read_only || 0) == ($read_only || 0);

    # Otherwise, flush any untagged messages, close the old, and open
    # the new.
    $self->send_untagged;
    $self->_selected->close if $self->_selected;
    $self->_selected( $mailbox );
    if ($self->_selected) {
        $self->selected_read_only( $read_only );
        $self->_selected->select;
    }

    return $self->_selected;
}

=head2 selected_read_only

Returns true of the currently selected mailbox has been forced into
read-only mode.  Note that the mailbox may be read-only for other
reasons, so checking L<Net::IMAP::Server::Mailbox/read_only> is
suggested instead.

=head2 greeting

Sends out a one-line untagged greeting to the client.

=cut

sub greeting {
    my $self = shift;
    $self->untagged_response('OK IMAP4rev1 Server');
}

=head2 handle_lines

The main line handling loop.  Since we are using L<Coro>, this cedes
to other coroutines whenever we block, given them a chance to run.  We
additionally cede after handling every command.

=cut

sub handle_lines {
    my $self = shift;
    $self->coro->prio(-4);

    eval {
        $self->greeting;
        while ( $self->io_handle and $_ = $self->io_handle->getline() ) {
            $self->handle_command($_);
            $self->commands( $self->commands + 1 );
            if (    $self->is_unauth
                and $self->server->unauth_commands
                and $self->commands >= $self->server->unauth_commands )
            {
                $self->out(
                    "* BYE Don't noodle around so much before logging in!");
                last;
            }
            $self->update_timer;
            cede;
        }

        $self->log( 4,
            "-(@{[$self]},@{[$self->auth ? $self->auth->user : '???']},@{[$self->is_selected ? $self->selected->full_path : 'unselected']}): Connection closed by remote host"
        );
    };
    my $err = $@;
    $self->log(1, $err)
        if $err and not( $err eq "Error printing\n" or $err eq "Timeout\n" );
    eval { $self->out("* BYE Idle timeout; I fell asleep.") if $err eq "Timeout\n"; };
    $self->close;
}

=head2 update_timer

Updates the inactivity timer.

=cut

sub update_timer {
    my $self = shift;
    $self->timer(undef);
    my $weakself = $self;
    weaken($weakself);
    my $timeout = sub {
        $weakself->coro->throw("Timeout\n");
        $weakself->coro->ready;
    };
    if ( $self->is_unauth and $self->server->unauth_idle ) {
        $self->timer( AnyEvent->timer( after => $self->server->unauth_idle, cb => $timeout ) );
    } elsif ( $self->server->auth_idle ) {
        $self->timer( AnyEvent->timer( after => $self->server->auth_idle, cb => $timeout ) );
    }
}

=head2 timer [AnyEvent watcher]

Returns the L<AnyEvent> watcher in charge of the inactivity timer.

=head2 commands

Returns the number of client commands the connection has processed.

=head2 handle_command

Handles a single line from the client.  This is not quite the same as
handling a command, because of client literals and continuation
commands.  This also handles dispatch of client commands to
L<Net::IMAP::Server::Command> subclasses (see L</class_for>).

Any errors generated while running commands will cause a C<NO Server
error> to be sent to the client -- unless the error message starts
with C<NO> or c<BAD>, in which case it will be relayed to the client.

Returns the L<Net::IMAP::Server::Command> instance that was run, or
C<undef> if it was a continuation line or pending interactive command.

=cut

sub handle_command {
    my $self    = shift;
    my $content = shift;

    my $output = $content;
    $output =~ s/[\r\n]+$//;
    $self->log( 4,
        "C(@{[$self]},@{[$self->auth ? $self->auth->user : '???']},@{[$self->is_selected ? $self->selected->full_path : 'unselected']}): $output"
    );

    if ( $self->pending ) {
        $self->pending->($content);
        return;
    }

    my ( $id, $cmd, $options ) = $self->parse_command($content);
    return unless defined $id;

    my $handler = $self->class_for($cmd)->new(
        {   server      => $self->server,
            connection  => $self,
            options_str => $options,
            command_id  => $id,
            command     => $cmd
        }
    );
    return if $handler->has_literal;

    eval { $handler->run() if $handler->validate; };
    if ( my $error = $@ ) {
        if ($error eq "Timeout\n" or $error eq "Error printing\n") {
            die $error;
        } elsif ($error =~ /^NO (.*)/) {
            $handler->no_command($1);
        } elsif ($error =~ /^BAD (.*)/) {
            $handler->bad_command($1);
        } else {
            $handler->no_command("Server error");
            $self->log(1, $error);
        }
    }
    return $handler;
}

=head2 class_for COMMAND

Returns the package name that implements the given C<COMMAND>.  See
L<Net::IMAP::Server/add_command>.

=cut

sub class_for {
    my $self = shift;
    my $cmd = shift;
    my $classref = $self->server->command_class;
    my $cmd_class = $classref->{lc $cmd} || $classref->{$cmd} || $classref->{uc $cmd}
         || "Net::IMAP::Server::Command::$cmd";
    my $class_path = $cmd_class;
    $class_path =~ s{::}{/}g;

    $cmd_class->require();
    my $err = $@;
    if ($err and $err !~ /^Can't locate $class_path.pm in \@INC/) {
        $self->log(1, $@);
        $cmd_class = "Net::IMAP::Server::Error";
    }

    return $cmd_class->can('run') ? $cmd_class : "Net::IMAP::Server::Command";
}

=head2 pending

If a connection has pending state, contains the callback that will
receive the next line of input.

=cut

=head2 close

Shuts down this connection, also closing the model and mailboxes.

=cut

sub close {
    my $self = shift;
    if ( $self->io_handle ) {
        $self->io_handle->close;
        $self->io_handle(undef);
    }
    $self->timer( undef )  if $self->timer;
    $self->selected->close if $self->selected;
    $self->model->close    if $self->model;
    $self->server->connection(undef) if $self->server;
    $self->coro(undef);
}

=head2 parse_command LINE

Parses the line into the C<tag>, C<command>, and C<options>.  Returns
undef if parsing fails for some reason.

=cut

sub parse_command {
    my $self = shift;
    my $line = shift;
    $line =~ s/[\r\n]+$//;
    my $TAG = qr/([^\(\)\{ \*\%"\\\+}]+)/;
    unless ( $line =~ /^$TAG\s+(\w+)(?:\s+(.+?))?$/ ) {
        if ( $line !~ /^$TAG\s+/ ) {
            $self->out("* BAD Invalid tag");
        } else {
            $self->out("* BAD Null command ('$line')");
        }
        return undef;
    }

    my $id   = $1;
    my $cmd  = $2;
    my $args = $3 || '';
    $cmd = ucfirst( lc($cmd) );
    return ( $id, $cmd, $args );
}

=head2 is_unauth

Returns true if the connection is unauthenticated.

=cut

sub is_unauth {
    my $self = shift;
    return not defined $self->auth;
}

=head2 is_auth

Returns true if the connection is authenticated.

=cut

sub is_auth {
    my $self = shift;
    return defined $self->auth;
}

=head2 is_selected

Returns true if the connection has selected a mailbox.

=cut

sub is_selected {
    my $self = shift;
    return defined $self->selected;
}

=head2 is_encrypted

Returns true if the connection is protected by SSL or TLS.

=cut

sub is_encrypted {
    my $self   = shift;
    return $self->io_handle->is_ssl;
}

=head2 poll

Polls the currently selected mailbox, and resets the poll timer.

=cut

sub poll {
    my $self = shift;
    $self->selected->poll;
    $self->last_poll(time);
}

=head2 force_poll

Forces a poll of the selected mailbox the next chance we get.

=cut

sub force_poll {
    my $self = shift;
    $self->last_poll(0);
}

=head2 last_poll

Gets or sets the last time the selected mailbox was polled, in seconds
since the epoch.

=head2 previous_exists

The high-water mark of how many messages the client has been told are
in the mailbox.

=head2 send_untagged

Sends any untagged updates about the current mailbox to the client.

=cut

sub send_untagged {
    my $self = shift;
    my %args = (
        expunged => 1,
        @_
    );
    return unless $self->is_auth and $self->is_selected;

    if ( time >= $self->last_poll + $self->server->poll_every ) {
        # We record that we're in a poll so that EXPUNGE knows that
        # this connection should get a temporary message store if need
        # be.
        $self->in_poll(1);
        $self->poll;
        $self->in_poll(0);
    }

    for my $s ( keys %{ $self->_unsent_fetch } ) {
        my ($m) = $self->get_messages($s);
        $self->untagged_response(
                  $s 
                . " FETCH "
                . Net::IMAP::Server::Command->data_out(
                [ $m->fetch( [ keys %{ $self->_unsent_fetch->{$s} } ] ) ]
                )
        );
    }
    $self->_unsent_fetch( {} );

    if ( $args{expunged} ) {

# Make sure that they know of at least the existence of what's being expunged.
        my $max = 0;
        $max = $max < $_ ? $_ : $max for @{ $self->_unsent_expunge };
        $self->untagged_response("$max EXISTS")
            if $max > $self->previous_exists;

        # Send the expunges, clear out the temporary message store
        $self->previous_exists(
            $self->previous_exists - @{ $self->_unsent_expunge } );
        $self->untagged_response( map {"$_ EXPUNGE"}
                @{ $self->_unsent_expunge } );
        $self->_unsent_expunge( [] );
        $self->temporary_messages(undef);
    }

    # Let them know of more EXISTS
    my $expected = $self->previous_exists;
    my $now = @{ $self->temporary_messages || $self->selected->messages };
    $self->untagged_response( $now . ' EXISTS' ) if $expected != $now;
    $self->previous_exists($now);
}

=head2 get_messages STR

Parses and returns messages fitting the given sequence range.  This is
on the connection and not the mailbox because messages have
connection-dependent sequence numbers.

=cut

use constant SEQUENCE_TOKEN => qr/(?:\d+:\d+|\d+:\*|\*:\d+|\d+|\*)/;
use constant SEQUENCE_STRING => qr/^@{[SEQUENCE_TOKEN]}(,@{[SEQUENCE_TOKEN]})*$/;
sub get_messages {
    my $self = shift;
    my $str  = shift;

    my $messages = $self->temporary_messages || $self->selected->messages;

    my %ids;
    for ( split ',', $str ) {
        if (/^(\d+):(\d+)$/) {
            $ids{$_}++ for $2 > $1 ? $1 .. $2 : $2 .. $1;
        } elsif ( /^(\d+):\*$/ or /^\*:(\d+)$/ ) {
            $ids{$_}++ for @{$messages} + 0, $1 .. @{$messages} + 0;
        } elsif (/^(\d+)$/) {
            $ids{$1}++;
        } elsif (/^\*$/) {
            $ids{ @{$messages} + 0 }++;
        }
    }
    return grep {defined}
        map { $messages->[ $_ - 1 ] } sort { $a <=> $b } keys %ids;
}

=head2 sequence MESSAGE

Returns the sequence number for the given message.

=cut

sub sequence {
    my $self    = shift;
    my $message = shift;

    return $message->sequence unless $self->temporary_messages;
    return $self->temporary_sequence_map->{$message};
}

=head2 capability

Returns the current capability list for this connection, as a string.
Connections not under TLS or SSL always have the C<LOGINDISABLED>
capability, and no authentication capabilities.  The
L<Net::IMAP::Server/auth_class>'s
L<Net::IMAP::Server::DefaultAuth/sasl_provides> method is used to list
known C<AUTH=> types.

=cut

sub capability {
    my $self = shift;

    my $base = $self->server->capability;
    my @words = split " ", $base;

    # Skip STARTTLS if we're encrpyted
    @words = grep {$_ ne "STARTTLS"} @words
        if $self->is_encrypted;

    # If we're auth'd, no need to list any AUTH or LOGINDISABLED
    unless ($self->auth) {
        my $auth = $self->auth || $self->server->auth_class->new;
        my @auth = $auth->sasl_provides;
        unless ($self->is_encrypted) {
            # Lack of encrpytion makes us turn off all plaintext auth
            push @words, "LOGINDISABLED";
            @auth = grep {$_ ne "PLAIN"} @auth;
        }
        push @words, map {"AUTH=$_"} @auth;
    }

    return join(" ", @words);
}

=head2 log SEVERITY, MESSAGE

Defers to L<Net::IMAP::Server/log>.

=cut

sub log {
    my $self = shift;
    $self->server->log(@_);
}

=head2 untagged_response STRING

Sends an untagged response to the client; a newline ia automatically
appended.

=cut

sub untagged_response {
    my $self = shift;
    $self->out("* $_") for grep defined, @_;
}

=head2 out STRING

Sends the message to the client.  If the client's connection has
dropped, or the send fails for whatever reason, L</close> the
connection and then die, which is caught by L</handle_lines>.

=cut

sub out {
    my $self = shift;
    my $msg  = shift;
    if ( $self->io_handle and $self->io_handle->peerport ) {
        if ( $self->io_handle->print( $msg . "\r\n" ) ) {
            $self->log( 4,
                "S(@{[$self]},@{[$self->auth ? $self->auth->user : '???']},@{[$self->is_selected ? $self->selected->full_path : 'unselected']}): $msg"
            );
        } else {
            $self->close;
            die "Error printing\n";
        }
    } else {
        $self->close;
        die "Error printing\n";
    }
}

1;
