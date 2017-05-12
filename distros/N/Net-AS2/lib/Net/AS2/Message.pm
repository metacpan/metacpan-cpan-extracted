package Net::AS2::Message;
use strict;
use warnings qw(all);

=head1 NAME

Net::AS2::Message - AS2 incoming message

=head1 SYNOPSIS

    ### Receiving Message and sending MDN
    my $message = $as2->decode_messages($headers, $post_body);
    if ($message->is_success) {
        print $message->content;
    }

=head1 PUBLIC INTERFACE

=cut

use Carp;

my $crlf = "\x0d\x0a";

sub new
{
    my ($class, $message_id, $async_url, $should_mdn_sign, $mic, $content) = @_;

    my $self = $class->_create_message($message_id, $async_url, $should_mdn_sign);
    $self->{success} = 1;
    $self->{content} = $content;
    $self->{mic} = $mic;
    return $self;
}

sub create_error_message
{
    my $self = _create_message(@_);
    $self->{error} = 1;
    return $self;
}

sub create_failure_message
{
    my $self = _create_message(@_);
    $self->{failure} = 1;
    return $self;
}

sub _create_message
{
    my ($class, $message_id, $async_url, $should_mdn_sign, $status_text, $plain_text) = @_;
    $class = ref($class) || $class;
    my $self = { 
        message_id => $message_id,
        async_url => $async_url,
        should_mdn_sign => $should_mdn_sign,
        status_text => $status_text,
        plain_text => $plain_text,
    };
    bless ($self, $class);
    return $self;
}

=head2 Constructor

=over 4

=item $msg = Net::AS2::Message->create_from_serialized_state($state)

Create an C<Net::AS2::Message> from a serialized state data returned from L<serialized_state>

=back

=cut

sub create_from_serialized_state
{
    my ($class, $state) = @_;

    my ($version, $status, $message_id, $mic, $async_url, $should_mdn_sign, $status_text, $plain_text)
        = split(/\n/, $state);
    croak "Net::AS2::Message state version is not supported" 
        unless defined $version && $version eq 'v1' && defined $plain_text;

    $class = ref($class) || $class;
    my $self = { 
        (
            $status eq '1' ? ( success => 1 ) : 
            $status eq '-1' ? ( error => 1 ) :
            ( failure => 1 )
        ),
        message_id => $message_id,
        mic => $mic,
        status_text => $status_text,
        should_mdn_sign => $should_mdn_sign,
        plain_text => $plain_text,
        async_url => $async_url
    };
    bless ($self, $class);

    return $self;
}

=head2 Methods

=over 4

=item $msg->is_success

Returns if the message was successfully parsed.
C<content> and C<mic> would be available.

=cut

sub is_success { return (shift)->{success}; }

=item $msg->is_error

Returns if the message was failed to parse. 
C<error_status_text> and C<error_plain_text> would be available.

=cut

sub is_error { return (shift)->{error}; }

=item $msg->is_failure

Returns if the message was parsed but failed in further processing, e.g. unsupported algorithm request .
C<error_status_text> and C<error_plain_text> would be available.

=cut

sub is_failure { return (shift)->{failure}; }

=item $msg->is_mdn_async

Returns if the partner wants to have the MDN sent in ASYNC.
C<async_url> would be available.

=cut

sub is_mdn_async { return (shift)->{async_url} ? 1 : 0; }

=item $msg->should_mdn_sign

Returns if the partner wants to have the MDN signed.

=cut

sub should_mdn_sign { return (shift)->{should_mdn_sign} ? 1 : 0; }

=item $msg->message_id

Returns the message id of this message. This could be undefined in some failure mode.

=cut

sub message_id { return (shift)->{message_id}; }

=item $msg->content

Returns the encoded content (binary) of the message. 
This is only defined when C<is_success> is true.

=cut

sub content { return (shift)->{content}; }

=item $msg->mic

Returns the SHA-1 MIC of the message.
This is only defined when C<is_success> is true.

=cut

sub mic { return (shift)->{mic}; }

=item $msg->error_status_text

Dedicated short error text that should goes into machine readable report in the MDN.

=cut

sub error_status_text { return (shift)->{status_text}; }

=item $msg->error_plain_text

Error text that goes into human readable report in the MDN.

=cut

sub error_plain_text { return (shift)->{plain_text}; }

=item $msg->async_url

Returns the url that partner wants us to send MDN to.

=cut

sub async_url { return (shift)->{async_url}; }

=item $msg->serialized_state

Returns the serialized state of this message. 

This is usually used for passing C<Net::AS2::Message> to another process for sending ASYNC MDN.

=cut

sub serialized_state {
    my $self = shift;
    return join("\n",
        'v1',
        $self->is_success ? 1 : $self->is_error ? -1 : -2,
        $self->{message_id},
        $self->{mic} // '',
        $self->{async_url} // '',
        $self->{should_mdn_sign} // '',
        $self->{status_text} // '', 
        $self->{plain_text} // ''
    );
}

# Check if notification options are supported
sub notification_options_check
{
    my ($options) = @_;
    foreach (split(/;/, $options))
    {
        my ($key, $value) = $_ =~ /^\s*(.+?)\s*=\s*(.+?)\s*$/;
        my ($requireness, @values) = lc($value) =~ /\s*(.+?)\s*(?:,|$)/g;

        if (lc($key) eq 'signed-receipt-protocol') {
            return 'requested MDN protocol is not supported' 
		unless 'pkcs7-signature' ~~ \@values;
        }
        if (lc($key) eq 'signed-receipt-micalg') {
            return 'requested MIC algorithm is not supported' 
		unless 'sha1' ~~ \@values;
        }
    }
    return undef;
}

1;

=back

=head1 SEE ALSO

L<Net::AS2>

