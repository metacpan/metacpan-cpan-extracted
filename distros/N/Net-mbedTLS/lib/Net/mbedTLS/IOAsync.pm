package Net::mbedTLS::IOAsync;

use strict;
use warnings;

use IO::Async::Handle;

use parent 'Net::mbedTLS::Async';

my %OBJ_LOOP;
my %OBJ_IO_HANDLE;

sub new {
    my $class = shift;
    my $loop = pop;

    my $self = $class->SUPER::new(@_);

    $OBJ_LOOP{$self} = $loop;

    return $self;
}

sub _set_event_listener {
    my ($self, $is_write, $sub_cb) = @_;

    my $handle_needs_add = !$OBJ_IO_HANDLE{$self};

    my $handle = $OBJ_IO_HANDLE{$self} ||= IO::Async::Handle->new(
        handle => $self->_TLS()->fh(),

        on_read_ready => $sub_cb,
        on_write_ready => $sub_cb,

        want_readready => !$is_write,
        want_writeready => $is_write,
    );

    $OBJ_LOOP{$self}->add($handle) if $handle_needs_add;
}

sub _unset_event_listener {
    my ($self) = @_;

    if ( my $handle = $OBJ_IO_HANDLE{$self} ) {
        $OBJ_LOOP{$self}->remove($handle);
    }

    return;
}

sub DESTROY {
    my ($self) = @_;

    delete $OBJ_LOOP{$self};
    delete $OBJ_IO_HANDLE{$self};

    $self->SUPER::DESTROY() if $self->can('SUPER::DESTROY');
}

1;
