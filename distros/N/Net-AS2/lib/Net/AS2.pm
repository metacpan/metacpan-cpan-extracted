package Net::AS2;

use strict;
use warnings;
use autodie qw(:file :filesys);
our $VERSION = '1.0110'; # VERSION

=head1 NAME

Net::AS2 - AS2 Protocol implementation (RFC 4130) used in Electronic Data Exchange (EDI)

=head1 VERSION

This documentation is for AS2 Protocol Version 1.0.

=head1 SYNOPSIS

    ### Create an AS2 handler
    my $as2 = Net::AS2->new(
            MyId => 'alice',
            MyKey => '...RSA KEY in PEM...',
            MyCert => '...X509 Cert in PEM...'
            PartnerId => 'bob',
            CertificateDirectory => '/etc/AS2',
            PartnerCertFile => 'partner.certificate.file',
        );

    ### Sending Message (Sync MDN)
    my $mdn = $as2->send($body, Type => 'application/xml', MessageId => 'my-message-id-12345@localhost')

    ### Receiving MDN (Async MDN)
    my $mdn = $as2->decode_mdn($headers, $body);

    ### Receiving Message and sending MDN
    my $message = $as2->decode_message($headers, $post_body);

    if ($message->is_success) {
        print $message->content;
    }

    if ($message->is_mdn_async) {
        # ASYNC MDN is expected

        # stored the state for later use
        my $state = $message->serialized_state;

        # ...in another perl instance...
        my $message = Net::AS2::Message->create_from_serialized_state($state);
        $as2->send_async_mdn(
                $message->is_success ?
                    Net::AS2::MDN->create_success($message) :
                    Net::AS2::MDN->create_from_unsuccessful_message($message),
                'id-23456@localhost'
            );
    } else
    {
        # SYNC MDN is expected
        my ($new_headers, $mdn_body) = $as2->prepare_sync_mdn(
                $message->is_success ?
                    Net::AS2::MDN->create_success($message) :
                    Net::AS2::MDN->create_from_unsuccessful_message($message),
                'id-23456@localhost'
            );

        # ... Send headers and body ...
    }

=head1 DESCRIPTION

This is a class for handling AS2 (RFC 4130) communication - sending
message (optionally sign and encrypt), decoding Message Disposition
Notification. Receiving message and produce corresponding Message
Disposition Notification.

=head2 Protocol Introduction

AS2 is a protocol that defines communication over HTTP(s), and
optionally using SMIME as payload container, plus a mandated
multipart/report machine readable Message Disposition Notification
response (MDN).

When encryption and signature are used in SMIME payload (agree between
parties), as well as a signed MDN, the protocol offers data
confidentiality, data integrity/authenticity, non-repudiation of
origin, and non-repudiation of receipt over HTTP.

In AS2, MDN can only be signed but not encrypted, some MIME headers
are also exposed in the HTTP headers when sending. Use HTTPS if this
is a concerns.

Encryption and Signature are done in PKCS7/SMIME favor. The certificate
are usually exchanged out of band before establishing communication.
The certificates could be self-signed.

=head1 PUBLIC INTERFACE

=cut

use Carp;
use Crypt::SMIME;
use Digest::SHA;
use Email::Address;
use Encode;
use HTTP::Headers;
use HTTP::Request;
use LWP::UserAgent;
use MIME::Base64;
use MIME::Entity;
use MIME::Parser;
use Scalar::Util qw(blessed);
use Sys::Hostname;
use Scalar::Util qw(blessed);

use Net::AS2::HTTP;
use Net::AS2::MDN;
use Net::AS2::Message;

my $crlf = "\x0d\x0a";

=head2 Constructor

=over 4

=item $as2 = Net::AS2->new(%ARGS)

Create an AS2 handler. For preparing keys and certificates, see L<Preparing Certificates|Net::AS2::FAQ/Preparing Certificates>

The arguments are:

=over 4

=item MyId

I<Required.>
Your AS2 name. This will be used in the AS2-From header.

=item PartnerId

I<Required.>
The AS2 name of the partner. This will be used in the AS2-To header.

=item PartnerUrl

I<Required.>
The Url of partner where message would be sent to.

=item MyKey

