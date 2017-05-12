package Plack::Middleware::ServerName;

use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util;
use vars qw( $VERSION );
$VERSION = 0.02;

sub call {
    my ( $self, $env ) = @_;
    my $res = $self->app->($env);

    my $header_order = {
        'Apache/1.3.23' => [ qw( Date Server Last-Modified ETag Accept-Ranges Content-Length Keep-Alive Connection Content-Type ) ],
        'Apache/2.2.8' => [ qw( Date Server Last-Modified ETag Accept-Ranges Content-Length Keep-Alive Connection Content-Type ) ],
        'Microsoft-IIS/5.0' => [ qw( Server Expires Date Content-Type Accept-Ranges Last-Modified ETag Content-Length ) ],
        'Netscape-Enterprise/4.1' => [ qw( Server Date Content-type Last-modified Content-length Accept-ranges Connection ) ],
        'Sun-ONE-Web-Server/6.1' => [ qw( Server Date Content-length Content-type Last-Modified Etag Accept-Ranges Connection ) ],
    };

    Plack::Util::response_cb( $res, sub {
        my $res = shift();

        my $headers = {};
        my @orders = ();
        if( defined( $self->{order} ) and ( ref( $self->{order} ) eq 'ARRAY' ) ) {
            @orders = @{ $self->{order} };
        } elsif( defined( $self->{name} ) and defined( $header_order->{ $self->{name} } ) and ( ref( $header_order->{ $self->{name} } ) eq 'ARRAY' ) ) {
            @orders = @{ $header_order->{ $self->{name} } };
        }

        my $h = HTTP::Headers->new( @{ $res->[1] } );
        $h->scan( sub { push @{ $headers->{ lc( shift() ) } }, shift(); } );
        $headers->{'last-modified'} = $headers->{'date'} if( defined( $headers->{'date'} ) and !defined( $headers->{'last-modified'} ) );
        if( defined( $self->{name} ) ) {
            $headers->{'server'} = [ $self->{name} ];
        } elsif( !defined( $self->{name} ) and defined( $headers->{'server'} ) ) {
            delete $headers->{'server'};
        }

        my @output_headers = ();
        foreach my $order ( @orders ) {
            next if( !defined( $headers->{ lc( $order ) } ) );
            push @output_headers, ( $order, $_ ) foreach ( @{ $headers->{ lc( $order ) } } );
            delete $headers->{ lc( $order ) };
        }

        foreach my $header ( keys %{ $headers } ) {
            push @output_headers, ( ucfirst( $header ), $_ ) foreach ( @{ $headers->{ $header } } );
        }

        $res->[1] = \@output_headers if( scalar( @output_headers ) );

        return;
    } );
}


1;
__END__

=head1 NAME

Plack::Middleware::ServerName - sets/fakes the name of the server processing the
requests while it will try to rearrange the headers so that they can match the
real webserver you want to fake

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable "Plack::Middleware::ServerName",
          name  => 'Apache/2.2.8',
          order => [ qw( Date Server Last-Modified ETag Content-Type ) ];
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::ServerName is a middleware that allows to fakes the response
Server header by removing it ( if name is undef ) or setting it to a defined
value.

=head1 CONFIGURATIONS

=over

=item name

  name => 'Apache'
  name => 'My-Own-WebServer/0.02'

string that defines/fakes the server's name

=item order

  order => [ qw( Date Server Last-Modified ETag Accept-Ranges Content-Length Keep-Alive Connection Content-Type ) ]

arrayref with headers in the order that the server should return them
this are also case sensitive as to how the server returns them

=back

=head1 SEE ALSO

L<Plack::Middleware>

=head1 AUTHOR

Sorin Pop E<lt>sorin.pop {at} evozon.comE<gt>

=head1 LICENSE

This software is copyright (c) 2011 by Sorin Pop.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
