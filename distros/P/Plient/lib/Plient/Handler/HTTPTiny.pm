package Plient::Handler::HTTPTiny;
use strict;
use warnings;

require Plient::Handler unless $Plient::bundle_mode;
our @ISA = 'Plient::Handler';
my ( $HTTPTiny, %all_protocol, %protocol, %method );

%all_protocol = ( http => undef );
sub all_protocol { return \%all_protocol }
sub protocol     { return \%protocol }
sub method       { return \%method }

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

        # HTTPTiny doesn't support proxy auth
        return;
    }

    return $class->SUPER::support_method(@_);
}

my $inited;

sub init {
    return if $inited;
    $inited = 1;
    eval { require HTTP::Tiny } or return;
    undef $protocol{http};
    $method{http_get} = sub {
        my ( $uri, $args ) = @_;
        my $http = HTTP::Tiny->new;
        add_headers( $http, $uri, $args );
        $http->{proxy} = $ENV{http_proxy} if $ENV{http_proxy};
        my $res = $http->get($uri);

        if ( $res->{success} ) {
            return $res->{content};
        }
        else {
            warn "failed to get $uri with HTTP::Tiny: " . $res;
            return;
        }
    };

    $method{http_post} = sub {
        my ( $uri, $args ) = @_;
        my $http = HTTP::Tiny->new;
        $http->proxy( $ENV{http_proxy} ) if $ENV{http_proxy};
        add_headers( $http, $uri, $args );

        my $body;
        if ( $args->{body_hash} ) {
            for my $key ( keys %{$args->{body_hash}} ) {
                # TODO uri escape key and value
                my $val = $args->{body_hash}{$key};
                $body .= $body ? "&$key=$val" : "$key=$val";
            }
        }

        $http->{default_headers}{'Content-Type'} =
          'application/x-www-form-urlencoded'
          unless $http->{default_headers}{'Content-Type'};

        my $res = $http->request(
            'POST', $uri,
            {
                defined $body
                ? ( content => $body )
                : ()
            }
        );

        if ( $res->{success} ) {
            return $res->{content};
        }
        else {
            warn "failed to post $uri with HTTP::Tiny: " . $res;
            return;
        }
    };

    return 1;
}

sub add_headers {
    my ( $http, $uri, $args ) = @_;
    my $headers = $args->{headers} || {};
    for my $k ( keys %$headers ) {
        $http->{default_headers}{$k} = $headers->{$k};
    }

    if ( $args->{user} && defined $args->{password} ) {
        my $method = lc $args->{auth_method} || 'basic';
        if ( $method eq 'basic' ) {
            require MIME::Base64;
            $http->{default_headers}{"Authorization"} = 'Basic '
              . MIME::Base64::encode_base64( "$args->{user}:$args->{password}",
                '' );
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

Plient::Handler::HTTPTiny - 


=head1 SYNOPSIS

    use Plient::Handler::HTTPTiny;

=head1 DESCRIPTION


=head1 INTERFACE

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

