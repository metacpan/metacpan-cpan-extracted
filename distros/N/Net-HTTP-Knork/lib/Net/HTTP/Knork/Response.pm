package Net::HTTP::Knork::Response;

# ABSTRACT: Portable HTTP Response object for SPORE response
use Moo;
extends 'HTTP::Response';

use overload
  '@{}'    => \&finalize,
  '""'     => \&to_string,
  fallback => 1;


has 'body' => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        return $_[0]->content;
    },
    trigger => sub {
        my ( $self, $body_new_value ) = @_;
        $self->raw_body($body_new_value);
    }
);

has 'raw_body' => (
    is => 'rw',
);

has 'request' => (
    is => 'rw',
);

sub FOREIGNBUILDARGS {
    my $class = shift;
    my ( $rc, $message, $headers, $body ) = @_;
    return ( $rc, $message, $headers, $body );
}


sub env            { shift->request->env }
sub content_type   { shift->headers->content_type(@_) }
sub content_length { shift->headers->content_length(@_) }
sub location       { shift->headers->header( 'Location' => @_ ) }
sub header         { shift->headers->header(@_) }
sub to_string      { shift->as_string }
sub status         { shift->code(@_) }


sub finalize {
    my $self = shift;
    return [
        $self->status,
        +[  map {
                my $k = $_;
                map { ( $k => $_ ) } $self->headers->header($_);
            } $self->headers->header_field_names
        ],
        $self->body,
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Knork::Response - Portable HTTP Response object for SPORE response

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    use Net:HTTP::Knork::Response;

    my $response = Net::HTTP::Knork::Response->new(
        200, ['Content-Type', 'application/json'], '{"foo":1}';
    );
    $response->request($request);

=head1 DESCRIPTION

Net::HTTP::Knork::Response : create a HTTP response
Most of the code was adapted from Net::HTTP::Spore::Response, with two main differences : 
  - it uses Moo
  - it is a subclass of HTTP::Response

=head1 METHODS

=over 4

=item new

    my $res = Net::HTTP::Knork::Response->new;
    my $res = Net::HTTP::Knork::Response->new($status);
    my $res = Net::HTTP::Knork::Response->new($status, $message, $headers);
    my $res = Net::HTTP::Knork::Response->new($status, $message, $headers, $body);

Creates a new Net::HTTP::Knork::Response object.

=item code

=item status

    $res->status(200);
    my $status = $res->status;

Gets or sets the HTTP status of the response

=item env 
   $res->env($env);
   my $env = $res->env;

Gets or sets the environment for the response. Shortcut to C<< $res->request->env >>

=item content

=item body

    $res->body($body);
    my $body = $res->body;

Gets or sets the body for the response

=item raw_body

    my $raw_body = $res->raw_body

The raw_body value is the same as body when the body is sets for the first time.

=item content_type

    $res->content_type('application/json');
    my $ct = $res->content_type;

Gets or sets the content type of the response body

=item content_length

    $res->content_length(length($body));
    my $cl = $res->content_length;

Gets or sets the content type of the response body

=item location

    $res->location('http://example.com');
    my $location = $res->location;

Gets or sets the location header for the response

=item request

    $res->request($request);
    $request = $res->request;

Gets or sets the HTTP request that created the current HTTP response.

=item headers

    $headers = $res->headers;
    $res->headers(['Content-Type' => 'application/json']);

Gets or sets HTTP response headers.

=item header

    my $cl = $res->header('Content-Length');
    $res->header('Content-Type' => 'application/json');

Shortcut for C<< $res->headers->header >>.

=item finalise

    my $res = Net::HTTP::Knork::Response->new($status, $headers, $body);
    say "http status is ".$res->[0];

Return an arrayref:

=over 2

=item status

The first element of the array ref is the HTTP status

=item headers

The second element is an arrayref containing the list of HTTP headers

=item body

The third and final element is the body

=back

=back

=head1 AUTHOR

Emmanuel Peroumalnaïk

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by E. Peroumalnaik.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
