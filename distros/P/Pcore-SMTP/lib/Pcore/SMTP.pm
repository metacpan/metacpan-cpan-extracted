package Pcore::SMTP v0.4.1;

use Pcore -dist, -const, -class, -result;
use Pcore::AE::Handle qw[:TLS_CTX];
use Pcore::Util::Scalar qw[is_ref is_plain_arrayref];
use Pcore::Util::Data qw[from_b64 to_b64];
use Pcore::Util::Text qw[encode_utf8];
use Authen::SASL;

has host     => ( is => 'ro', isa => Str,         required => 1 );
has port     => ( is => 'ro', isa => PositiveInt, required => 1 );
has username => ( is => 'ro', isa => Str,         required => 1 );
has password => ( is => 'ro', isa => Str,         required => 1 );
has tls      => ( is => 'ro', isa => Bool,        default  => 1 );
has tls_ctx => ( is => 'ro', isa => Maybe [ HashRef | Enum [ $TLS_CTX_HIGH, $TLS_CTX_LOW ] ], default => $TLS_CTX_HIGH );

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
    my $cb = $_[-1] // sub {return};

    my %args = (
        from     => undef,
        reply_to => undef,    # Str
        to       => undef,    # Str, ArrayRef
        cc       => undef,    # Str, ArrayRef
        bcc      => undef,    # Str, ArrayRef
        subject  => undef,
        headers  => undef,    # ArrayRef
        body     => undef,    # Str, ScalarRef
        splice @_, 1, -1
    );

    $args{to}  = undef if defined $args{to}  && !$args{to};
    $args{cc}  = undef if defined $args{cc}  && !$args{cc};
    $args{bcc} = undef if defined $args{bcc} && !$args{bcc};

    $args{to}  = [ $args{to} ]  if defined $args{to}  && !is_plain_arrayref $args{to};
    $args{cc}  = [ $args{cc} ]  if defined $args{cc}  && !is_plain_arrayref $args{cc};
    $args{bcc} = [ $args{bcc} ] if defined $args{bcc} && !is_plain_arrayref $args{bcc};

    Pcore::AE::Handle->new(
        connect          => 'smtp://' . $self->host . q[:] . $self->port,
        connect_timeout  => 10,
        timeout          => 10,
        persistent       => 0,
        tls_ctx          => $self->{tls_ctx},
        on_connect_error => sub ( $h, $reason ) {
            $cb->( result [ 500, $reason ] );

            return;
        },
        on_error => sub ( $h, $fatal, $reason ) {
            $cb->( result [ 500, $reason ] );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {
            $h->starttls('connect') if $self->tls;

            # read handshake response
            $self->_read_response(
                $h,
                sub ($res) {

                    # HANDSHAKE error
                    if ( !$res ) {
                        $cb->($res);
                    }

                    # HANDSHAKE ok
                    else {

                        # EHLO
                        $self->_EHLO(
                            $h,
                            sub ($ehlo) {

                                # EHLO error
                                if ( !$ehlo ) {
                                    $cb->($ehlo);
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
                                                $cb->($auth);
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
                                                            $cb->($mail);
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
                                                                        $cb->($rcpt);
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
                                                                                    $cb->($data);
                                                                                }

                                                                                # DATA ok
                                                                                else {

                                                                                    # QUIT
                                                                                    $self->_QUIT(
                                                                                        $h,
                                                                                        sub($quit) {

                                                                                            # quit status is not checked
                                                                                            $cb->($quit);

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

    return;
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
        $cb->( result [ 500, $STATUS_REASON ] );

        return;
    }

    my $sasl = Authen::SASL->new(
        mechanism => $mechanisms,
        callback  => {
            user     => $self->username,
            pass     => $self->password,
            authname => $self->username,
        },
        debug => 0,
    );

    my ( $client, $str );

    while ( !defined $str ) {
        if ($client) {

            # $client mechanism failed, so we need to exclude this mechanism from list
            my $failed_mechanism = $client->mechanism;

            if ( !defined $failed_mechanism ) {
                $cb->( result [ 500, $STATUS_REASON ] );

                return;
            }

            $mechanisms =~ s/\b\Q$failed_mechanism\E\b//sm;

            # no auth mechanisms left
            if ( $mechanisms !~ /\S/sm ) {
                $cb->( result [ 500, $STATUS_REASON ] );

                return;
            }

            $sasl->mechanism($mechanisms);
        }

        # we should probably allow the user to pass the host, but I don't
        # currently know and SASL mechanisms that are used by smtp that need it

        $client = $sasl->client_new( 'smtp', $self->host, 0 );

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
    my $buf;

    $buf .= qq[From: $args->{from}$CRLF] if $args->{from};

    $buf .= qq[Reply-To: $args->{reply_to}$CRLF] if $args->{reply_to};

    $buf .= qq[To: @{[ join q[, ], $args->{to}->@* ]}$CRLF] if $args->{to};

    $buf .= qq[Cc: @{[ join q[, ], $args->{cc}->@* ]}$CRLF] if $args->{cc};

    $buf .= qq[Subject: $args->{subject}$CRLF] if defined $args->{subject};

    $buf .= join( $CRLF, $args->{headers}->@* ) . $CRLF if $args->{headers} && $args->{headers}->@*;

    $buf .= $CRLF;

    $buf .= is_ref $args->{body} ? $args->{body}->$* : $args->{body} if defined $args->{body};

    # escape "."
    $buf =~ s/\x0A[.]/\x0A../smg;

    $buf .= qq[$CRLF.$CRLF];

    encode_utf8($buf);

    $h->push_write(qq[DATA$CRLF]);

    $self->_read_response(
        $h,
        sub ($res) {
            if ( $res != 354 ) {
                $cb->($res);
            }
            else {
                $h->push_write($buf);

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

    $cb->( result [ 221, $STATUS_REASON ] );

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

                    $cb->( result [ $status, $STATUS_REASON ], $data );
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
## |    3 | 50                   | Subroutines::ProhibitExcessComplexity - Subroutine "sendmail" with high complexity score (29)                  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 167                  | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 428                  | * Private subroutine/method '_RSET' declared but not used                                                      |
## |      | 436                  | * Private subroutine/method '_VRFY' declared but not used                                                      |
## |      | 442                  | * Private subroutine/method '_NOOP' declared but not used                                                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 437                  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 470, 472             | RegularExpressions::ProhibitCaptureWithoutTest - Capture variable used outside conditional                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 53                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::SMTP - non-blocking SMTP protocol implementation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
