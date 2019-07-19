package Net::Stomp::Producer::Transactional;
$Net::Stomp::Producer::Transactional::VERSION = '2.005';
{
  $Net::Stomp::Producer::Transactional::DIST = 'Net-Stomp-Producer';
}
use Moose;
extends 'Net::Stomp::Producer';
use Net::Stomp::Producer::Exceptions;
use MooseX::Types::Common::Numeric 'PositiveOrZeroInt';
use Try::Tiny;

# ABSTRACT: subclass of Net::Stomp::Producer with transaction-like behaviour


has _transactions => (
    is => 'ro',
    isa => 'ArrayRef[ArrayRef]',
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        in_transaction => 'count',
        _start_transaction => 'push',
        _drop_transaction => 'pop',
        _all_transactions => 'elements',
        _clear_transactions => 'clear',
    },
);

sub _current_transaction {
    my ($self) = @_;

    Net::Stomp::Producer::Exceptions::Transactional->throw()
          unless $self->in_transaction;

    return $self->_transactions->[-1];
}

sub _add_frames_to_transaction {
    my ($self,@frames) = @_;

    Net::Stomp::Producer::Exceptions::Transactional->throw()
          unless $self->in_transaction;

    push @{$self->_current_transaction},@frames;

    return;
}


sub txn_begin {
    my ($self) = @_;

    $self->_start_transaction([]);

    return;
}


sub txn_commit {
    my ($self) = @_;

    Net::Stomp::Producer::Exceptions::Transactional->throw()
          unless $self->in_transaction;

    my $messages = $self->_current_transaction;
    $self->_drop_transaction;
    if ($self->in_transaction) {
        # commit to the outer transaction
        $self->_add_frames_to_transaction(@$messages);
    }
    else {
        for my $f (@$messages) {
            $self->_really_send($f);
        }
    }

    return;
}


sub txn_rollback {
    my ($self) = @_;

    Net::Stomp::Producer::Exceptions::Transactional->throw()
          unless $self->in_transaction;

    $self->_drop_transaction;

    return;
}


override send => sub {
    my ($self,$destination,$headers,$body) = @_;

    my $actual_headers = $self->_prepare_message($destination,$headers,$body);

    if ($self->in_transaction) {
        $self->_add_frames_to_transaction($actual_headers);
    }
    else {
        $self->_really_send($actual_headers);
    }

    return;
};


sub txn_do {
    my ($self,$code) = @_;

    $self->txn_begin;
    try {
        $code->();
    }
    catch {
        $self->txn_rollback;
        die $_;
    };
    $self->txn_commit;
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stomp::Producer::Transactional - subclass of Net::Stomp::Producer with transaction-like behaviour

=head1 VERSION

version 2.005

=head1 SYNOPSIS

  my $p = Net::Stomp::Producer::Transactional->new({
      servers => [ { hostname => 'localhost', port => 61613, } ],
  });

  $p->txn_begin();

  $p->send('/queue/somewhere',
           { type => 'my_message' },
           'body contents');
  # nothing sent yet

  # some time later
  $p->txn_commit();
  # all messages are sent now

Also:

  $p->txn_do(sub{
    # do something...

    $p->send(@msg1);

    # do something else...

    $p->send(@msg2);
  });
  # all messages are sent now, unless an exception was thrown

=head1 DESCRIPTION

A subclass of L<Net::Stomp::Producer>, this class adds some
transaction-like behaviour.

If you call L</txn_begin>, the messages sent through this object will
be kept in memory instead of being actually sent to the STOMP
connection. They will be sent when you call L</txn_commit>,

There is also a L</txn_do> method, which takes a coderef and executes
it between a L</txn_begin> and a L</txn_commit>. If the coderef throws
an exception, the messages are forgotten.

Please remember that this has nothing to do with STOMP transactions,
nor with the L<Net::Stomp::Producer/transactional_sending>
attribute. We could, in future, re-implement this to delegate
transactional behaviour to the broker via STOMP's C<BEGIN> and
C<COMMIT> frames. At the moment we do everything client-side.

=head1 METHODS

=head2 C<in_transaction>

If true, we are inside a "transaction". You can change this with
L</txn_begin>, L</txn_commit> and L</txn_rollback>.

=head2 C<txn_begin>

Start a transaction, so that subsequent calls to C<send> or
C<transform_and_send> won't really send messages to the connection,
but keep them in memory.

You can call this method multiple times; the transaction will end (and
messages will be sent) when you call L</txn_commit> as many times as
you called C<txn_begin>.

Calling L</txn_rollback> will destroy the messages sent since the most
recent C<txn_begin>. In other words, transactions are properly
re-entrant.

=head2 C<txn_commit>

Commit the current transaction. If this was the outer-most
transaction, send all buffered messages.

If you call this method outside of a transaction, you'll get a
L<Net::Stomp::Producer::Exceptions::Transactional> exception.

=head2 C<txn_rollback>

Roll back the current transaction, destroying all messages "sent"
inside it.

If you call this method outside of a transaction, you'll get a
L<Net::Stomp::Producer::Exceptions::Transactional> exception.

=head2 C<send>

If not L</in_transaction>, send the message normally; otherwise, add
it to the in-memory buffer. See L<the base
method|Net::Stomp::Producer/send> for more details.

=head2 C<txn_do>

  $p->txn_do(sub {
    $p->send(@something);
  });

This method executes the given coderef between a L</txn_begin> and a
L</txn_commit>.

If the coderef throws an exception, L</txn_rollback> will be called,
and the exception re-thrown.

This method is re-entrant:

  $p->txn_do(sub {
    $p->send(@msg1);
    eval {
      $p->txn_do(sub {
        $p->send(@msg2);
        die "boom\n";
      });
    };
    $p->send(@msg3);
 });

The first and thind messages will be sent, the second one will not.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
