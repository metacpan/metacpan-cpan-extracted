package Pcore::SMTP v0.5.9;

use Pcore -dist, -const, -class, -res;
use Pcore::AE::Handle qw[:TLS_CTX];
use Pcore::Util::Scalar qw[is_ref is_plain_scalarref is_plain_arrayref is_plain_coderef];
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
has timeout => 10;
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

sub sendmail ( $self, @ ) {
    my $cb1 = is_plain_coderef $_[-1] ? pop : undef;

    my %args = (
        from     => undef,
        reply_to => undef,    # Str
        to       => undef,    # Str, ArrayRef
        cc       => undef,    # Str, ArrayRef
        bcc      => undef,    # Str, ArrayRef
        subject  => undef,
        headers  => undef,    # ArrayRef
        body     => undef,    # Str, ScalarRef
        splice @_, 1
    );

    $args{to}  = undef if defined $args{to}  && !$args{to};
    $args{cc}  = undef if defined $args{cc}  && !$args{cc};
    $args{bcc} = undef if defined $args{bcc} && !$args{bcc};

    $args{to}  = [ $args{to} ]  if defined $args{to}  && !is_plain_arrayref $args{to};
    $args{cc}  = [ $args{cc} ]  if defined $args{cc}  && !is_plain_arrayref $args{cc};
    $args{bcc} = [ $args{bcc} ] if defined $args{bcc} && !is_plain_arrayref $args{bcc};

    my $rouse_cb = defined wantarray ? Coro::rouse_cb : ();

    my $cb = sub ( $h, $res ) {
        $h->destroy;

        $rouse_cb ? $cb1 ? $rouse_cb->( $cb1->($res) ) : $rouse_cb->($res) : $cb1 ? $cb1->($res) : ();

        return;
    };

    Pcore::AE::Handle->new(
        connect          => 'smtp://' . $self->{host} . q[:] . $self->{port},
        connect_timeout  => $self->{timeout},
        timeout          => $self->{timeout},
        persistent       => 0,
        tls_ctx          => $self->{tls_ctx},
        on_connect_error => sub ( $h, $reason ) {
            $cb->( $h, res [ 500, $reason ] );

            return;
        },
        on_error => sub ( $h, $fatal, $reason ) {
            $cb->( $h, res [ 500, $reason ] );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {
            $h->starttls('connect') if $self->{tls};

            # read handshake response
            $self->_read_response(
                $h,
                sub ($res) {

                    # HANDSHAKE error
                    if ( !$res ) {
                        $cb->( $h, $res );
                    }

                    # HANDSHAKE ok
                    else {

                        # EHLO
                        $self->_EHLO(
                            $h,
                            sub ($ehlo) {

                                # EHLO error
                                if ( !$ehlo ) {
                                    $cb->( $h, $ehlo );
                                }

                                # EHLO ok
                                else {

                                    # AUTH
                                    $self->_AUTH(
                                        $h,
                                        $ehlo->{ext}->{AUTH},
                                        sub ($auth) {

                                            # AUTH error
                                            if ( !$auth ) {
                                                $cb->( $h, $auth );
                                            }

                                            # AUTH ok
                                            else {

                                                # MAIL
                                                $self->_MAIL_FROM(
                                                    $h,
                                                    $args{from} // $self->{username},
                                                    sub ($mail) {

                                                        # MAIL error
                                                        if ( !$mail ) {
                                                            $cb->( $h, $mail );
                                                        }

                                                        # MAIL ok
                                                        else {

                                                            # RCPT
                                                            $self->_RCPT_TO(
                                                                $h,
                                                                [ defined $args{to} ? $args{to}->@* : (), defined $args{cc} ? $args{cc}->@* : (), defined $args{bcc} ? $args{bcc}->@* : () ],
                                                                sub ($rcpt) {

                                                                    # RCPT error
                                                                    if ( !$rcpt ) {
                                                                        $cb->( $h, $rcpt );
                                                                    }

                                                                    # RCPT ok
                                                                    else {

                                                                        # DATA
                                                                        $self->_DATA(
                                                                            $h,
                                                                            \%args,
                                                                            sub ($data) {

                                                                                # DATA error
                                                                                if ( !$data ) {
                                                                                    $cb->( $h, $data );
                                                                                }

                                                                                # DATA ok
                                                                                else {

                                                                                    # QUIT
                                                                                    $self->_QUIT(
                                                                                        $h,
                                                                                        sub($quit) {

                                                                                            # quit status is not checked
                                                                                            $cb->( $h, $quit );

                                                                                            return;
                                                                                        }
                                                                                    );
                                                                                }

                                                                                return;
                                                                            }
                                                                        );
                                                                    }

                                                                    return;
                                                                }
                                                            );
                                                        }

                                                        return;
                                                    }
                                                );
                                            }

                                            return;
                                        }
                                    );
                                }

                                return;
                            }
                        );
                    }

                    return;
                }
            );

            return;
        },
    );

    return $rouse_cb ? Coro::rouse_wait $rouse_cb : ();
}

sub _EHLO ( $self, $h, $cb ) {
    $h->push_write(qq[EHLO localhost.localdomain$CRLF]);

    $self->_read_response(
        $h,
        sub ($res) {
            my $data;

            if ($res) {
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

            $cb->($res);

            return;
        }
    );

    return;
}

sub _AUTH ( $self, $h, $mechanisms, $cb ) {

    # NOTE partially stolen from Net::SMTP

    if ( !$mechanisms ) {
        $cb->( res [ 500, $STATUS_REASON ] );

        return;
    }

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

            if ( !defined $failed_mechanism ) {
                $cb->( res [ 500, $STATUS_REASON ] );

                return;
            }

            $mechanisms =~ s/\b\Q$failed_mechanism\E\b//sm;

            # no auth mechanisms left
            if ( $mechanisms !~ /\S/sm ) {
                $cb->( res [ 500, $STATUS_REASON ] );

                return;
            }

            $sasl->mechanism($mechanisms);
        }

        # we should probably allow the user to pass the host, but I don't
        # currently know and SASL mechanisms that are used by smtp that need it

        $client = $sasl->client_new( 'smtp', $self->{host}, 0 );

        $str = $client->client_start;
    }

    my $cmd = sub ($cmd) {
        my $sub = __SUB__;

        $h->push_write( $cmd . $CRLF );

        $self->_read_response(
            $h,
            sub ($res) {
                if ( $res || $res != 334 ) {
                    $cb->($res);
                }
                else {
                    $sub->( to_b64 $client->client_step( from_b64 $res->{data}->[0] ), q[] );
                }

                return;
            }
        );

        return;
    };

    $cmd->( 'AUTH ' . $client->mechanism . ( defined $str and length $str ? q[ ] . to_b64 $str, q[] : q[] ) );

    return;
}

