package Net::mbedTLS::Async;

use strict;
use warnings;

use feature 'current_sub';

use Promise::XS;
use Scalar::Util;

use Net::mbedTLS;

use constant {
    _READ_QUEUE_IDX => 1,
    _WRITE_QUEUE_IDX => 2,

    _POS_IDX => 2,
    _MIN_IDX => 3,
};

sub new {
    my ($class, $tls) = @_;

    return bless [
        $tls,
        [],
        [],
    ], $class;
}

=head2 promise() = I<OBJ>->shake_hands()

See the method of the same name in L<Net::mbedTLS::Connection>.
The returned promise resolves (empty) when the handshake is
complete.

=cut

sub shake_hands {
    my ($self) = @_;

    my $d = Promise::XS::deferred();

    my $tls = $self->[0];

    my $weak_self = $self;
    Scalar::Util::weaken($weak_self);

    sub {
        my $sub = __SUB__;

        $d->reject($@) if !eval {
            if ( my $ok = $tls->shake_hands() ) {
                $d->resolve();
            }
            else {
                $weak_self->_handle_nonfatal_error($tls, $sub);
            }

            1;
        };
    }->();

    return $d->promise()->finally(
        sub { $self->_unset_event_listener() },
    );
}

=head2 promise($count) = I<OBJ>->read_any( $OUTPUT_BUFFER )

Like C<read()> in L<Net::mbedTLS::Connection>.

=cut

sub read_any {
    splice @_, 1, 0, 1, 1;

    &_read;
}

=head2 promise() = I<OBJ>->read_all( $OUTPUT_BUFFER )

Like C<read_any()> above but won’t resolve until the entire
$OUTPUT_BUFFER has been written to. The returned promise
resolves empty.

=cut

sub read_all {
    splice @_, 1, 0, length $_[1], 0;

    &_read;
}

sub _read {
    my ($self, $min, $resolve_with_length_yn) = @_;

    my $tls = $self->[0];

    my $read_queue_ar = $self->[_READ_QUEUE_IDX];

    my $d = Promise::XS::deferred();

    push @$read_queue_ar, [ $d, \$_[2], 0, $min ];

    if (@$read_queue_ar == 1) {
        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        sub {
            my $sub = __SUB__;

            my $ok = eval {
                my $pos_sr = \$read_queue_ar->[0][_POS_IDX];

                if ( my $got = $tls->read(substr ${ $read_queue_ar->[0][1] }, $$pos_sr) ) {
                    $$pos_sr += $got;

                    if ($$pos_sr >= $read_queue_ar->[0][_MIN_IDX]) {
                        $read_queue_ar->[0][0]->resolve( $resolve_with_length_yn ? $$pos_sr : ());
                        shift @$read_queue_ar;
                    }

                    __SUB__->() if @$read_queue_ar;
                }
                else {
                    $weak_self->_handle_nonfatal_error($tls, $sub);
                }

                1;
            };

            if (!$ok) {
                my $err = $@;
                $_->[0]->reject($err) for splice @$read_queue_ar;
            }
        }->();
    }

    return $d->promise();
}

=head2 promise($count) = I<OBJ>->write_any( $OUTPUT_BUFFER )

Writes as much of $OUTPUT_BUFFER as possible. The returned promise
resolves with the number of bytes written. (It won’t resolve until
I<at least> one byte is written.)

=cut

sub write_any {
    push @_, 1, 1;
    &_write;
}

=head2 promise() = I<OBJ>->write_all( $OUTPUT_BUFFER )

Like C<write_any()>, but the returned promise won’t resolve until
all of $OUTPUT_BUFFER is sent. The returned promise resolves empty.

=cut

sub write_all {
    push @_, length $_[1], 0;
    &_write;
}

sub _write {
    my ($self, $payload, $min, $resolve_length_yn) = @_;

    my $d = Promise::XS::deferred();

    my $tls = $self->[0];

    my $write_queue_ar = $self->[_WRITE_QUEUE_IDX];
    push @$write_queue_ar, [ $d, $payload, 0, $min ];

    if (@$write_queue_ar == 1) {
        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        sub {
            my $sub = __SUB__;

            my $ok = eval {
                my $pos_sr = \$write_queue_ar->[0][_POS_IDX];

                if ( my $sent = $tls->write(substr ${ $write_queue_ar->[0][1] }, $$pos_sr) ) {
                    $$pos_sr += $sent;

                    if ($$pos_sr >= $write_queue_ar->[0][_MIN_IDX]) {
                        $write_queue_ar->[0][0]->resolve( $resolve_length_yn ? $$pos_sr : () );
                        shift @$write_queue_ar;
                    }

                    __SUB__->() if @$write_queue_ar;
                }
                else {
                    $weak_self->_handle_nonfatal_error($tls, $sub);
                }

                1;
            };

            if (!$ok) {
                my $err = $@;
                $_->[0]->reject($err) for splice @$write_queue_ar;
            }
        }->();
    }
}

sub _handle_nonfatal_error {
    my ($self, $tls, $sub_cb) = @_;

    die "need code ref" if !$sub_cb;

    my $fn = (caller 1)[3];

    if ($tls->error() eq Net::mbedTLS::ERR_SSL_WANT_READ) {
        $self->_set_event_listener(0, $sub_cb);
    }
    elsif ($tls->error() eq Net::mbedTLS::ERR_SSL_WANT_WRITE) {
        $self->_set_event_listener(1, $sub_cb);
    }
    else {
        die sprintf("$fn: Unknown mbedTLS error: %d", $tls->error());
    }
}

sub _unset_event_listener { }

sub _TLS { $_[0][0] }

sub DESTROY {
    my ($self) = @_;

    warn "DESTROYing $self at global destruction!\n" if ${^GLOBAL_PHASE} eq 'DESTRUCT';
}

1;
