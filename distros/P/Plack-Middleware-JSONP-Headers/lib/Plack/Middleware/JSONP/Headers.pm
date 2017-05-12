package Plack::Middleware::JSONP::Headers;
{
  $Plack::Middleware::JSONP::Headers::VERSION = '0.11';
}
#ABSTRACT: Wraps JSON response with HTTP headers in JSONP
use strict;

use parent qw(Plack::Middleware);

use Plack::Util;
use Plack::Builder;
use URI::Escape ();
use JSON ();
use Scalar::Util 'reftype';
use HTTP::Headers ();
use Plack::Util::Accessor qw(callback_key headers template);

sub prepare_app {
    my $self = shift;

    unless (defined $self->callback_key) {
        $self->callback_key('callback');
    }
    
    unless (defined $self->headers) {
        $self->headers( sub { 1 } );
    }

    unless (reftype $self->headers eq 'CODE') {
        my $headers = $self->headers;
        if (ref $self->headers eq ref qr//) {
            $self->headers( sub { $_[0] =~ $headers; } );
        } elsif (reftype $self->headers eq 'ARRAY') {
            $self->headers( sub { grep { $_[0] eq $_ } @$headers } );
        } else {
            die "headers must be code, array, or regexp";
        }
    }

    unless ($self->template) {
        $self->template('{ "meta": %s, "data": %s }')
    }
}

sub wrap_json {
    my ($self, $status, $headers, $data) = @_;

    my $meta = { status => $status }; 
    my @links;

    $headers->iter(    sub {
        my ($key, $value) = @_;
        return unless $self->headers->($key, $value);
        if ($key eq 'Link') {
            push @{$meta->{'Link'}}, $self->parse_link_header( $value );
        } else {
            $meta->{$key} = $value; # just ignores repeatable headers
        }
    });
    
    $meta->{Link} = \@links if @links;
    $meta = JSON->new->encode( $meta );

    sprintf $self->template, $meta, $data;
}

sub parse_link_header {
    my ($self, $link) = @_;

    my @links;

    while( $link =~ /^(\s*<([^>]*)>\s*[;,]?\s*)/) {
        my $url = $2;
        $link = substr($link, length($1));
        my %attr = ();
        while ($link =~ /^((\/|[a-z0-9-]+\*?)\s*\=\s*("[^"]*"|[^\s\"\;\,]+)\s*[;,]?\s*)/i) {
            $link = substr($link, length($1));
            my $key = lc $2;
            my $val = $3;
            $val =~ s/(^"|"$)//g if ($val =~ /^".*"$/);
            $attr{$key} = $val;
        }
        push @links, [ $url, \%attr ];
    }

    return @links;
}

# Most of this method is copied from Plack::Middleware::JSONP. 
# I found no easy way to reuse this module, so it had to be forked.
sub call {
    my($self, $env) = @_;
    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        if (defined $res->[2]) {
            my $h = Plack::Util::headers($res->[1]);
            my $callback_key = $self->callback_key;
            if ($h->get('Content-Type') =~ m!/(?:json|javascript)! &&
                $env->{QUERY_STRING} =~ /(?:^|&)$callback_key=([^&]+)/) {
                my $cb = URI::Escape::uri_unescape($1);
                if ($cb =~ /^[\w\.\[\]]+$/) {
                    my $body;
                    Plack::Util::foreach($res->[2], sub { $body .= $_[0] });
                    
                    # this line added
                      $body = $self->wrap_json( $res->[0], $h, $body );

                    my $jsonp = "$cb($body)";
                    $res->[2] = [ $jsonp ];
                    $h->set('Content-Length', length $jsonp);
                    $h->set('Content-Type', 'text/javascript');
                }
            }
        }
    });
}

1;



__END__
=pod

=head1 NAME

Plack::Middleware::JSONP::Headers - Wraps JSON response with HTTP headers in JSONP

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    enable "JSONP::Headers", 
        callback_key => 'callback',
        headers      => qr/^(X-|Link$)/,
        template     => '{ "meta": %s, "data": %s }';

=head1 DESCRIPTION

Plack::Middleware::JSONP::Headers wraps JSON response in JSONP (just like
L<Plack::Middleware::JSONP>) and adds HTTP header information. For instance
the JSON response

    { "foo": "bar" }

with query parameter C<callback> set to C<doz> is wrapped to

    doz({ 
      "meta": { 
        "status": 200, 
        "Content-Type": "application/javascript"
      }, 
      "data": { "foo": "bar" }
    })

The HTTP headers to be wrapped can be configured. All header values are
returned as strings (repeatable headers are ignored) with one exception:
Link-headers are parsed and returned as array of C<<[ url, options ]>>
tuples.

Same as Plack::Middleware::JSONP this middleware only works with a
non-streaming response.

=head1 CONFIGURATION

=over 4

=item callback_key

Callback query parameter. Set to C<callback> by default.

=item headers

List of HTTP headers or regular expression of headers to add to the response.
One can alternatively pass a code reference that gets each header as key-value
pair. By default all headers are wrapped.

=item template

String template for C<sprintf> to construct the JSON response from HTTP headers
(first) and original response (second). Set to C<{ "meta": %s, "data": %s }> by
default.

=back

=head1 SEE ALSO

Inspired by L<http://developer.github.com/v3/#json-p-callbacks>.

=encoding utf8

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

