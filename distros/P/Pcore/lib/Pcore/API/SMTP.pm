package Pcore::API::SMTP;

use Pcore -dist, -const, -class, -res;
use Pcore::Handle qw[:TLS_CTX];
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_plain_arrayref];
use Pcore::Util::Data qw[from_b64 to_b64];
use Pcore::Util::Text qw[encode_utf8];
use Authen::SASL;

# required
has host     => ();
has port     => ();
has username => ();
has password => ();
has tls      => ();

# handle settings
has tls_ctx => $TLS_CTX_HIGH;    # Maybe [ HashRef | Enum [ $TLS_CTX_HIGH, $TLS_CTX_LOW ] ]

const our $STATUS_REASON => {
    200 => q[(nonstandard success response, see rfc876)],
    211 => q[System status, or system help reply],
    214 => q[Help message],
    220 => q[<domain> Service ready],
    221 => q[<domain> Service closing transmission channel],
    235 => q[Authentication successful],
    250 => q[Requested mail action okay, completed],
    251 => q[User not local; will forward to <forward-path>],
    252 => q[Cannot VRFY user, but will accept message and attempt delivery],
    334 => q[Continue request],
    354 => q[Start mail input; end with <CRLF>.<CRLF>],
    421 => q[<domain> Service not available, closing transmission channel],
    450 => q[Requested mail action not taken: mailbox unavailable],
    451 => q[Requested action aborted: local error in processing],
    452 => q[Requested action not taken: insufficient system storage],
    500 => q[Syntax error, command unrecognised],
    501 => q[Syntax error in parameters or arguments],
    502 => q[Command not implemented],
    503 => q[Bad sequence of commands],
    504 => q[Command parameter not implemented],
    521 => q[<domain> does not accept mail (see rfc1846)],
    530 => q[Access denied (???a Sendmailism)],
    534 => q[Please log in via your web browser],
    535 => q[AUTH failed with the remote server],
    550 => q[Requested action not taken: mailbox unavailable],
    551 => q[User not local; please try <forward-path>],
    552 => q[Requested mail action aborted: exceeded storage allocation],
    553 => q[Requested action not taken: mailbox name not allowed],
    554 => q[Transaction failed],
    555 => q[Syntax error],
};

