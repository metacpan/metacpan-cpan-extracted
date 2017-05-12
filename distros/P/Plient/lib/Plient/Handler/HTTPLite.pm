package Plient::Handler::HTTPLite;
use strict;
use warnings;

require Plient::Handler unless $Plient::bundle_mode;
our @ISA = 'Plient::Handler';
my ( $HTTPLite, %all_protocol, %protocol, %method );

%all_protocol = ( http => undef );
sub all_protocol { return \%all_protocol }
sub protocol { return \%protocol }
sub method { return \%method }

sub support_method {
    my $class = shift;
    my ( $method, $args ) = @_;
    if (   $args
        && $args->{content_type}
        && $args->{content_type} =~ 'form-data' )
    {
        return;
    }

    if ( $ENV{http_proxy} && $ENV{http_proxy} =~ /@/ ) {
        # HTTPLite doesn't support proxy auth
        return;
    }

    return $class->SUPER::support_method(@_);
}

my $inited;
sub init {
    return if $inited;
    $inited = 1;
    eval { require HTTP::Lite } or return;
    undef $protocol{http};
    $method{http_get} = sub {
        my ( $uri, $args ) = @_;
        my $http  = HTTP::Lite->new;
        add_headers( $http, $uri, $args );
        $http->proxy( $ENV{http_proxy} ) if $ENV{http_proxy};
        my $res = $http->request($uri) || '';

        if ( $res == 200 || $res == 301 || $res == 302 ) {

            # XXX TODO handle redirect
            return $http->body;
        }
        else {
            warn "failed to get $uri with HTTP::Lite: "  . $res;
            return;
        }
    };

    $method{http_post} = sub {
        my ( $uri, $args ) = @_;
        my $http  = HTTP::Lite->new;
        $http->proxy( $ENV{http_proxy} ) if $ENV{http_proxy};
        add_headers( $http, $uri, $args );
        $http->prepare_post( $args->{body_hash} ) if $args->{body_hash};
        my $res = $http->request($uri) || '';
        if ( $res == 200 || $res == 301 || $res == 302 ) {

            # XXX TODO handle redirect
            return $http->body;
        }
        else {
            warn "failed to post $uri with HTTP::Lite: "  . $res;
            return;
        }
    };

    return 1;
}

sub add_headers {
    my ( $http, $uri, $args ) = @_;
    my $headers = $args->{headers} || {};
    for my $k ( keys %$headers ) {
        $http->add_req_header( $k, $headers->{$k} );
    }

    if ( $args->{user} && defined $args->{password} ) {
        my $method = lc $args->{auth_method} || 'basic';
        if ( $method eq 'basic' ) {
            require MIME::Base64;
            $http->add_req_header( "Authorization",
                'Basic '
                  . MIME::Base64::encode_base64( "$args->{user}:$args->{password}", '' )
            );
        }
        else {
            die "aborting: unsupported auth method: $method";
        }
    }
}

__PACKAGE__->_add_to_plient if $Plient::bundle_mode;

1;

__END__

=head1 NAME

Plient::Handler::HTTPLite - 


=head1 SYNOPSIS

    use Plient::Handler::HTTPLite;

=head1 DESCRIPTION


=head1 INTERFACE

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

