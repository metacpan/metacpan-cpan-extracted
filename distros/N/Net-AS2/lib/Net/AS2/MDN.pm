package Net::AS2::MDN;
use strict;
use warnings qw(all);

=head1 NAME

Net::AS2::MDN - AS2 Message Deposition Notification

=head1 SYNOPSIS

    ### Sending Message and got a Sync MDN
    my $mdn = $as2->send($body, Type => 'application/xml', MessageId => 'my-message-id-12345@localhost')

    if (!$mdn->is_success) {
        print STDERR $mdn->description;
    }

=head1 PUBLIC INTERFACE

=cut
 
use Carp;
use MIME::Parser;
use MIME::Entity;
use Scalar::Util qw(blessed);

my $crlf = "\x0d\x0a";

=head2 Constructor

=over 4

=item $mdn = Net::AS2::MDN->create_success($message)

=item $mdn = Net::AS2::MDN->create_success($message, $plain_text)

Create an C<Net::AS2::MDN> indicating processed with transaction information 
provided by C<Net::AS2::Message>. Optionally with a human readable text.

=cut

sub create_success
{
    my ($class, $message, $plain_text) = @_;

    my $self = $class->_create_from_message($message, 'Message is received successfully.', $plain_text);
    $self->{success} = 1;
    return bless ($self, ref($class) || $class);
}

=item $mdn = Net::AS2::MDN->create_warning($message, $status_text)

=item $mdn = Net::AS2::MDN->create_warning($message, $status_text, $plain_text)

Create an C<Net::AS2::MDN> indicating processed with warnings with transaction 
information provided by C<Net::AS2::Message>. Optionally with a human readable text.

Status text is required and will goes to the C<Disposition> line. 
It is limited to printable ASCII.

=cut

sub create_warning
{
    my ($class, $message, $status_text, $plain_text) = @_;

    my $self = $class->_create_from_message($message, $status_text, $plain_text);
    $self->{success} = 1;
    $self->{warning} = 1;
    return $self
}

=item $mdn = Net::AS2::MDN->create_failure($message, $status_text)

=item $mdn = Net::AS2::MDN->create_failure($message, $status_text, $plain_text)

Create an C<Net::AS2::MDN> indicating failed/failure status with transaction 
information provided by C<Net::AS2::Message>. Optionally with a human readable text.

Status text is required and will goes to the C<Disposition> line. 
It is limited to printable ASCII.

=cut

sub create_failure
{
    my ($class, $message, $status_text, $plain_text) = @_;

    my $self = $class->_create_from_message($message, $status_text, $plain_text);
    $self->{failure} = 1;
    return $self
}

=item $mdn = Net::AS2::MDN->create_error($message, $status_text)

=item $mdn = Net::AS2::MDN->create_error($message, $status_text, $plain_text)

Create an C<Net::AS2::MDN> indicating processed/error status with transaction 
information provided by C<Net::AS2::Message>. Optionally with a human readable text.

Status text is required and will goes to the C<Disposition> line. 
It is limited to printable ASCII.

=cut

sub create_error
{
    my ($class, $message, $status_text, $plain_text) = @_;

    my $self = $class->_create_from_message($message, $status_text, $plain_text);
    $self->{error} = 1;
    return $self
}

=item $mdn = Net::AS2::MDN->create_from_unsuccessful_message($message)

Create a corresponding C<Net::AS2::MDN> for unsuccessful C<Net::AS2::Message> 
notice generated while receiving and decoding. Message's error text
will be used.

=cut

sub create_from_unsuccessful_message
{
    my ($class, $error_message) = @_;

    croak "error_message is not an Net::AS2::Message"
        unless blessed($error_message) && $error_message->isa('Net::AS2::Message');
    croak "message is not error"
        unless !$error_message->is_success;

    my $self = $class->_create_from_message(
        $error_message,
        $error_message->error_status_text,
        $error_message->error_plain_text);

    if ($error_message->is_error) {
        $self->{error} = 1;
    } else {
        $self->{failure} = 1;
    }
    return $self
}

