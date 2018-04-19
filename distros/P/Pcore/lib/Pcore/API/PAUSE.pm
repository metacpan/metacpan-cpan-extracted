package Pcore::API::PAUSE;

use Pcore -class, -res;
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::Scalar qw[is_coderef];

has username => ( is => 'ro', isa => Str, required => 1 );
has password => ( is => 'ro', isa => Str, required => 1 );

has _auth_header => ( is => 'lazy', isa => Str, init_arg => undef );

sub _build__auth_header ($self) {
    return 'Basic ' . P->data->to_b64_url( encode_utf8( $self->username ) . q[:] . encode_utf8( $self->password ) ) . q[==];
}

sub upload ( $self, $path, $cb = undef ) {
    my $body;

    $path = P->path($path);

    my $boundary = P->random->bytes_hex(64);

    $self->_pack_multipart( \$body, $boundary, 'HIDDENNAME', \encode_utf8( $self->username ) );

    $self->_pack_multipart( \$body, $boundary, 'pause99_add_uri_subdirtext', \q[] );

    $self->_pack_multipart( \$body, $boundary, 'CAN_MULTIPART', \1 );

    $self->_pack_multipart( \$body, $boundary, 'pause99_add_uri_upload', \$path->filename );

    $self->_pack_multipart( \$body, $boundary, 'pause99_add_uri_httpupload', P->file->read_bin($path), $path->filename );

    $self->_pack_multipart( \$body, $boundary, 'pause99_add_uri_uri', \q[] );

    $self->_pack_multipart( \$body, $boundary, 'SUBMIT_pause99_add_uri_httpupload', \q[ Upload this file from my disk ] );

    $body .= q[--] . $boundary . q[--] . $CRLF . $CRLF;

    return P->http->post(
        'https://pause.perl.org/pause/authenquery',
        headers => {
            AUTHORIZATION => $self->_auth_header,
            CONTENT_TYPE  => qq[multipart/form-data; boundary=$boundary],
        },
        body => \$body,
        $cb // ()
    );
}

sub clean ( $self, @args ) {
    my $rouse_cb = defined wantarray ? Coro::rouse_cb : ();

    my $cb = is_coderef $args[-1] ? pop @args : undef;

    my %args = (
        keep => 2,
        @args,
    );

    my $on_finish = sub ($res) {
        $rouse_cb ? $cb ? $rouse_cb->( $cb->($res) ) : $rouse_cb->($res) : $cb ? $cb->($res) : ();

        return;
    };

    if ( !$args{keep} ) {
        $on_finish->( res [ 400, q[Bad "keep" arument.] ] );
    }

    P->http->get(
        'https://pause.perl.org/pause/authenquery?ACTION=delete_files',
        headers => { AUTHORIZATION => $self->_auth_header, },
        sub ($res) {
            if ( !$res ) {
                $on_finish->( res [ $res->{status}, $res->{reason} ] );
            }
            else {
                my $releases;

                while ( $res->{body}->$* =~ /input type="checkbox" name="pause99_delete_files_FILE" value="([[:alnum:]-]+)?-v([[:alnum:].]+)?[.]tar[.]gz"(.+?)<\/span>/smg ) {
                    $releases->{$1}->{$2} = undef if $3 !~ m[Scheduled for deletion]smi;
                }

                my $params = [
                    HIDDENNAME                         => encode_utf8( $self->username ),
                    SUBMIT_pause99_delete_files_delete => 'Delete',
                ];

                my $releases_to_remove;

                for my $release ( keys $releases->%* ) {
                    my $versions = [ map {"$_"} reverse sort map { version->new($_) } keys $releases->{$release}->%* ];

                    # keep last releases
                    splice $versions->@*, 0, $args{keep}, ();

                    if ( $versions->@* ) {
                        for my $version ( $versions->@* ) {
                            $releases_to_remove->{"$release-v$version"} = undef;

                            push $params->@*, pause99_delete_files_FILE => "$release-v$version.tar.gz";
                            push $params->@*, pause99_delete_files_FILE => "$release-v$version.meta";
                            push $params->@*, pause99_delete_files_FILE => "$release-v$version.readme";
                        }
                    }
                }

                if ( !$releases_to_remove ) {
                    $on_finish->( res [ 200, 'Nothing to do' ] );
                }
                else {
                    P->http->post(
                        'https://pause.perl.org/pause/authenquery',
                        headers => {
                            AUTHORIZATION => $self->_auth_header,
                            CONTENT_TYPE  => 'application/x-www-form-urlencoded',
                        },
                        body => P->data->to_uri($params),
                        sub ($res) {
                            $on_finish->( res [ $res->{status}, $res->{reason} ], [ sort keys $releases_to_remove->%* ] );

                            return;
                        }
                    );
                }
            }

            return;
        }
    );

    return $rouse_cb ? Coro::rouse_wait $rouse_cb : ();
}

sub _pack_multipart ( $self, $body, $boundary, $name, $content, $filename = undef ) {
    $body->$* .= q[--] . $boundary . $CRLF;

    $body->$* .= qq[Content-Disposition: form-data; name="$name"];

    $body->$* .= qq[; filename="$filename"] if $filename;

    $body->$* .= $CRLF x 2;

    $body->$* .= $content->$*;

    $body->$* .= $CRLF;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 80                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 135                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::PAUSE - pause.perl.org API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
