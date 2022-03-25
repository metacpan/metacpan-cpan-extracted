package Net::Async::Redis::Server::Connection;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '3.022'; # VERSION

=head1 NAME

Net::Async::Redis::Server::Connection - represents a single connection to a server

=head1 DESCRIPTION

Best to wait until the 2.000 release for this one.

=cut

use strict;
use warnings;

use Net::Async::Redis::Commands;

use Net::Async::Redis::Server::Database;

use Log::Any qw($log);

sub info {
    my ($self) = @_;
    my $h = $self->stream->read_handle;
    return {
        id          => $self->id,
        addr        => join(':', $h->sockhost, $h->sockport),
        fd          => $h->fileno,
        name        => $self->name,
        age         => int($self->age / 1000),
        idle        => int($self->idle_time / 1000),
        flags       => 'N',
        db          => $self->database_index,
        sub         => $self->subscription_count,
        psub        => $self->psubscription_count,
        multi       => $self->multi_count // -1,
        qbuf        => 0,
        'qbuf-free' => 32768,
        obl         => 0,
        oll         => 0,
        omem        => 0,
        events      => 'rw',
        cmd         => $self->last_command,
    }
}

sub age {
    my ($self) = @_;
    $self->server->time - $self->created_at
}

sub idle_time {
    my ($self) = @_;
    $self->server->time - $self->last_command_at
}

sub created_at { shift->{created_at} }
sub last_command_at { shift->{last_command_at} }
sub id { shift->{id} }
sub name { shift->{name} }
sub database_index { shift->{database_index} //= 0 }
sub subscription_count { shift->{subscription_count} }
sub psubscription_count { shift->{psubscription_count} }
sub multi_count { shift->{multi_count} }
sub last_command { shift->{last_command} // '' }

sub request { }

sub stream { shift->{stream} }

sub on_close {
    my ($self) = @_;
    $log->infof('Closing server connection');
    $self->server->client_disconnect($self);
}

sub protocol {
    my ($self) = @_;
    $self->{protocol} ||= do {
        require Net::Async::Redis::Protocol;
        Net::Async::Redis::Protocol->new(
            handler => $self->curry::weak::on_message
        )
    };
}

sub on_read {
    my ($self, $stream, $buffref, $eof) = @_;
    $log->tracef('Read %d bytes of data, EOF = %d', length($$buffref), $eof ? 1 : 0);
    $self->protocol->decode($buffref);
    0
}

sub on_message {
    my ($self, $msg) = @_;
    $log->debugf('Had message %s', $msg);
    my ($command, @data) = @$msg;
    my $db = $self->db;
    my $code = $db->can(lc $command);
    $self->{last_command} = $command;
    $self->{last_command_at} = $self->server->time;
    $log->tracef('Database method: %s', $code);
    (
        $code
        ? $code->($db, @data)
        : Future->done(qq{ERR unknown command '$command'})
    )->then(sub {
        my $data = shift;
        $self->stream->write(
            $self->protocol->encode($data)
        )
    }, sub {
        my $err = shift;
        $self->stream->write(
            $self->protocol->encode(
                qq{ERR failed to process '$command' - $err}
            )
        );
    })->retain;
}

sub db {
    my ($self) = @_;
    $self->{db} //= Net::Async::Redis::Server::Database->new(
        server => $self->server
    )
}

sub server { shift->{server} }

sub configure {
    my ($self, %args) = @_;
    if(exists $args{stream}) {
        my $stream = delete $args{stream};
        $self->add_child($stream);
        Scalar::Util::weaken($self->{stream} = $stream);
        $stream->configure(
            on_closed => $self->curry::weak::on_close,
            on_read   => $self->curry::weak::on_read,
        );
    }
    for (qw(server)) {
        Scalar::Util::weaken($self->{$_} = delete $args{$_}) if exists $args{$_};
    }
    for (qw(protocol id created_at)) {
        $self->{$_} = delete $args{$_} if exists $args{$_};
    }
    return $self->next::method(%args);
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    my ($method) = our $AUTOLOAD =~ /::([^:]+)$/;
    my $cmd = uc $method;
    if(Net::Async::Redis::Commands->can($method)) {
        $cmd =~ tr/_/ /;
        return $self->request->reply(ERR => 'Unimplemented command ' . $cmd);
    }
    return $self->request->reply(ERR => 'Unknown command ' . $cmd);
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth 2015-2022. Licensed under the same terms as Perl itself.