sub sendmail ( $self, %args ) {
    %args = (
        from     => undef,
        reply_to => undef,    # Str
        to       => undef,    # Str, ArrayRef
        cc       => undef,    # Str, ArrayRef
        bcc      => undef,    # Str, ArrayRef
        subject  => undef,
        headers  => undef,    # ArrayRef
        body     => undef,    # Str, ScalarRef
        %args
    );

    $args{to}  = undef if defined $args{to}  && !$args{to};
    $args{cc}  = undef if defined $args{cc}  && !$args{cc};
    $args{bcc} = undef if defined $args{bcc} && !$args{bcc};

    $args{to}  = [ $args{to} ]  if defined $args{to}  && !is_plain_arrayref $args{to};
    $args{cc}  = [ $args{cc} ]  if defined $args{cc}  && !is_plain_arrayref $args{cc};
    $args{bcc} = [ $args{bcc} ] if defined $args{bcc} && !is_plain_arrayref $args{bcc};

    my $h = P->handle(
        [ $self->{host}, $self->{port} ],
        timeout => $self->{timeout},
        tls_ctx => $self->{tls_ctx},
    );

    $h->starttls if $self->{tls};

    my $res;

    # handshake
    ( $res = $self->_read_response($h) ) or return $res;

    # EHLO
    ( $res = $self->_EHLO($h) ) or return $res;

    # AUTH
    ( $res = $self->_AUTH( $h, $res->{ext}->{AUTH} ) ) or return $res;

    # MAIL_FROM
    ( $res = $self->_MAIL_FROM( $h, $args{from} // $self->{username} ) ) or return $res;

    # RCPT_TO
    ( $res = $self->_RCPT_TO( $h, [ defined $args{to} ? $args{to}->@* : (), defined $args{cc} ? $args{cc}->@* : (), defined $args{bcc} ? $args{bcc}->@* : () ] ) ) or return $res;

    # DATA
    ( $res = $self->_DATA( $h, \%args ) ) or return $res;

    # QUIT
    return $self->_QUIT($h);
}

sub test ($self) {
    my $h = P->handle(
        [ $self->{host}, $self->{port} ],
        timeout => $self->{timeout},
        tls_ctx => $self->{tls_ctx},
    );

    $h->starttls if $self->{tls};

    my $res;

    # handshake
    ( $res = $self->_read_response($h) ) or return $res;

    # EHLO
    ( $res = $self->_EHLO($h) ) or return $res;

    # AUTH
    $res = $self->_AUTH( $h, $res->{ext}->{AUTH} );

    return $res;
}

sub _read_response ( $self, $h ) {
    my $status;
    my $data = [];

    while () {
        my $line = $h->read_line("\r\n");

        return res [ $h->{status}, $h->{reason} ] if !$line;

        $line->$* =~ s[\A(\d{3})(.?)][]sm;

        $status = $1;

        my $more = $2 eq q[-];

        push $data->@*, $line->$*;

        # response finished
        last if !$more;
    }

    return res [ $status, $STATUS_REASON ], $data;
}

sub _EHLO ( $self, $h ) {
    $h->write("EHLO localhost.localdomain\r\n");

    my $res = $self->_read_response($h);

    if ($res) {
        my $data;

        for my $line ( $res->{data}->@* ) {
            if ( $line =~ s[\A([[:upper:]\d]+)\s?][]sm ) {
                $res->{ext}->{$1} = $line;
            }
            else {
                push $data->@*, $line;
            }
        }

        $res->{data} = $data;
    }

    return $res;
}

sub _AUTH ( $self, $h, $mechanisms ) {

    # NOTE partially stolen from Net::SMTP

    # remove DIGEST-MD5 mechanism, because he doesn't work
    $mechanisms =~ s/DIGEST-MD5//smg;

    return res [ 500, $STATUS_REASON ] if !$mechanisms;

    my $sasl = Authen::SASL->new(
        mechanism => $mechanisms,
        callback  => {
            user     => $self->{username},
            pass     => $self->{password},
            authname => $self->{username},
        },
        debug => 0,
    );

    my ( $client, $str );

    while ( !defined $str ) {
        if ($client) {

            # $client mechanism failed, so we need to exclude this mechanism from list
            my $failed_mechanism = $client->mechanism;

            return res [ 500, $STATUS_REASON ] if !defined $failed_mechanism;

            $mechanisms =~ s/\b\Q$failed_mechanism\E\b//sm;

            # no auth mechanisms left
            return res [ 500, $STATUS_REASON ] if $mechanisms !~ /\S/sm;

            $sasl->mechanism($mechanisms);
        }

        # we should probably allow the user to pass the host, but I don't
        # currently know and SASL mechanisms that are used by smtp that need it

        $client = $sasl->client_new( 'smtp', $self->{host}, 0 );

        $str = $client->client_start;
    }

    my $cmd = 'AUTH ' . $client->mechanism . ( defined $str and length $str ? $SPACE . to_b64 $str, $EMPTY : $EMPTY );

    while () {
        $h->write("$cmd\r\n");

        my $res = $self->_read_response($h);

        if ( $res || $res != 334 ) {
            return $res;
        }
        else {
            $cmd = to_b64 $client->client_step( from_b64 $res->{data}->[0] ), $EMPTY;
        }
    }

    return;
}

sub _MAIL_FROM ( $self, $h, $from ) {
    $h->write("MAIL FROM:<$from>\r\n");

    return $self->_read_response($h);
}

sub _RCPT_TO ( $self, $h, $to ) {
    while () {
        my $addr = shift $to->@*;

        $h->write("RCPT TO:<$addr>\r\n");

        my $res = $self->_read_response($h);

        # RCPT error
        if ( !$res ) {
            $res->{error} = $addr;

            return $res;
        }

        # RCPT ok, next
        next if $to->@*;

        # RCPT ok, last
        return $res;
    }

    return;
}

sub _DATA ( $self, $h, $args ) {
    $h->write("DATA\r\n");

    my $res = $self->_read_response($h);

    return $res if $res != 354;

    # send headers
    my $buf;

    $buf .= "From: $args->{from}\r\n" if $args->{from};

    $buf .= "Reply-To: $args->{reply_to}\r\n" if $args->{reply_to};

    $buf .= "To: @{[ join ', ', $args->{to}->@* ]}\r\n" if $args->{to};

    $buf .= "Cc: @{[ join ', ', $args->{cc}->@* ]}\r\n" if $args->{cc};

    $buf .= 'Subject: ' . encode_utf8 $args->{subject} . "\r\n" if defined $args->{subject};

    $buf .= join( "\r\n", $args->{headers}->@* ) . "\r\n" if $args->{headers} && $args->{headers}->@*;

    my $boundary;

    if ( defined $args->{body} && is_plain_arrayref $args->{body} ) {
        $boundary = P->random->bytes_hex(64);

        $buf .= "MIME-Version: 1.0\r\n";

        $buf .= qq[Content-Type: multipart/mixed; BOUNDARY="$boundary"\r\n];
    }

    $buf .= "\r\n";

    $h->write($buf);

    # send body
    $buf = $EMPTY;

    if ( defined $args->{body} ) {
        if ( !is_ref $args->{body} ) {
            $buf .= encode_utf8 $args->{body};
        }
        elsif ( is_plain_scalarref $args->{body} ) {
            $buf .= encode_utf8 $args->{body}->$*;
        }
        elsif ( is_plain_arrayref $args->{body} ) {
            state $pack_mime = sub ( $boundary, $headers, $body ) {
                my $part = "--$boundary\r\n";

                $part .= join( "\r\n", map { encode_utf8 $_} $headers->@* ) . "\r\n" if defined $headers;

                $part .= "Content-Transfer-Encoding: base64\r\n";

                $part .= "\r\n";

                $part .= to_b64 encode_utf8 $body->$*;

                $part .= "\r\n";

                $part .= "--$boundary\r\n";

                return \$part;
            };

            for my $part ( $args->{body}->@* ) {
                next if !defined $part;

                if ( !is_ref $part || is_plain_scalarref $part ) {
                    $buf .= $pack_mime->( $boundary, undef, is_plain_scalarref $part ? $part : \$part )->$*;
                }
                elsif ( is_plain_arrayref $part) {
                    if ( !is_ref $part->[0] ) {
                        my $headers = [    #
                            qq[Content-Type: @{[ P->path($part->[0])->mime_type // 'application/octet-stream' ]}; name="$part->[0]"],
                            qq[Content-Disposition: attachment; filename="$part->[0]"],
                        ];

                        $buf .= $pack_mime->( $boundary, $headers, is_plain_scalarref $part->[1] ? $part->[1] : \$part->[1] )->$*;
                    }
                    else {
                        $buf .= $pack_mime->( $boundary, $part->[0], is_plain_scalarref $part->[1] ? $part->[1] : \$part->[1] )->$*;
                    }
                }
                else {
                    die q[Invalid ref type];
                }
            }
        }
        else {
            die q[Invalid ref type];
        }
    }

    if ( defined $buf ) {
        $buf =~ s/\x0A[.]/\x0A../smg;

        $buf .= "\r\n";
    }

    $buf .= ".\r\n";

    $h->write($buf);

    return $self->_read_response($h);
}

sub _QUIT ( $self, $h ) {
    $h->write("QUIT\r\n");

    # do not read QUIT response
    return res [ 221, $STATUS_REASON ];
}

sub _RSET ( $self, $h ) {
    $h->write("RSET\r\n");

    return $self->_read_response($h);
}

sub _VRFY ( $self, $h, $email, $cb ) {
    ...;

    return;
}

sub _NOOP ( $self, $h, $cb ) {
    $h->write("NOOP\r\n");

    return $self->_read_response($h);
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 53                   | * Subroutine "sendmail" with high complexity score (23)                                                        |
## |      | 270                  | * Subroutine "_DATA" with high complexity score (29)                                                           |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 140, 142             | RegularExpressions::ProhibitCaptureWithoutTest - Capture variable used outside conditional                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 384                  | * Private subroutine/method '_RSET' declared but not used                                                      |
## |      | 390                  | * Private subroutine/method '_VRFY' declared but not used                                                      |
## |      | 396                  | * Private subroutine/method '_NOOP' declared but not used                                                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 391                  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 54                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::SMTP - non-blocking SMTP protocol implementation

=head1 SYNOPSIS

    my $smtp = Pcore::API::SMTP->new( {
        host     => 'smtp.gmail.com',
        port     => 465,
        username => 'username@gmail.com',
        password => 'password',
        tls      => 1,
    } );

    # send email with two attachments
    $message_body = [ [ 'filename1.ext', \$content1 ], [ 'filename2.ext', \$content2 ] ];

    my $res = $smtp->sendmail(
        from     => 'from@host',
        reply_to => 'from@host',
        to       => 'to@host',
        cc       => 'cc@host',
        bcc      => 'bcc@host',
        subject  => 'email subject',
        body     => $message_body
    );

=head1 DESCRIPTION

AnyEvent based SMTP protocol implementation.

=head1 ATTRIBUTES

=head1 METHODS

=head2 new(\%args)

Please, see L</SYNOPSIS>

=head2 sendmail(%args)

Where %args are:

=over

=item from

from email address.

=item reply_to

reply to email address.

=item to

This argument can be either Scalar or ArrayRef[Scalar].

=item cc

This argument can be either Scalar or ArrayRef[Scalar].

=item bcc

This argument can be either Scalar or ArrayRef[Scalar].

=item subject

Email subject.

=item body

Email body. Can be Scalar|ScalarRef|ArrayRef[Scalar|ScalarRef|ArrayRef].

If body is ArrayRef - email will be composed as multipart/mixed. Each part can be a C<$body> or C<\$body> or a C<[$headers, $body]>. If C<$headers> ia plain scalar - this will be a filename, and headers array will be generated. Or you can specify all required headers manually in ArrayRef.

Examples:

    $body = 'message body';

    $body = \'message body';

    $body = [ 'body1', \$body2, [ \@headers, $content ] ];

    # send email with two file attachmants
    $body = [ 'message body', [ 'filename1.txt', \$content1 ], [ 'filename2.txt', \$content2 ] ];

    # manually specify headers
    # send HTML email with 1 attachment
    $body = [ [ ['Content-Type: text/html'], \$body ], [ 'filename1.txt', \$attachment ] ];

=back

=head1 NOTES

If you are using gmail and get error 534 "Please log in via your web browser", go to L<https://myaccount.google.com/lesssecureapps> and allow less secure apps.

=head1 SEE ALSO

L<http://foundation.zurb.com/emails.html>

L<https://habrahabr.ru/post/317810/>

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
