package Net::Stomp::MooseHelpers::TraceOnly;
$Net::Stomp::MooseHelpers::TraceOnly::VERSION = '3.0';
{
  $Net::Stomp::MooseHelpers::TraceOnly::DIST = 'Net-Stomp-MooseHelpers';
}
use Moose::Role;
use Net::Stomp::Frame;
use namespace::autoclean;

# ABSTRACT: role to replace the Net::Stomp connection with tracing code

with 'Net::Stomp::MooseHelpers::TracerRole';


has trace => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

around '_build_connection' => sub {
    my ($orig,$self,@etc) = @_;

    my $conn = Net::Stomp::MooseHelpers::TraceOnly::Connection->new({
        _tracing_object => $self,
    });
    return $conn;
};

package Net::Stomp::MooseHelpers::TraceOnly::Connection;
$Net::Stomp::MooseHelpers::TraceOnly::Connection::VERSION = '3.0';
{
  $Net::Stomp::MooseHelpers::TraceOnly::Connection::DIST = 'Net-Stomp-MooseHelpers';
}{
use Moose;
use Carp;
use Log::Any;
require Net::Stomp;

# newer Net::Stomp have a logger, so we need one too
has logger => ( is => 'ro', lazy_build => 1 );
sub _build_logger { Log::Any->get_logger() }

has _tracing_object => ( is => 'rw' );

sub connect {
    my ($self) = @_;
    $self->session_id("$self-$$");
    return Net::Stomp::Frame->new({
        command => 'CONNECTED',
        headers => {
            session => $self->session_id,
        },
        body => '',
    });
}
sub subscribe { return 1 }
sub unsubscribe { return 1 }
sub ack { return 1 }
sub current_host { return 0 }
sub receipt_timeout { return undef }

has _last_frame => (
    is => 'rw',
);

sub receive_frame {
    my ($self) = @_;

    # hack to make send_with_receipt happy
    if ($self->_last_frame && $self->_last_frame->headers->{'receipt'}) {
        return Net::Stomp::Frame->new({
            command => 'RECEIPT',
            headers => {
                'receipt-id' => $self->_last_frame->headers->{'receipt'},
            },
            body => '',
        });
        $self->_last_frame(undef);
    }
    croak "This a Net::Stomp::MooseHelpers::TraceOnly::Connection, we don't talk to the network";
}

sub send_frame {
    my ($self,$frame,@etc) = @_;

    $self->_last_frame($frame);

    if (my $o=$self->_tracing_object) {
        $o->_save_frame($frame,'send');
    }

    return;
};

has serial => (
    isa => 'Int',
    is => 'rw',
    default => 0,
);
has session_id => (
    isa => 'Str',
    is => 'rw',
);

# let's just take the original methods, they'll work
*send = \&Net::Stomp::send;
*send_transactional = \&Net::Stomp::send_transactional;
*send_with_receipt = \&Net::Stomp::send_with_receipt;
*_get_next_transaction = \&Net::Stomp::_get_next_transaction;

__PACKAGE__->meta->make_immutable;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stomp::MooseHelpers::TraceOnly - role to replace the Net::Stomp connection with tracing code

=head1 VERSION

version 3.0

=head1 SYNOPSIS

  package MyThing;
  use Moose;with 'Net::Stomp::MooseHelpers::CanConnect';
  with 'Net::Stomp::MooseHelpers::TraceOnly';

  $self->trace_basedir('/tmp/stomp_dumpdir');

B<NOTE>: a C<CanConnect> consuming this role will never talk to the
network, and will C<die> if asked to receive frames.

=head1 DESCRIPTION

This module I<replaces> the connection object provided by
L<Net::Stomp::MooseHelpers::CanConnect> so that it writes to disk
every outgoing frame, I<without actually talking to the network>. It
will also C<die> if the connection is asked to receive frames.

The frames are written as they would be "on the wire" (no encoding
conversion happens), one file per frame. Each frame is written into a
directory under L</trace_basedir> with a name derived from the frame
destination.

=head1 ATTRIBUTES

=head2 C<trace_basedir>

The directory under which frames will be dumped. Accepts strings and
L<Path::Class::Dir> objects. If it's not specified, every frame will
generate a warning.

=begin Pod::Coverage

trace

connect
subscribe
unsubscribe
ack
receive_frame
send_frame
send

=end Pod::Coverage

1;

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
