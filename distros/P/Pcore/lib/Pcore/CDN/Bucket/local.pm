package Pcore::CDN::Bucket::local;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_plain_scalarref is_plain_arrayref is_plain_coderef];

with qw[Pcore::CDN::Bucket];

has prefix => ('/cdn');

has locations       => ( init_arg => undef );    # ArrayRef
has upload_location => ( init_arg => undef );
has is_local => ( 1, init_arg => undef );

sub BUILD ( $self, $args ) {

    # locations
    for my $location ( $args->{locations}->@* ) {

        # location is absolute
        if ( $location =~ m[\A/]sm ) {
            P->file->mkpath( $location, mode => 'rwxr-xr-x' ) || die qq[Can't create CDN path "$location", $!] if !-d $location;

            $self->{can_upload} = 1;
            $self->{upload_location} //= $location;
        }

        # location is dist name
        else {
            P->class->load( $location =~ s/-/::/smgr );

            $location = $ENV->{share}->get_location("/$location/cdn");

            next if !$location;
        }

        push $self->{locations}->@*, "$location";
    }

    return;
}

sub get_nginx_cfg ( $self, $cache_control ) {
    my $tmpl = <<'TMPL';
    # cdn
    location <: $prefix :>/ {
        error_page 418 = @<: $locations[0] :>;
        return 418;
: for $cache_control.sort() -> $cache_control_location {

        location <: $prefix :>/<: $cache_control_location.path :>/ {
            set $cache_control "<: $cache_control_location.cache_control :>";
            return 418;
        }
: }
    }
:for $locations -> $location {

    location @<: $location :> {
        root          <: $location :>;
        add_header    Cache-Control $cache_control;
: if ( $~location.is_last ) {
        try_files     /../$uri =404;
: }
: else {
        try_files     /../$uri @<: $~location.peek_next :>;
: }
    }
: }
TMPL

    return P->tmpl->(
        \$tmpl,
        {   prefix        => $self->{prefix},
            locations     => $self->{locations},
            cache_control => $cache_control,
        }
    )->$*;
}

# TODO check path
sub upload ( $self, $path, $data, @args ) {
    my $cb = is_plain_coderef $_[-1] ? pop @args : ();

    die q[Can't upload to bucket] if !$self->{can_upload};

    state $on_finish = sub ( $cb, $res ) {
        if ($cb) {
            return $cb->($res);
        }
        else {
            return $res;
        }
    };

    $path = P->path("$self->{upload_location}/$path");

    # TODO check, that path is child
    # return $on_finish->( $cb, res 404 );

    P->file->mkpath( $path->{dirname}, mode => 'rwxr-xr-x' ) || return $on_finish->( $cb, res [ 500, qq[Can't create CDN path "$path", $!] ] ) if !-d $path->{dirname};

    if ( is_plain_scalarref $data) {
        P->file->write_bin( $path, { mode => 'rw-r--r--' }, $data );    # TODO or return res [ 500, qq[Can't write "$path", $!] ];
    }
    else {
        P->file->copy( $data, $path, mode => 'rw-r--r--' );             # TODO or return res [ 500, qq[Can't write "$path", $!] ];
    }

    return $on_finish->( $cb, res 200 );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::CDN::Bucket::local

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