I<Required.>
Our private key in PEM format.
Please includes the C<-----BEGIN RSA PRIVATE KEY-----> and C<-----END RSA PRIVATE KEY-----> line.

=item MyEncryptionKey, MySignatureKey

I<Optional.>
Different private keys could be used for encryption and signing. C<MyKey> will be used if not independently supplied.

=item MyCertificate

I<Required.>
Our corresponding certificate in PEM format.
Please includes the C<-----BEGIN CERTIFICATE-----> and C<-----END CERTIFICATE-----> line.

=item MyEncryptionCertificate, MySignatureCertificate

I<Optional.>
Different certificate could be used for encryption and signing. C<MyCertificate> will be used if not independently supplied.

=item PartnerCertificate

I<Required.>
Partner's certificate in PEM format.
Please includes the C<-----BEGIN CERTIFICATE-----> and C<-----END CERTIFICATE-----> line.

=item PartnerEncryptionCertificate, PartnerSignatureCertificate

I<Optional.>
Different certificate could be used for encryption and signing. If so, load them here.
L<PartnerCertificate> will be used if not independently supplied.

=item CertificateDirectory

A directory from which the private key and public certificate files
may be read from.

=item MyKeyFile

Sets C<MyKey> using a filename or pattern that contains the private key.

The files are located under C<CertificateDirectory>.

=item MyEncryptionKeyFile, MySignatureKeyFile

I<Optional.> Sets C<MyEncryptionKey> and/or C<MySignatureKey> using a
filename or pattern that contains the private keys. L<MyKeyFile> will
be used if not supplied.

=item MyCertificateFile

Sets C<MyCertificate> using a filename or pattern that contains the
corresponding public certificate.

The files are located under C<CertificateDirectory>.

=item MyEncryptionCertificateFile, MySignatureCertificateFile

I<Optional.> Sets C<MyEncryptionCertificate> and/or
C<MySignatureCertificate> using a filename or pattern that contains
the certificate files for encryption and signing. L<MyCertificateFile>
will be used if not independently supplied.

=item PartnerCertificateFile

Sets C<PartnerCertificate> using a filename or pattern that contains
the partner's public certificate.

The files are located under C<CertificateDirectory>.

=item PartnerEncryptionCertificateFile, PartnerSignatureCertificateFile

I<Optional.> Sets C<PartnerEncryptionCertificate> and/or
C<PartnerSignatureCertificate> using a filename or pattern that
contains the certificate files for encryption and signing, otherwise
L<PartnerCertificateFile> will be used

=item Encryption

I<Optional.>
Encryption alogrithm used in SMIME encryption operation. Only C<3des> is supported at this moment.

If left undefined, encryption is enabled and C<3des> would be used.
A false value must be specified to disable encryption.

If enabled, encryption would also be required for receiving.
Otherwise, encryption would be optional for receiving.

=item Signature

I<Optional.>
Signing alogrithm used in SMIME signing operation..

If left undefined, signing is enabled and C<sha1> will be used.
A false value must be specified to disable signature.

If enabled, signature would also be required for receiving.
Otherwise, signature would be optional for receiving.

Also, if enabled, signed MDN would be requested.

=item Mdn

I<Optional.>
The preferred MDN method - C<sync> or C<async>. The default is C<sync>.

=item MdnAsyncUrl

I<Required if Mdn is async>.
The URL where the async MDN should be sent back to the partner.

=item UserAgentClass

I<Optional.>
The class used to create the User Agent object.
If not given, it will default to L<Net::AS2::HTTP>.

=item Timeout

I<Optional.>
The timeout in seconds for HTTP communication. The default is 30.

This option is passed to C<UserAgentClass>.

=item UserAgent

I<Optional.>
User Agent name used in HTTP communication.

This option is passed to C<UserAgentClass>.

=back

=back

=cut

