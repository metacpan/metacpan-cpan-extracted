package Net::Async::AMQP::Server::Protocol;
$Net::Async::AMQP::Server::Protocol::VERSION = '2.000';
use strict;
use warnings;

=head1 NAME

Net::Async::AMQP::Server::Protocol

=head1 VERSION

version 2.000

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use curry;
use Net::Async::AMQP::Utils qw(amqp_frame_type);

=head2 new

=cut

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
}

=head2 write

=cut

sub write { my $self = shift; $self->{write}->(@_) }

=head2 on_read

=cut

sub on_read {
	my ($self, $buffer, $eof) = @_;
	return 0 unless length $$buffer >= length Net::AMQP::Protocol->header;

	$self->{initial_header} = substr $$buffer, 0, length Net::AMQP::Protocol->header, '';
	my ($proto, $version) = $self->{initial_header} =~ /^(AMQP)(....)/ or die "Invalid header received: " . sprintf "%v02x", $self->{initial_header};
	$self->debug_printf("Protocol $proto, version " . join '.', sprintf '%08x', unpack 'N1', $version);
	$self->can('startup');
}

=head2 startup

=cut

sub startup {
	my ($self, $buffer, $eof) = @_;
	my $frame = Net::AMQP::Frame::Method->new(
		channel => 0,
		method_frame => Net::AMQP::Protocol::Connection::Start->new(
			server_properties => {
			},
			mechanisms        => $self->auth_mechanisms,
			locale            => $self->locale,
		),
	);
    $frame = $frame->frame_wrap if $frame->isa("Net::AMQP::Protocol::Base");
    $frame->channel(0) unless defined $frame->channel;
	$self->write($frame->to_raw_frame);
    $self->push_pending(
        'Connection::StartOk' => $self->can('start_ok'),
        'Connection::Close'   => $self->can('conn_close'),
	);
	$self->can('conn_start');
}

sub auth_mechanisms { 'AMQPLAIN' }

sub locale { 'en_GB' }

=head2 push_pending

=cut

sub push_pending {
    my $self = shift;
    while(@_) {
        my ($type, $code) = splice @_, 0, 2;
        push @{$self->{pending}{$type}}, $code;
    }
    return $self;
}

=head2 remove_pending

=cut

sub remove_pending {
	my $self = shift;
    while(@_) {
        my ($type, $code) = splice @_, 0, 2;
		# This is the same as extract_by { $_ eq $code } @{$self->{pending}{$type}};,
		# but since we'll be calling it a lot might as well do it inline:
		splice
			@{$self->{pending}{$type}},
			$_,
			1 for grep {
				$self->{pending}{$type}[$_] eq $code
			} reverse 0..$#{$self->{pending}{$type}};
    }
    return $self;
}

=head2 next_pending

=cut

sub next_pending {
    my ($self, $type, $frame) = @_;
    $self->debug_printf("Check next pending for %s", $type);

    if(my $next = shift @{$self->{pending}{$type} || []}) {
		# We have a registered handler for this frame type. This usually
		# means that we've sent a frame and are awaiting a response.
		if(ref($next) eq 'ARRAY') {
			my ($f, @args) = @$next;
			$f->done(@args) unless $f->is_ready;
		} else {
			$next->($self, $frame, @_);
		}
	} else {
		# It's quite possible we'll see unsolicited frames back from
		# the server: these will typically be errors, connection close,
		# or consumer cancellation if the consumer_cancel_notify
		# option is set (RabbitMQ). We don't expect many so report
		# them when in debug mode.
		$self->debug_printf("We had no pending handlers for %s, raising as event", $type);
		$self->bus->invoke_event(
			unexpected_frame => $type, $frame
		);
	}
    $self
}

=head2 process_frame

=cut

sub process_frame {
    my ($self, $frame) = @_;
#	if(my $ch = $self->channel_by_id($frame->channel)) {
#		return $self if $ch->next_pending($frame);
#	}

    my $frame_type = amqp_frame_type($frame);

	# Basic::Deliver - we're delivering a message to a ctag
	# Frame::Header - header part of message
	# Frame::Body* - body content
    $self->debug_printf("Processing connection frame %s => %s", $self, $frame);

    $self->next_pending($frame_type, $frame);
	return $self;

    # Any channel errors will be represented as a channel close event
    if($frame_type eq 'Channel::Close') {
        $self->debug_printf("Channel was %d, calling close", $frame->channel);
        $self->channel_by_id($frame->channel)->on_close(
            $frame->method_frame
        );
        return $self;
    }


    return $self;
}

use Data::Dumper;

=head2 conn_start

=cut