sub _create_from_message
{
    my ($class, $message, $status_text, $plain_text) = @_;

    croak "message is not an Net::AS2::Message"
        unless blessed($message) && $message->isa('Net::AS2::Message');

    croak "status_text should be in English" unless 
        defined $status_text && $status_text =~ /^[\x20-\x7E^]+$/;

    my $self = {         
        status_text => $status_text,
        plain_text => $plain_text // $status_text,
        original_message_id => $message->message_id,
        mic_hash => $message->mic,
        mic_alg => defined $message->mic ? 'sha1' : undef,
        async_url => $message->async_url,
        should_sign => $message->should_mdn_sign,
    };
    return bless ($self, ref($class) || $class);
}

sub parse_mdn
{
    my ($class, $content) = @_;

    $class = ref($class) || $class;
    my $self = {};
    bless ($self, $class);

    $self->_parse_mdn($content);
    return $self;
}

sub create_error_mdn
{
    my ($class, $reason) = @_;

    $class = ref($class) || $class;
    my $self = { unparsable => 1, status_text => $reason };
    bless ($self, $class);

    return $self;
}

sub create_unparsable_mdn
{
    my ($class, $reason) = @_;

    $class = ref($class) || $class;
    my $self = { unparsable => 1, status_text => $reason };
    bless ($self, $class);

    return $self;
}

sub _parse_mdn
{
    my ($self, $content) = @_;

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    $parser->tmp_to_core(1);
    my $entity = $parser->parse_data($content);

    unless ($entity->mime_type =~ m{^multipart/report}) {
        $self->{status_text} = 'unexpected content type';
        $self->{unparsable} = 1;
        return;
    }

    my @parts = $entity->parts_DFS();

    $self->{plain_text} = '';
    my $disposition_text = '';
    foreach my $p (@parts) {
        my $bh = $p->bodyhandle;
        next unless $bh;
        if ($p->effective_type =~ m{^text/}i) {
            $self->{plain_text} = $bh->as_string;
        } elsif ($p->effective_type =~ m{^message/disposition-notification$}i) {
            $disposition_text = $bh->as_string;
        }
    }

    my %disposition;
    while ($disposition_text =~ /^ *(.*?) *: *(.*?) *(?:$crlf|$)/gm)
    {
        $disposition{lc($1)} = $2;
    }

    if (defined $disposition{'final-recipient'})
    {
        my $recipient = $disposition{'final-recipient'};
        if ($recipient =~ /^.*? *; *(.+)$/) {
            $self->{recipient} = Net::AS2::_parse_as2_id($1);
        }
    }
        
    $self->{original_message_id} = $disposition{'original-message-id'}
        if defined $disposition{'original-message-id'};

    if (defined $disposition{'received-content-mic'})
    {
        if ($disposition{'received-content-mic'} =~ m{^ *([A-Za-z0-9/=+]+) *, * (.+?) *$})
        {
            $self->{mic_hash} = $1;
            $self->{mic_alg} = $2;
        }
    }

    my $status_text = '';
    if (defined $disposition{'disposition'}) {
        if ($disposition{'disposition'} =~ m{; *(.*?) *$})
        {
            my $op = $1;
            if ($op =~ /: *(.*?) *$/) {
                $status_text = $1;
            }
            if ($op =~ /^processed$/i) {
                # All success
                $self->{success} = 1;
            } elsif ($op =~ m{^processed/warning}i) {
                # Warning
                $self->{success} = 1;
                $self->{warning} = 1;
            } elsif ($op =~ m{^failed/failure}i) {
                # Failed (Failure - EDI level)
                $self->{failure} = 1;
            } else { 
                # including processed/error
                # Failed (Content - protocol level, e.g. parse/decode/auth)
                $self->{error} = 1;
            }
        } else {
            $status_text = "disposition not parsable";
            $self->{unparsable} = 1;
        }
    } else {
        $status_text = "disposition not found";
            $self->{unparsable} = 1;
    }
    $self->{status_text} = $status_text;
}

=back

=head2 Methods

=over 4

=item $mdn->match($mic, $alg)

Verify the MDN MIC value with a pre-calculated one to make sure the receiving party got what we sent.

The MDN will be marked C<is_error> if the MICs do not match.

    $mdn->match($mic, 'sha1');
    if ($mdn->is_success) {
        # still success after comparing mic
    }

=cut

sub match_mic
{
    my ($self, $hash, $alg) = @_;
    return undef if !$self->is_success;
    unless (
        defined $self->{mic_hash} &&
        defined $hash && defined $alg &&
        $self->{mic_hash} eq $hash &&
        $self->{mic_alg} eq $alg)
    {
        $self->{success} = $self->{warning} = $self->{failure} = 0;
        $self->{error} = 1;
        $self->{status_text} .= "; MDN MIC validation failure";
        return 0;
    }
    return 1;
}

