package Pcore::API::PAUSE;

use Pcore -class, -res;
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::Scalar qw[is_coderef];

has username => ( required => 1 );
has password => ( required => 1 );

has _auth_header => ( is => 'lazy', init_arg => undef );

sub _build__auth_header ($self) {
    return 'Basic ' . P->data->to_b64_url( encode_utf8( $self->{username} ) . q[:] . encode_utf8( $self->{password} ) ) . q[==];
}

sub upload ( $self, $path, $cb = undef ) {
    my $body;

    $path = P->path($path);

    my $boundary = P->random->bytes_hex(64);

    $self->_pack_multipart( \$body, $boundary, 'HIDDENNAME', \encode_utf8( $self->{username} ) );

    $self->_pack_multipart( \$body, $boundary, 'pause99_add_uri_subdirtext', \$EMPTY );

    $self->_pack_multipart( \$body, $boundary, 'CAN_MULTIPART', \1 );

    $self->_pack_multipart( \$body, $boundary, 'pause99_add_uri_upload', \$path->{filename} );

    $self->_pack_multipart( \$body, $boundary, 'pause99_add_uri_httpupload', \P->file->read_bin($path), $path->{filename} );

    $self->_pack_multipart( \$body, $boundary, 'pause99_add_uri_uri', \$EMPTY );

    $self->_pack_multipart( \$body, $boundary, 'SUBMIT_pause99_add_uri_httpupload', \q[ Upload this file from my disk ] );

    $body .= "--$boundary--\r\n\r\n";

    return P->http->post(
        'https://pause.perl.org/pause/authenquery',
        headers => [
            Authorization  => $self->_auth_header,
            'Content-Type' => qq[multipart/form-data; boundary=$boundary],
        ],
        data => \$body,
        $cb // ()
    );
}

sub clean ( $self, @args ) {
    my %args = (
        keep => 2,
        @args,
    );

    return res [ 400, q[Bad "keep" arument.] ] if !$args{keep};

    my $res = P->http->get( 'https://pause.perl.org/pause/authenquery?ACTION=delete_files', headers => [ Authorization => $self->_auth_header ] );

    return res [ $res->{status}, $res->{reason} ] if !$res;

    my $releases;

    for my $node ( $res->tree->findnodes(q[//tbody[@class="list"]/tr]) ) {
        my ( $name, $ver ) = $node->findvalue(q[./td[@class="file"]]) =~ /\A(.+)-v([[:alnum:].]+)[.]tar[.]gz\z/sm;

        next if !$name;

        next if $node->findvalue(q[./td[@class="modified"]]) =~ /Scheduled for deletion/sm;

        $releases->{$name}->{$ver} = undef;
    }

    my $params = [
        HIDDENNAME                         => uc encode_utf8( $self->{username} ),
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

    return res [ 200, 'Nothing to do' ] if !$releases_to_remove;

    $res = P->http->post(
        'https://pause.perl.org/pause/authenquery?ACTION=delete_files',
        headers => [
            Authorization  => $self->_auth_header,
            'Content-Type' => 'application/x-www-form-urlencoded',
        ],
        data => P->data->to_uri($params),
    );

    return res [ $res->{status}, $res->{reason} ], [ sort keys $releases_to_remove->%* ];
}

sub _pack_multipart ( $self, $body, $boundary, $name, $content, $filename = undef ) {
    $body->$* .= "--$boundary\r\n";

    $body->$* .= qq[Content-Disposition: form-data; name="$name"];

    $body->$* .= qq[; filename="$filename"] if $filename;

    $body->$* .= "\r\n" x 2;

    $body->$* .= $content->$*;

    $body->$* .= "\r\n";

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 112                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 64, 65, 69           | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
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