sub new
{
    my ($class, %opts) = @_;

    $class = ref($class) || $class;
    my $self = { %opts };
    bless ($self, $class);

    $self->_validations();

    my $s_e = $self->{_smime_enc} = Crypt::SMIME->new();

    eval {
        $s_e->setPrivateKey($self->{MyEncryptionKey}, $self->{MyEncryptionCertificate});
        1;
    } or do {
        croak "Unable to load private key/certificate for encryption: $@";
    };

    eval {
        $s_e->setPublicKey($self->{PartnerEncryptionCertificate});
        1;
    } or do {
        croak "Unable to load public certificate for encryption: $@";
    };

    if (
        $self->{MyEncryptionKey} eq $self->{MySignatureKey} &&
        $self->{MyEncryptionCertificate} eq $self->{MySignatureCertificate} &&
        $self->{PartnerEncryptionCertificate} eq $self->{PartnerSignatureCertificate}
    ) {
        $self->{_smime_sign} = $self->{_smime_enc};
    } else
    {
        my $s_s = $self->{_smime_sign} = Crypt::SMIME->new();

        eval {
            $s_s->setPrivateKey($self->{MySignatureKey}, $self->{MySignatureCertificate});
            1;
        } or do {
            croak "Unable to load private key/certificate for signature: $@";
        };

        eval {
            $s_s->setPublicKey($self->{PartnerSignatureCertificate});
            1;
        } or do {
            croak "Unable to load public certificate for signature: $@";
        };
    }

    return $self;
}

