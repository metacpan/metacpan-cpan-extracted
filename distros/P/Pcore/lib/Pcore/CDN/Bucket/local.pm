package Pcore::CDN::Bucket::local;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_plain_arrayref is_plain_coderef];

with qw[Pcore::CDN::Bucket];

has locations => ();         # HashRef
has prefix    => ('/cdn');

has libs       => ( init_arg => undef );    # ArrayRef
has write_path => ( init_arg => undef );
has is_local => ( 1, init_arg => undef );

sub BUILD ( $self, $args ) {

    # load libs
    for my $path ( $args->{libs}->@* ) {

        # $path is absolute
        if ( $path =~ m[\A/]sm ) {
            P->file->mkpath( $path, mode => 'rwxr-xr-x' ) || die qq[Can't create CDN path "$path", $!] if !-d $path;

            $self->{write_path} //= $path;
        }

        # $path is dist name
        else {
            P->class->load( $path =~ s/-/::/smgr );

            $path = $ENV->{share}->get_storage( $path, 'cdn' );

            next if !$path;
        }

        push $self->{libs}->@*, "$path";
    }

    return;
}

sub get_nginx_cfg ($self) {
    my $tmpl = <<'TMPL';
    # cdn
    location <: $prefix :>/ {
        error_page 418 = @<: $libs[0] :>;
        set $cache_control "<: $locations["/"] :>";
        return 418;
: for $locations.keys().sort() -> $location {
: next if $location == "/"

        location <: $prefix :><: $location :> {
            set $cache_control "<: $locations[$location] :>";
            return 418;
        }
: }
    }
:for $libs -> $path {

    location @<: $path :> {
        root          <: $path :>;
        add_header    Cache-Control $cache_control;
: if ( $~path.is_last ) {
        try_files     /../$uri =404;
: }
: else {
        try_files     /../$uri @<: $~path.peek_next :>;
: }
    }
: }
TMPL

    return P->tmpl->(
        \$tmpl,
        {   prefix    => $self->{prefix},
            locations => $self->{locations},
            libs      => $self->{libs},
        }
    )->$*;
}

# TODO check path
sub upload ( $self, $path, $data, @args ) {
    my $cb = is_plain_coderef $_[-1] ? pop @args : ();

    die q[Bucket has no default write path] if !$self->{write_path};

    state $on_finish = sub ( $cb, $res ) {
        if ($cb) {
            return $cb->($res);
        }
        else {
            return $res;
        }
    };

    $path = P->path("$self->{write_path}/$path");

    # TODO check, that path is child
    # return $on_finish->( $cb, res 404 );

    P->file->mkpath( $path->{dirname}, mode => 'rwxr-xr-x' ) || return res [ 500, qq[Can't create CDN path "$path", $!] ] if !-d $path->{dirname};

    P->file->write_bin( $path, { mode => 'rw-r--r--' }, $data );    # TODO or return res [ 500, qq[Can't write "$path", $!] ];

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
