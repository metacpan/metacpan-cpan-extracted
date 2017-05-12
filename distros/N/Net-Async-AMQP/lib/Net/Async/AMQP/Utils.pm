package Net::Async::AMQP::Utils;
$Net::Async::AMQP::Utils::VERSION = '2.000';
use strict;
use warnings;

use parent qw(Exporter);

=head1 NAME

Net::Async::AMQP::Utils

=head1 VERSION

version 2.000

=head1 SYNOPSIS

=head1 DESCRIPTION

All functions are imported by default.

=cut

our @EXPORT_OK = our @EXPORT = qw(
	amqp_frame_info
	amqp_frame_type
);

my %extra = (
	'Connection::Start' => sub {
		sprintf 'AMQP %d.%d, { %s }, auth "%s", locales "%s"',
			$_->version_major // 0,
			$_->version_minor // 0,
			join(', ', map { $_ . ' = "' . ($_[0]->server_properties->{$_} // '') . '"' } keys %{$_->server_properties}),
			$_->mechanisms // '',
			$_->locales // ''
	},
	'Connection::StartOk' => sub {
		sprintf '{ %s }, auth "%s", response "%s", locale "%s"',
			join(', ', map { $_ . ' = "' . $_[0]->client_properties->{$_} . '"' } keys %{$_->client_properties}),
			$_->mechanism,
			$_->response,
			$_->locale
	},
	'Connection::Secure' => sub {
		sprintf 'challenge "%s"',
			$_->challenge
	},
	'Connection::SecureOk' => sub {
		sprintf 'response "%s"',
			$_->response
	},
	'Connection::Tune' => sub {
		sprintf 'channels %d, frame max %d, heartbeat %d',
			$_->channel_max,
			$_->frame_max,
			$_->heartbeat,
	},
	'Connection::TuneOk' => sub {
		sprintf 'channels %d, frame max %d, heartbeat %d',
			$_->channel_max,
			$_->frame_max,
			$_->heartbeat
	},
	'Connection::Open' => sub {
		sprintf 'vhost "%s"',
			$_->virtual_host
	},
	'Connection::Close' => sub {
		sprintf 'code %d, text "%s", class %d, method %d',
			$_->reply_code,
			$_->reply_text,
			$_->class_id,
			$_->method_id
	},
	'Channel::Flow' => sub {
		sprintf '%s',
			$_->active ? 'enable' : 'disable'
	},
	'Channel::Close' => sub {
		sprintf 'code %d, text "%s", class %d, method %d',
			$_->reply_code,
			$_->reply_text,
			$_->class_id,
			$_->method_id
	},
	'Exchange::Declare' => sub {
		sprintf 'exchange "%s", type "%s", passive = %s, durable = %s, auto-delete = %s, internal = %s, nowait = %s, arguments { %s }',
			$_->exchange,
			$_->type,
			$_->passive ? 'yes' : 'no',
			$_->durable ? 'yes' : 'no',
			$_->auto_delete ? 'yes' : 'no',
			$_->internal ? 'yes' : 'no',
			$_->nowait ? 'yes' : 'no',
			$_->arguments ? join(', ', map { $_ . ' = "' . $_[0]->arguments->{$_} . '"' } keys %{$_->arguments}) : '',
	},
	'Exchange::Delete' => sub {
		sprintf 'exchange "%s", if-unused "%s", nowait = %s',
			$_->exchange,
			$_->if_unused ? 'yes' : 'no',
			$_->nowait ? 'yes' : 'no',
	},
	'Exchange::Bind' => sub {
		sprintf 'destination "%s", source "%s", rkey "%s", nowait = %s, arguments { %s }',
			$_->destination,
			$_->source,
			$_->routing_key,
			$_->nowait ? 'yes' : 'no',
			$_->arguments ? join(', ', map { $_ . ' = "' . $_[0]->arguments->{$_} . '"' } keys %{$_->arguments}) : '',
	},
	'Exchange::Unbind' => sub {
		sprintf 'destination "%s", source "%s", rkey "%s", nowait = %s, arguments { %s }',
			$_->destination,
			$_->source,
			$_->routing_key,
			$_->nowait ? 'yes' : 'no',
			$_->arguments ? join(', ', map { $_ . ' = "' . $_[0]->arguments->{$_} . '"' } keys %{$_->arguments}) : '',
	},
	'Queue::Declare' => sub {
		sprintf 'queue "%s", passive = %s, durable = %s, exclusive = %s, auto-delete = %s, nowait = %s, arguments { %s }',
			$_->queue,
			$_->passive ? 'yes' : 'no',
			$_->durable ? 'yes' : 'no',
			$_->exclusive ? 'yes' : 'no',
			$_->auto_delete ? 'yes' : 'no',
			$_->nowait ? 'yes' : 'no',
			$_->arguments ? join(', ', map { $_ . ' = "' . $_[0]->arguments->{$_} . '"' } keys %{$_->arguments}) : '',
	},
	'Queue::DeclareOk' => sub {
		sprintf 'queue "%s", messages %d, consumers %d',
			$_->queue,
			$_->message_count,
			$_->consumer_count,
	},
	'Queue::Bind' => sub {
		sprintf 'queue "%s", exchange "%s", rkey "%s", nowait = %s, arguments { %s }',
			$_->queue,
			$_->exchange,
			$_->routing_key,
			$_->nowait ? 'yes' : 'no',
			$_->arguments ? join(', ', map { $_ . ' = "' . $_[0]->arguments->{$_} . '"' } keys %{$_->arguments}) : '',
	},
	'Queue::Unbind' => sub {
		sprintf 'queue "%s", exchange "%s", rkey "%s", nowait = %s, arguments { %s }',
			$_->queue,
			$_->exchange,
			$_->routing_key,
			$_->nowait ? 'yes' : 'no',
			$_->arguments ? join(', ', map { $_ . ' = "' . $_[0]->arguments->{$_} . '"' } keys %{$_->arguments}) : '',
	},
	'Queue::Delete' => sub {
		sprintf 'queue "%s", if-unused = %s, if-empty = %s, nowait = %s',
			$_->queue,
			$_->if_unused ? 'yes' : 'no',
			$_->if_empty ? 'yes' : 'no',
			$_->nowait ? 'yes' : 'no',
	},
	'Queue::DeleteOk' => sub {
		sprintf 'messages %d',
			$_->message_count,
	},
	'Basic::Qos' => sub {
		sprintf 'size %d, count %d, global = %s',
			$_->prefetch_size,
			$_->prefetch_count,
			$_->global ? 'yes' : 'no',
	},
	'Basic::Consume' => sub {
		sprintf 'queue "%s", ctag "%s", no-local = %s, no-ack = %s, exclusive = %s, nowait = %s, arguments { %s }',
			$_->queue,
			$_->consumer_tag,
			$_->no_local ? 'yes' : 'no',
			$_->no_ack ? 'yes' : 'no',
			$_->exclusive ? 'yes' : 'no',
			$_->nowait ? 'yes' : 'no',
			$_->arguments ? join(', ', map { $_ . ' = "' . $_[0]->arguments->{$_} . '"' } keys %{$_->arguments}) : '',
	},
	'Basic::ConsumeOk' => sub {
		sprintf 'ctag "%s"',
			$_->consumer_tag,
	},
	'Basic::Cancel' => sub {
		sprintf 'ctag "%s", nowait = %s',
			$_->consumer_tag,
			$_->nowait ? 'yes' : 'no',
	},
	'Basic::CancelOk' => sub {
		sprintf 'ctag "%s"',
			$_->consumer_tag
	},
	'Basic::Return' => sub {
		sprintf 'code %d, text "%s", exchange "%s", rkey "%s"',
			$_->reply_code,
			$_->reply_text,
			$_->exchange,
			$_->routing_key
	},
	'Basic::Deliver' => sub {
		sprintf 'ctag "%s", dtag %s, redelivered = %s, exchange "%s", rkey "%s"',
			$_->consumer_tag,
			$_->delivery_tag,
			$_->redelivered ? 'yes' : 'no',
			$_->exchange,
			$_->routing_key
	},
	'Basic::Ack' => sub {
		sprintf 'dtag %s, multiple = %s',
			$_->delivery_tag,
			$_->multiple ? 'yes' : 'no',
	},
);

=head2 amqp_frame_info

Returns a string with information about the given AMQP frame.

=cut

sub amqp_frame_info($) {
	my ($frame) = @_;
	my $type = amqp_frame_type($frame);
	my $txt = $type;
	$txt .= ', channel ' . $frame->channel if $frame->channel;
	if($frame->can('method_frame') && (my $method_frame = $frame->method_frame)) {
		$txt .= " " . $extra{$type}->($method_frame, $frame) for grep exists $extra{$type}, $method_frame;
	}
	return $txt;
}

{ # We cache the lookups since they're unlikely to change during the application lifecycle

my %types;

=head2 amqp_frame_type

Takes the following parameters:

=over 4

=item * $frame - the L<Net::AMQP::Frame> instance

=back

Returns string representing type, typically the base class with Net::AMQP::Protocol prefix removed.

=cut

sub amqp_frame_type {
	my ($frame) = @_;
	return 'Header' if $frame->isa('Net::AMQP::Frame::Header');
	return 'Heartbeat' if $frame->isa('Net::AMQP::Frame::Heartbeat');
	return 'Unknown' unless $frame->can('method_frame');

	my $method_frame = shift->method_frame;
	my $ref = ref $method_frame;
	return $types{$ref} if exists $types{$ref};
	my $re = qr/^Net::AMQP::Protocol::([^:]+::[^:]+)$/;
	my ($frame_type) = grep /$re/, Class::ISA::self_and_super_path($ref);
	($frame_type) = $frame_type =~ $re;
	$types{$ref} = $frame_type;
	return $frame_type;
}
}

{
my %amqp_codes = (
	200 => { message => 'replysuccess', description => 'Indicates that the method completed successfully. This reply code is reserved for future use the current protocol design does not use positive confirmation and reply codes are sent only in case of an error.' },
	311 => { message => 'contenttoolarge', type => 'channel', description => 'The client attempted to transfer content larger than the server could accept at the present time. The client may retry at a later time.' },
	313 => { message => 'noconsumers', type => 'channel', description => 'When the exchange cannot deliver to a consumer when the immediate flag is set. As a result of pending data on the queue or the absence of any consumers of the queue.' },
	320 => { message => 'connectionforced', type => 'connection', description => 'An operator intervened to close the connection for some reason. The client may retry at some later date.' },
	402 => { message => 'invalidpath', type => 'connection', description => 'The client tried to work with an unknown virtual host.' },
	403 => { message => 'accessrefused', type => 'channel', description => 'The client attempted to work with a server entity to which it has no access due to security settings.' },
	404 => { message => 'notfound', type => 'channel', description => 'The client attempted to work with a server entity that does not exist.' },
	405 => { message => 'resourcelocked', type => 'channel', description => 'The client attempted to work with a server entity to which it has no access because another client is working with it.' },
	406 => { message => 'preconditionfailed', type => 'channel', description => 'The client requested a method that was not allowed because some precondition failed.' },
	501 => { message => 'frameerror', type => 'connection', description => 'The sender sent a malformed frame that the recipient could not decode.  This strongly implies a programming error in the sending peer.' },
	502 => { message => 'syntaxerror', type => 'connection', description => 'The sender sent a frame that contained illegal values for one or more fields.  This strongly implies a programming error in the sending peer.' },
	503 => { message => 'commandinvalid', type => 'connection', description => 'The client sent an invalid sequence of frames, attempting to perform an operation that was considered invalid by the server. This usually implies a programming error in the client.' },
	504 => { message => 'channelerror', type => 'connection', description => 'The client attempted to work with a channel that had not been correctly opened. This most likely indicates a fault in the client layer.' },
	505 => { message => 'unexpectedframe', type => 'connection', description => 'The peer sent a frame that was not expected, usually in the context of a content header and body. This strongly indicates a fault in the peer\'s content processing.' },
	506 => { message => 'resourceerror', type => 'connection', description => 'The server could not complete the method because it lacked sufficient resources. This may be due to the client creating too many of some type of entity.' },
	530 => { message => 'notallowed', type => 'connection', description => 'The client tried to work with some entity in a manner that is prohibited by the server, due to security settings or by some other criteria.' },
	540 => { message => 'notimplemented', type => 'connection', description => 'The client tried to use functionality that is not implemented in the server.' },
	541 => { message => 'internalerror', type => 'connection', description => 'The server could not complete the method because of an internal error. The server may require intervention by an operator in order to resume normal operations.' },
);

=head2 message_for_code

Returns the name (short message) corresponding to the given status code.

Example:

 message_for_code(540) => 'not implemented'

=cut

sub message_for_code {
	my ($code) = @_;
	$amqp_codes{$code}{message}
}

=head2 description_for_code

Returns the description (long message) corresponding to the given status code.

=cut

sub description_for_code {
	my ($code) = @_;
	$amqp_codes{$code}{description}
}

=head2 type_for_code

Returns the type for the given status code - typically "channel" or "connection".

=cut

sub type_for_code {
	my ($code) = @_;
	$amqp_codes{$code}{type}
}
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