=item $mdn->is_success

Indicating a successfully processed status. (This returns true even with warning was presented)

=cut

sub is_success { return (shift)->{success}; }

=item $mdn->with_warning

Indicating the message was processed with warning.

=cut

sub with_warning { return (shift)->{warning}; }

=item $mdn->is_failure

Indicating a failed/failure status.

=cut

sub is_failure { return (shift)->{failure}; }

=item $mdn->is_error

Indicating a processed/error status

=cut

sub is_error { return (shift)->{error}; }

=item $mdn->is_unparsable

Indicating the MDN was unparsable

=cut

sub is_unparsable { return (shift)->{unparsable}; }

=item $mdn->status_text

The machine readable text follows the Disposition status

=cut

sub status_text { return (shift)->{status_text}; }

=item $mdn->async_url

The URL where the MDN was requested to sent to

=cut

sub async_url { return (shift)->{async_url}; }

=item $mdn->should_sign

Returns true if the MDN was requested to be signed

=cut

sub should_sign { return (shift)->{should_sign}; }

=item $mdn->recipient

Returns the AS2 name of the final recipient field of the MDN

=cut

sub recipient { 
    my ($self, $value) = @_; 
    $self->{recipient} = $value if @_ >= 2;
    return $self->{recipient}; 
}

=item $mdn->original_message_id

Returns the Original-Message-Id field of the MDN

=cut

sub original_message_id { return (shift)->{original_message_id}; }

=item $mdn->description

Returns a concatenated text message of the MDN status, machine readable text 
and human readable text.

=cut

sub description { 
    my $self = shift;
    return sprintf("%s; %s", 
        $self->{warning} ? 'processed/warning: ' . $self->{status_text} :
        $self->{success} ? 'processed' :
        $self->{failure} ? 'failed/failure: ' . $self->{status_text} :
        $self->{error} ? 'processed/error: ' . $self->{status_text} :
        'unparsable: ' . $self->{status_text}, 
        $self->{plain_text} // '');
}

=item $mdn->as_mime

Returns a multipart/report C<MIME::Entity> representation of the MDN

=cut

sub as_mime
{
    my $self = shift;

    my $quoted_recipient = Net::AS2::_encode_as2_id($self->{recipient});

    my $machine_report =
    join($crlf, (
        "Reporting-UA: Perl AS2",
        sprintf("Original-Recipient: rfc822; %s", $quoted_recipient),
        sprintf("Final-Recipient: rfc822; %s", $quoted_recipient),
        ( $self->{original_message_id} ?
            sprintf("Original-Message-ID: %s", $self->{original_message_id} ) :
            ()),
        sprintf("Disposition: automatic-action/MDN-sent-automatically; %s",
            $self->{warning} ? 'processed/warning: ' . $self->{status_text} :
            $self->{success} ? 'processed' :
            $self->{failure} ? 'failed/failure: ' . $self->{status_text} :
            'processed/error: ' . ($self->{status_text} // 'unknown-error')
        ),
        ( defined $self->{mic_hash} ?
            sprintf("Received-Content-MIC: %s, %s", $self->{mic_hash}, $self->{mic_alg}) :
            ())
    ));

    my $human_report_mime = new MIME::Entity->build(
        Type => 'text/plain', 
        Data => $self->{plain_text} // $self->{status_text} // (
            $self->{success} ? 
                'Message is received successfully.' :
                'Message could not be processed.'),
        Top => 0);
    $human_report_mime->head->delete('Content-disposition');
    my $machine_report_mime = new MIME::Entity->build(
        Type => 'message/disposition-notification', 
        Data => $machine_report, 
        Top => 0);
    $machine_report_mime->head->delete('Content-disposition');
    my $report_mime = new MIME::Entity->build(
        Type => 'multipart/report; report-type="disposition-notification"',
        'X-Mailer' => undef);
    $report_mime->add_part($human_report_mime);
    $report_mime->add_part($machine_report_mime);
    $report_mime->preamble([]);
    return $report_mime;
}

1;

=back

=head1 SEE ALSO

L<Net::AS2>, L<MIME::Entity>

