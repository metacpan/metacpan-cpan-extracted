package Pcore::App::Controller;

use Pcore -role;

has app  => ( required => 1 );    # ConsumerOf ['Pcore::App']
has path => ( required => 1 );    # HTTP controller url path, always finished with "/"

sub run ( $self, $req ) {
    return 404;
}

sub get_abs_path ( $self, $path ) {
    if ( $self->{path} eq '/' ) {
        return "/$path";
    }
    else {
        return "$self->{path}/$path";
    }
}

sub get_nginx_cfg ($self) {
    my $tmpl = <<'NGINX';
    # "<: $location :>"
: if $location == '/' {
    location =/ {
        error_page 418 = @backend;
        return 418;
    }

    location / {
        rewrite ^/favicon.ico$ /cdn/favicon.ico last;
        rewrite ^/robots.txt$ /cdn/robots.txt last;

        error_page 418 = @backend;
        return 418;
    }
: } else {
    location =<: $location :> {
        error_page 418 = @backend;
        return 418;
    }

    location <: $location :>/ {
        error_page 418 = @backend;
        return 418;
    }
: }
NGINX

    return P->tmpl->( \$tmpl, { location => $self->{path} } )->$*;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