sub _validations
{
    my ($self) = @_;

    $self->{Encryption} = lc($self->{Encryption} // '3des');
    croak sprintf("encryption %s is not supported", $self->{Encryption})
        if $self->{Encryption} && $self->{Encryption} ne '3des';

    $self->{Signature} = lc($self->{Signature} // 'sha1');
    croak sprintf("signature %s is not supported", $self->{Signature})
        if $self->{Signature} && $self->{Signature} !~ qr{^sha-?(?:1|224|256|384|512)$};

    $self->_setup('My',      'Key');
    $self->_setup('My',      'Certificate');
    $self->_setup('Partner', 'Certificate');

    delete $self->{MyKey};
    delete $self->{MyCertificate};
    delete $self->{PartnerCertificate};

    foreach my $t (qw(
        MyId
        MyEncryptionKey MyEncryptionCertificate
        MySignatureKey MySignatureCertificate
        PartnerId
        PartnerEncryptionCertificate PartnerSignatureCertificate
        ))
    {
        croak "$t is not valid"
            unless defined $self->{$t} && $self->{$t} =~ /^[\r\n\x20-\x7E]+$/;
    }
    croak "PartnerUrl is invalid"
        unless defined $self->{PartnerUrl} && $self->{PartnerUrl} =~ m{^https?://[\x20-\x7E]+$};

    $self->{Mdn} = lc($self->{Mdn} // 'sync');
    croak sprintf("mdn %s is not supported", $self->{Mdn})
        unless grep { $_ eq lc($self->{Mdn}) } qw(sync async);

    if ($self->{Mdn} eq 'sync') {
        croak "MdnAsyncUrl is not required for synchronous Mdn"
          if defined $self->{MdnAsyncUrl};
    } else {
        croak "MdnAsyncUrl is invalid for asynchronous Mdn"
          if ($self->{MdnAsyncUrl} // '') !~ m{^https?://[\x20-\x7E]+$};
    }

    if (($self->{Signature} // '') =~ /^sha-?(\d+)/i) {
        $self->{Digest} = Digest::SHA->new($1);
    }
    else {
        $self->{Digest} = Digest::SHA->new(1);
    }

    $self->{UserAgentClass} //= "Net::AS2::HTTP";

    $self->create_useragent() or croak "cannot create $self->{UserAgentClass}";

    return;
}

# Internal routine that configures the private key(s) and certificates
# from the options that are passed in.
#
# The 'File' options allow for a glob pattern to be given.
#
# If multiple files match the pattern, the last matching file in a
# sorted list is used. This is to allow for file names containing dates
# that indicate their start and expiry dates.

sub _setup {
    my ($self, $prefix, $postfix) = @_;

    foreach my $type (('', 'Encryption', 'Signature')) {
        my $key_name = $prefix . $type . $postfix;
        my $key_file = $key_name . 'File';
        if (exists $self->{$key_file}) {
            $self->{$key_name} //= $self->_read_pattern($key_file);
        }
        next if $type eq '';

        $self->{$key_name} //= $self->{$prefix . $postfix};
    }
    return;
}

sub _read_pattern {
    my ($self, $key_file) = @_;

    my $pattern = $self->{$key_file} // '';

    # get latest matching file pattern
    my ($file) = reverse sort glob($self->{CertificateDirectory} . '/' . $pattern);

    croak "No file matching '$pattern'" unless -f $file;

    return _read_file($file);
}

sub _read_file {
    my($file) = @_;
    local $/ = undef;

    open my $fh, '<', $file;
    my $contents = scalar(<$fh>);
    close $fh;

    return $contents;
}

=head2 Methods

=over 4

=item $message = $as2->decode_message($headers, $content)

Decode the incoming HTTP request as AS2 Message.

C<$headers> is either an L<HTTP::Headers> compatible object or a hash
ref supplied in PSGI format, or C<\%ENV> in CGI mode.
C<$content> is the raw POST body of the request.

This method always returns a C<Net::AS2::Message> object and never dies.
The message could be successfully parsed, or contains corresponding error message.

Check the C<$message-E<gt>is_async> property and send the MDN accordingly.

If ASYNC MDN is requested, it should be sent after this HTTP request is returned
or in another thread - some AS2 server might block otherwise, YMMV. How to handle
this is out of topic.

=cut

sub decode_message
{
    my ($self, $headers, $content) = @_;

    $headers = $self->_http_headers($headers) if ref($headers) eq 'HASH';

    croak 'headers must be an HTTP::Headers compatible object'
      unless blessed($headers) && $headers->can('header_field_names');
    croak 'content is undefined'
      unless defined $content;

    my @new_prefix = (
        scalar($headers->header('Message-Id')),
        scalar($headers->header('Receipt-Delivery-Option')),
        0
    );

    # Validate Message-Id format
    eval {
        $new_prefix[0] = $self->get_message_id($new_prefix[0]);
    } or do {
        return Net::AS2::Message->create_error_message(@new_prefix, 'unexpected-processing-error', "Malformed AS2 Message, $@.");
    };
    if (defined($new_prefix[1]) && $new_prefix[1] !~ m{^https?://}) {
        $new_prefix[1] = undef;
        return Net::AS2::Message->create_failure_message(@new_prefix, 'Async transport other than http/https is not supported');
    }

    if (my $options = $headers->header('Disposition-Notification-Options')) {
        my $status = Net::AS2::Message::notification_options_check($options);
        return Net::AS2::Message->create_failure_message(@new_prefix, $status)
            if defined $status;
        $new_prefix[2] = 1;
    }

    my $content_type = $headers->content_type;
    my $version      = $headers->header('AS2-Version');
    my $from         = $headers->header('AS2-From');
    my $to           = $headers->header('AS2-To');

    unless (
        defined $content_type &&
        defined $new_prefix[0] &&
        defined $version &&
        defined $from &&
        defined $to)
    {
        return Net::AS2::Message->create_error_message(@new_prefix, 'unexpected-processing-error', 'Malformed AS2 Message, crucial headers are missing.');
    }

    if (
        $self->parse_as2_id($from) ne $self->{PartnerId} ||
        $self->parse_as2_id($to)   ne $self->{MyId}
    ) {
        return Net::AS2::Message->create_error_message(@new_prefix, 'authentication-failed', 'AS2-From or AS2-To is not expected');
    }

    my $is_content_raw = 1;

    my $raw_content    = $content;
    my $merged_headers = $headers->as_string($crlf) . $crlf;

    if ($self->{_smime_enc}->isEncrypted($merged_headers . $content))
    {
        # OpenSSL (Crypt::SMIME) in Windows cannot handle binary content,
        # convert the data to base64
        $content =
            "Content-Transfer-Encoding: base64$crlf" .
            $merged_headers .
            encode_base64($content);
        $is_content_raw = 0;

        $content = eval { $self->{_smime_enc}->decrypt($content); };
        return Net::AS2::Message->create_error_message(@new_prefix,
            'decryption-failed', 'Unable to decrypt the message')
            if $@;
    } else {
        return Net::AS2::Message->create_error_message(@new_prefix,
            'insufficient-message-security', 'Encryption is expected but the message is not encrypted')
            if $self->{Encryption};
    }

    if ($self->{_smime_sign}->isSigned($is_content_raw ? $merged_headers . $content : $content))
    {
        if ($is_content_raw) {
            $content =
                $merged_headers .
                $content;
            $is_content_raw = 0;
        }
        # OpenSSL (Crypt::SMIME) in Windows cannot handle binary content,
        # convert signature part to base64
        $content = _pkcs7_base64($content);
        $content = eval { $self->{_smime_sign}->check($content); };

        return Net::AS2::Message->create_error_message(@new_prefix,
            'insufficient-message-security', 'Unable to verify the signature')
            if $@;
    } else {
        return Net::AS2::Message->create_error_message(@new_prefix,
            'insufficient-message-security', 'Signature is expected but the message is not signed')
            if $self->{Signature};
    }

    my $mic = $self->_base64_digest($content);

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    $parser->tmp_to_core(1);
    my $entity = $parser->parse_data($is_content_raw ? $merged_headers . $content : $content);
    my $bh = $entity->bodyhandle;

    return Net::AS2::Message->create_failure_message(@new_prefix,
        'unexpected-processing-error',
        'MIME has no body (multipart message is not supported)')
        unless defined $bh;

    $content = $bh->as_string;
    my $filename = $entity->head->mime_attr('content-disposition.filename');
    return Net::AS2::Message->new(@new_prefix, $mic, $content, $self->{Signature}, $filename);
}

=item $mdn = $as2->decode_mdn($headers, $content)

Decode the incoming HTTP request as AS2 MDN.

C<$headers> is either an L<HTTP::Headers> compatible object or a hash
ref supplied in PSGI format, or C<\%ENV> in CGI mode.
C<$content> is the raw POST body of the request.

This method always returns a C<Net::AS2::MDN> object and never dies.
The MDN could be successfully parsed, or contains unparsable error details
if it is malformed, or signature could not be verified.

C<$mdn-E<gt>match_mic($content_mic)> should be called afterward with the
pre-calculated MIC from the outgoing message to verify the correctness
of the MIC.

=cut

sub decode_mdn
{
    my ($self, $headers, $content) = @_;

    $headers = $self->_http_headers($headers) if ref($headers) eq 'HASH';

    croak 'headers must be an HTTP::Headers compatible object'
      unless blessed($headers) && $headers->can('header_field_names');
    croak "content is undefined"
      unless defined $content;

    my $content_type = $headers->content_type;
    my $message_id   = $headers->header('Message-Id');
    my $version      = $headers->header('AS2-Version');
    my $from         = $headers->header('AS2-From');
    my $to           = $headers->header('AS2-To');

    unless (
        defined $content_type &&
        defined $message_id   &&
        defined $version &&
        defined $from &&
        defined $to)
    {
        return Net::AS2::MDN->create_unparsable_mdn('Malformed AS2 MDN, crucial headers are missing.')
    }

    if (
        $self->parse_as2_id($from) ne $self->{PartnerId} ||
        $self->parse_as2_id($to)   ne $self->{MyId}
    ) {
        return Net::AS2::MDN->create_unparsable_mdn('AS2-From or AS2-To is not expected')
    }

    my $merged_headers = $headers->as_string($crlf) . $crlf;

    $content =
        $merged_headers .
        $content;

    return $self->_parse_mdn($content);
}

=item ($headers, $content) = $as2->prepare_sync_mdn($mdn, $message_id)

Returns the headers and content to be sent in a HTTP response for a sync MDN.

The MDN is usually created after an incoming message is received, with
C<Net::AS2::MDN-E<gt>create_success> or C<Net::AS2::MDN-E<gt>create_from_unsuccessful_message>.

The headers are in arrayref format in PSGI response format.
The content is raw and ready to be sent.

For CGI, it should be sent like this:

    my ($headers, $content) = $as2->prepare_sync_mdn($mdn, $message_id);

    my $mh = '';
    for (my $i = 0; $i < scalar @{$headers}; $i += 2)
    {
        $mh .= $headers->[$i] . ': ' . $headers->[$i+1] . "\x0d\x0a";
    }

    binmode(STDOUT);
    print $mh . "\x0d\x0a" . $content;

If message id not specified, a random one will be generated.

=cut

sub prepare_sync_mdn
{
    my ($self, $mdn, $message_id) = @_;

    $message_id = $self->get_message_id($message_id, generate => 1);

    $mdn->recipient($self->{MyId});

    my ($headers, $payload) =
        $self->_send_preprocess($mdn->as_mime->stringify, $message_id, undef, undef,
            1, $mdn->should_sign);

    return ($headers, $payload);
}

=item $resp = $as2->send_async_mdn($mdn, $message_id)

Send an ASYNC MDN requested by partner. Returns a L<HTTP::Response>.

The MDN is usually created after an incoming message is received, with
C<Net::AS2::MDN-E<gt>create_success> or C<Net::AS2::MDN-E<gt>create_from_unsuccessful_message>.

If message id is not specified, a random one will be generated.

Note that the destination URL is passed by the partner in its request,
but not specified during construction.

=cut

sub send_async_mdn
{
    my ($self, $mdn, $message_id) = @_;

    $message_id = $self->get_message_id($message_id, generate => 1);

    $mdn->recipient($self->{MyId});
    my $target_url = $mdn->async_url;

    croak "MDN async url is not defined" unless $target_url;
    croak "MDN async url is not valid" unless $target_url =~ m{^https?://};

    my ($headers, $payload) =
        $self->_send_preprocess($mdn->as_mime->stringify, $message_id, $target_url, undef,
            1, $mdn->should_sign);

    my $req = HTTP::Request->new(POST => $target_url, $headers);
    $req->content($payload);

    my $ua = $self->create_useragent;
    my $resp = $ua->request($req);

    return $resp;
}


=item ($mdn, $mic) = $as2->send($data, %MIMEHEADERS)

Send a message to the partner. Returns a C<Net::AS2::MDN> object and the calculated SHA Digest MIC.

The data should be encoded (or assumed to be UTF-8 encoded).

The mime headers should be listed in a hash.
It will be passed to C<MIME::Entity> almost transparently with some defaults dedicated for AS2,
at least the following must also be supplied

=over 4

=item MessageId

Message id of this request should be supplied, or a random one would be generated.

=item Type

Content type of the message should be supplied.

=item Filename

I<Optional.>
Sets the Content-Disposition filename. Default is "payload".

=back

In case of HTTP failure, the MDN object will be marked with C<$mdn-E<gt>is_error>.

In case ASYNC MDN is expected, the MDN object returned will most likely be marked with
C<$mdn-E<gt>is_unparsable> and should be ignored. A misbehave AS2 server could returns
a valid MDN even if async was requested - in this case the C<$mdn-E<gt>is_success> would
be true.

=cut

sub send ## no critic (ProhibitBuiltinHomonyms)
{
    my ($self, $data, %opts) = @_;

    croak "data is not defined"
        unless defined $data;

    $data = utf8::is_utf8($data) ? encode("utf8", $data) : $data;
    my $mic;
    $mic = $self->_base64_digest($data)
        unless $self->{Signature} || $self->{Encryption};

    my $message_id = $self->get_message_id($opts{MessageId}, generate => 1);

    my $filename = delete $opts{Filename} // 'payload';
    $opts{Encoding} = 'base64';
    $opts{Disposition} //= qq{attachment; filename="$filename"};
    $opts{Subject} //= 'AS2 Message';
    $opts{'X-Mailer'} = undef;

    my $mime = MIME::Entity->build(Data => $data, %opts);
    return $self->_send($mime->stringify, $message_id, $mic);
}

sub _send_preprocess
{
    my ($self, $data, $message_id, $target_url, $pre_mic, $is_mdn, $should_mdn_signed) = @_;

    $data =~ s/(?:$crlf|\n)/$crlf/g;
    my $mic = $is_mdn ? undef : ($pre_mic // $self->_base64_digest($data));
    my $mic_alg = $mic ? $self->{Signature} : undef;

    if ($is_mdn && $should_mdn_signed || !$is_mdn && $self->{Signature}) {
        $data = $self->{_smime_sign}->sign($data);
    }
    if ($self->{Encryption} && !$is_mdn) {
        $data = $self->{_smime_enc}->encrypt($data);
    }

    my ($header, $payload) = $data =~ /^(.*?)$crlf$crlf(.*)$/s;

    my @header;
    my ($prev_head, $prev_value);
    my $is_base64 = 0;
    foreach my $line (split(/$crlf/, $header))
    {
        if ($line =~ m/^([^:]+):\s*(.*)/) {
            my ($key, $value) = ($1, $2);
            push @header, ($prev_head => $prev_value)
              if defined $prev_head;
            if (lc($key) eq 'content-type') {
                $value =~ s{application/x-pkcs7}{application/pkcs7};
            } elsif (lc($key) eq 'content-transfer-encoding') {
                $is_base64 = 1 if lc($value) eq 'base64';
                $key = undef;
            }
            $prev_head = $key;
            $prev_value = $value;
        } elsif (defined $prev_head) {
            $prev_value .= " $line";
        }
    }
    push @header, ($prev_head => $prev_value)
        if defined $prev_head;

    push @header, (
        defined $target_url ? ('Recipient-Address' => $target_url) : (),
        'Message-Id'  => "<$message_id>",
        'AS2-Version' => '1.0',
        'AS2-From'    => $self->encode_as2_id($self->{MyId}),
        'AS2-To'      => $self->encode_as2_id($self->{PartnerId}),
        $is_mdn ? () : (
            'Disposition-notification-To' => 'example@example.com',
            ($self->{Signature} ? (
                'Disposition-Notification-Options' => 'signed-receipt-protocol=required, pkcs7-signature; signed-receipt-micalg=required, ' . $self->{Signature}
            ) : ()),
            ($self->{MdnAsyncUrl} ? (
                'Receipt-Delivery-Option' => $self->{MdnAsyncUrl}
            ) : ())
        ),
    );
    $payload = decode_base64($payload)
        if $is_base64;
    return (\@header, $payload, $mic, $mic_alg);
}

=item $as2->create_useragent()

This returns an object for handling requests.

It is configured via the C<UserAgentClass> option.
It defaults to L<Net::AS2::HTTP>.

=cut

sub create_useragent
{
    my $self = shift;

    return $self->{UserAgentClass}->new($self);
}

=item $as2->encode_as2_id( $id )

Return an AS2 ID quoted appropriately.

=cut

sub encode_as2_id {
    my ($self, $as2_id) = @_;
    if ($as2_id =~ s/(\\|")/\\$1/g || $as2_id =~ / /) {
        return qq{"$as2_id"};
    }
    return $as2_id;
}

=item $as2->parse_as2_id( $id )

Parse an AS2 ID from the given string, C<$id>, removing surrounding
spaces and quotes.

=cut

sub parse_as2_id {
    my ($self, $as2_id) = @_;
    my $chars = '\x23-\x5B\x5D-\x7E';
    $as2_id =~ /^ (?: ([!$chars]+) | "((?:\\\\|\\"|[!$chars ])+)" ) $/x;
    if (defined $1) {
        return $1;
    } elsif (defined $2) {
        $as2_id = $2;
        $as2_id =~ s/\\(\\|")/$1/g;
        return $as2_id;
    }
    return;
}

=item $id = $as2->get_message_id( $message_id, generate => ? )

Returns, or generates, a message id. Any angle brackets surrounding
the id are removed.

If C<$message_id> is defined and not an empty string and conforms to
RFC 2822, then this id is returned.

If C<$message_id> is defined and not an empty string but does not conform to
RFC 2822, then the method dies with an error message.

If C<generate> is true then a basic random message ID is created
using C<time()>, C<rand()> and C<hostname()>.

If C<generate> is false (default) then the method dies with an error message.

For production systems, it is strongly recommended to generate and use
an ID using a better random generator function and pass it in to this module.

=cut

sub get_message_id {
    my ($self, $message_id, %opt ) = @_;

    if ($message_id) {
        if ($message_id =~ /<?($Email::Address::addr_spec)>?/) {
            $message_id = $1;
        }
        else {
            croak "Message-Id does not conform to RFC 2822: '$message_id'";
        }
    }
    elsif ($opt{generate}) {
        $message_id = sprintf('%s@%s', (time() + rand()), hostname());
    }
    else {
        croak "Message-Id is undefined, empty or can generate option is false";
    }

    return $message_id;
}

sub _send
{
    my ($self, $data, $message_id, $pre_mic) = @_;

    my $target_url = $self->{PartnerUrl};
    my ($headers, $payload, $mic, $mic_alg) =
        $self->_send_preprocess($data, $message_id, $target_url, $pre_mic);

    my $req = HTTP::Request->new(POST => $target_url, \@$headers);
    $req->content($payload);

    my $test = $req->as_string;

    my $ua = $self->create_useragent;
    my $resp = $ua->request($req);

    my $mdn;
    if ($resp->is_success)
    {
        my $content = $resp->as_string;
        # Remove the status line
        $content =~ s{^.*?\r?\n}{};
        $mdn = $self->_parse_mdn($content);
        $mdn->match_mic($mic, $self->{Signature});

    } else {
        $mdn =
            Net::AS2::MDN->create_error_mdn(sprintf('HTTP failure: %s', $resp->status_line));
    }
    return wantarray ? ($mdn, $mic, $mic_alg) : $mdn;
}

sub _parse_mdn
{
    my ($self, $content) = @_;

    if ($self->{_smime_sign}->isSigned($content))
    {
        # OpenSSL (Crypt::SMIME) in Windows cannot handle binary content,
        # convert signature part to base64
        $content = _pkcs7_base64($content);
        $content = eval { $self->{_smime_sign}->check($content); };
        return Net::AS2::MDN->create_unparsable_mdn('MDN signature failed verification: ' . $@)
            if $@;
    } else {
        return Net::AS2::MDN->create_unparsable_mdn('MDN is not signed')
            if $self->{Signature};
    }
    return Net::AS2::MDN->parse_mdn($content);
}

sub _pkcs7_base64
{
    my ($content) = @_;
    my $parser = MIME::Parser->new;

    $parser->output_to_core(1);
    $parser->tmp_to_core(1);
    my $entity = $parser->parse_data($content);

    if ($entity->parts == 2)
    {
        my $p = $entity->parts(1);
        if (defined $p && $p->head &&
            $p->head->get('Content-type') =~ m{^application/(x-)?pkcs7-signature($|;)} &&
            ($p->head->get('Content-transfer-encoding') // '')  !~ qr{^base64\r?$}
        ) {
            $p->head->replace('Content-transfer-encoding', 'base64');
            return $entity->stringify;
        }
    }

    return $content;
}

sub _base64_digest {
    my ($self, $content) = @_;

    $self->{Digest}->add($content);

    my $digest = $self->{Digest}->b64digest();

    # pad the base64 string
    while (length($digest) % 4) {
        $digest .= '=';
    }

    return $digest;
}

sub _http_headers {
    my ($self, $headers) = @_;

    my $http_headers = HTTP::Headers->new();

    $http_headers->content_type($headers->{CONTENT_TYPE});

    foreach (keys %$headers) {
        next unless /^HTTP_/;
        my $value = $headers->{$_};
        my $key = $_;
        $key =~ s/^HTTP_//;
        $key =~ s/_/-/g;
        $http_headers->header($key => $value);
    }

    return $http_headers;
}

1;

=back

=head1 BUGS

=over 4

=item *

A bug in L<Crypt::SMIME> may cause tests to fail - specifically failed to add public key after decryption failure.
It appears to be related to a memory leak in L<Crypt::SMIME>.

=back

=head1 SEE ALSO

L<Net::AS2::HTTP>, L<Net::AS2::HTTPS>

L<Net::AS2::FAQ>, L<Net::AS2::Message>, L<Net::AS2::MDN>, L<MIME::Entity>

L<RFC 4130|https://www.ietf.org/rfc/rfc4130.txt>, L<RFC 2822|https://www.ietf.org/rfc/rfc2822.txt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sam Wong.

This software is copyright (c) 2019 by Catalyst IT.
Additional contributions by Andrew Maguire <ajm@cpan.org>

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

This module is not certificated by any AS2 body. This module generates MDN on your behalf.
When using this module, you must have reviewed and be responsible for all the actions and in-actions caused by this module.

More legal jargon follows:

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