sub _MAIL_FROM ( $self, $h, $from, $cb ) {
    $h->push_write(qq[MAIL FROM:<$from>$CRLF]);

    $self->_read_response( $h, $cb );

    return;
}

sub _RCPT_TO ( $self, $h, $to, $cb ) {
    my $cmd = sub ($addr) {
        my $sub = __SUB__;

        $h->push_write(qq[RCPT TO:<$addr>$CRLF]);

        $self->_read_response(
            $h,
            sub ($res) {

                # RCPT error
                if ( !$res ) {
                    $res->{error} = $addr;

                    $cb->($res);
                }

                # RCPT ok, next
                elsif ( $to->@* ) {
                    $sub->( shift $to->@* );
                }

                # RCPT ok, last
                else {
                    $cb->($res);
                }

                return;
            }
        );

        return;
    };

    $cmd->( shift $to->@* );

    return;
}

sub _DATA ( $self, $h, $args, $cb ) {
    state $send_headers = sub ( $h, $args ) {
        my $buf;

        $buf .= qq[From: $args->{from}$CRLF] if $args->{from};

        $buf .= qq[Reply-To: $args->{reply_to}$CRLF] if $args->{reply_to};

        $buf .= qq[To: @{[ join q[, ], $args->{to}->@* ]}$CRLF] if $args->{to};

        $buf .= qq[Cc: @{[ join q[, ], $args->{cc}->@* ]}$CRLF] if $args->{cc};

        $buf .= 'Subject: ' . encode_utf8 $args->{subject} . $CRLF if defined $args->{subject};

        $buf .= join( $CRLF, $args->{headers}->@* ) . $CRLF if $args->{headers} && $args->{headers}->@*;

        my $boundary;

        if ( defined $args->{body} && is_plain_arrayref $args->{body} ) {
            $boundary = P->random->bytes_hex(64);

            $buf .= qq[MIME-Version: 1.0$CRLF];

            $buf .= qq[Content-Type: multipart/mixed; BOUNDARY="$boundary"$CRLF];
        }

        $buf .= $CRLF;

        $h->push_write($buf);

        return $boundary;
    };

    state $send_body = sub ( $h, $args, $boundary ) {
        my $buf;

        if ( defined $args->{body} ) {
            if ( !is_ref $args->{body} ) {
                $buf .= encode_utf8 $args->{body};
            }
            elsif ( is_plain_scalarref $args->{body} ) {
                $buf .= encode_utf8 $args->{body}->$*;
            }
            elsif ( is_plain_arrayref $args->{body} ) {
                state $pack_mime = sub ( $boundary, $headers, $body ) {
                    my $part = '--' . $boundary . $CRLF;

                    $part .= join( $CRLF, map { encode_utf8 $_} $headers->@* ) . $CRLF if defined $headers;

                    $part .= 'Content-Transfer-Encoding: base64' . $CRLF;

                    $part .= $CRLF;

                    $part .= to_b64 encode_utf8 $body->$*;

                    $part .= $CRLF;

                    $part .= '--' . $boundary . $CRLF;

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
                                qq[Content-Type: @{[P->path($part->[0])->mime_type]}; name="$part->[0]"],
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

            $buf .= $CRLF;
        }

        $buf .= qq[.$CRLF];

        $h->push_write($buf);

        return;
    };

    $h->push_write(qq[DATA$CRLF]);

    $self->_read_response(
        $h,
        sub ($res) {
            if ( $res != 354 ) {
                $cb->($res);
            }
            else {
                my $boundary = $send_headers->( $h, $args );

                $send_body->( $h, $args, $boundary );

                $self->_read_response( $h, $cb );
            }

            return;
        }
    );

    return;
}

sub _RSET ( $self, $h, $cb ) {
    $h->push_write(qq[RSET$CRLF]);

    $self->_read_response( $h, $cb );

    return;
}

sub _VRFY ( $self, $h, $email, $cb ) {
    ...;

    return;
}

sub _NOOP ( $self, $h, $cb ) {
    $h->push_write(qq[NOOP$CRLF]);

    $self->_read_response( $h, $cb );

    return;
}

sub _QUIT ( $self, $h, $cb ) {
    $h->push_write(qq[QUIT$CRLF]);

    # do not wait for QUIT response
    $h->destroy;

    $cb->( res [ 221, $STATUS_REASON ] );

    return;
}

sub _read_response ( $self, $h, $cb ) {
    my $data = [];

    $h->on_read( sub ($h) {
        $h->unshift_read(
            line => $CRLF,
            sub ( $h, $line, $eol ) {
                $line =~ s[\A(\d{3})(.?)][]sm;

                my $status = $1;

                my $more = $2 eq q[-];

                push $data->@*, $line;

                # response finished
                if ( !$more ) {

                    # remove wathcher
                    $h->on_read;

                    $cb->( res [ $status, $STATUS_REASON ], $data );
                }

                return;
            }
        );

        return;
    } );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitExcessComplexity                                                                          |
## |      | 54                   | * Subroutine "sendmail" with high complexity score (35)                                                        |
## |      | 395                  | * Subroutine "_DATA" with high complexity score (30)                                                           |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 181                  | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 522                  | * Private subroutine/method '_RSET' declared but not used                                                      |
## |      | 530                  | * Private subroutine/method '_VRFY' declared but not used                                                      |
## |      | 536                  | * Private subroutine/method '_NOOP' declared but not used                                                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 531                  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 564, 566             | RegularExpressions::ProhibitCaptureWithoutTest - Capture variable used outside conditional                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 57                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::SMTP - non-blocking SMTP protocol implementation

=head1 SYNOPSIS

    my $smtp = Pcore::SMTP->new( {
        host     => 'smtp.gmail.com',
        port     => 465,
        username => 'username@gmail.com',
        password => 'password',
        tls      => 1,
    } );

    # send email with two attachments
    $message_body = [ [ 'filename1.ext', \$content1 ], [ 'filename2.ext', \$content2 ] ];

    $smtp->sendmail(
        from     => 'from@host',
        reply_to => 'from@host',
        to       => 'to@host',
        cc       => 'cc@host',
        bcc      => 'bcc@host',
        subject  => 'email subject',
        body     => $message_body,
        sub ($res) {
            say $res;

            $cb->();

            return;
        }
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