sub conn_start {
	my ($self, $buffer, $eof) = @_;
	$self->debug_printf("Have " . length($$buffer) . " bytes of post-connect data");
	for my $frame (Net::AMQP->parse_raw_frames($buffer)) {
		$self->debug_printf(":: Frame $frame" . Dumper($frame));
		$self->process_frame($frame);
	}
	0;
}

=head2 start_ok

=cut

sub start_ok {
	my ($self, $frame) = @_;
	$self->debug_printf("Start okay:\n");
	my $method_frame = $frame->method_frame;
	$self->debug_printf("Auth:     " . $method_frame->mechanism);
	$self->debug_printf("Locale:   " . $method_frame->locale);
	$self->debug_printf("Response: " . $method_frame->response);
	$self->send_frame(
		Net::AMQP::Protocol::Connection::Tune->new(
			channel_max => 12 || $self->channel_max,
			frame_max   => $self->frame_max,
			heartbeat   => $self->heartbeat_interval,
		)
	);
    $self->push_pending(
        'Connection::TuneOk' => $self->can('tune_ok'),
	);
}

=head2 heartbeat_interval

=cut

sub heartbeat_interval { shift->{heartbeat_interval} //= 0 }

=head2 send_frame

=cut

sub send_frame {
    my $self = shift;
    my $frame = shift;
    my %args = @_;

    # Apply defaults and wrap as required
    $frame = $frame->frame_wrap if $frame->isa("Net::AMQP::Protocol::Base");
    $frame->channel($args{channel} // 0) unless defined $frame->channel;

    # Get bytes to send across our transport
    my $data = $frame->to_raw_frame;
    $self->write($data);

    $self;
}

=head2 bus

=cut

sub bus { $_[0]->{bus} ||= Mixin::Event::Dispatch::Bus->new }

=head2 frame_max

=cut

sub frame_max {
    my $self = shift;
    return $self->{frame_max} unless @_;

    $self->{frame_max} = shift;
    $self
}

=head2 tune_ok

=cut

sub tune_ok {
	my ($self, $frame) = @_;
	$self->debug_printf("Tune okay:");
	my $method_frame = $frame->method_frame;
	$self->debug_printf("Channels:  " . $method_frame->channel_max);
	$self->debug_printf("Max size:  " . $method_frame->frame_max);
	$self->debug_printf("Heartbeat: " . $method_frame->heartbeat);
    $self->push_pending(
        'Connection::Open' => $self->can('connection_open'),
        # 'Channel::Open' => $self->can('channel_open'),
	);
}

=head2 connection_open

=cut

sub connection_open {
	my ($self, $frame) = @_;
    $self->push_pending(
        'Channel::Open' => $self->can('channel_open'),
	);
	$self->send_frame(
		Net::AMQP::Protocol::Connection::OpenOk->new(
			reserved_1 => '',
		)
	);
}

=head2 channel_open

=cut

sub channel_open {
	my ($self, $frame) = @_;
    $self->push_pending(
        'Channel::Open' => $self->can('channel_open'),
	);
	my $method_frame = $frame->method_frame;
	my $id = $frame->channel;
	$self->debug_printf("Channel [%d] open request", $id);
	if(exists $self->{channels}{$id}) {
		$self->debug_printf("Channel [%d] already assigned, rejecting", $id);
		$self->send_frame(
			Net::AMQP::Protocol::Channel->new(
				reserved_1 => '',
			)
		);

	}

	{
		my $frame = Net::AMQP::Frame::Method->new(
			channel => $id,
			method_frame => Net::AMQP::Protocol::Channel::OpenOk->new(
				reserved_1 => '',
			)
		);
		$self->send_frame(
			$frame
		);
	}
}

=head2 conn_close

=cut

sub conn_close {
	my ($self, $frame) = @_;
	$self->debug_printf("Close request");
	my $method_frame = $frame->method_frame;
	$self->debug_printf("Code:   " . $method_frame->reply_code);
	$self->debug_printf("Text:   " . $method_frame->reply_text);
	$self->debug_printf("Class:  " . $method_frame->class_id);
	$self->debug_printf("Method: " . $method_frame->method_id);
	$self->send_frame(
		Net::AMQP::Protocol::Connection::CloseOk->new(
		)
	);
}

=head2 debug_printf

=cut

sub debug_printf {
	my ($self, $fmt, @args) = @_;
	# strip CR/LF/FF
	$fmt =~ s/\v+/ /g;
	# warn sprintf "$fmt\n" => @args;
	$self
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Licensed under the same terms as Perl itself, with additional licensing
terms for the MQ spec to be found in C<share/amqp0-9-1.extended.xml>
('a worldwide, perpetual, royalty-free, nontransferable, nonexclusive
license to (i) copy, display, distribute and implement the Advanced
Messaging Queue Protocol ("AMQP") Specification').
