package Plack::Middleware::LimitRequest;

use strict;
use warnings;
use 5.008_001;
use Carp;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(body fields field_size line);

our $VERSION = '0.02';

sub prepare_app {
    my $self = shift;
    $self->body(0)          if ! defined $self->body;
    $self->fields(100)      if ! defined $self->fields;
    $self->field_size(8190) if ! defined $self->field_size;
    $self->line(8190)       if ! defined $self->line;
}

sub call {
    my($self, $env) = @_;

    # HTTP request body size limitation
    if (my $body_limit = $self->body) {
        if (my $content_length = $env->{CONTENT_LENGTH}) {
            if ($content_length > $body_limit) {
                return $self->handle_error(413 => 'Entity Too Large');
             }
        }
    }

    # HTTP request line length limitation
    if (my $line_limit = $self->line) {
        my $total = 0;
        for my $env_key (qw(REQUEST_METHOD REQUEST_URI SERVER_PROTOCOL)) {
            $total += length $env->{$env_key};
            if ($env_key ne 'SERVER_PROTOCOL') { # append a white space
                ++$total;
            }
            if ($total > $line_limit) {
                return $self->handle_error(414 => 'Request-URI Too Large');
            }
        }
    }

    # HTTP request header field number and field size limitation
    my $limit_fields     = $self->fields;
    my $limit_field_size = $self->field_size;

    if ($limit_fields or $limit_field_size) {
        my $field_count = 1; # includes the request line
        for my $env_key (keys %$env) {
            next if $env_key !~ /^(?:HTTP_\w+|CONTENT_(?:TYPE|LENGTH))$/;
            ++$field_count;
            if ($limit_fields && $field_count > $limit_fields) {
                return $self->handle_error(400 => 'Bad Request');
            }
            if ($limit_field_size) {
                (my $field_name = $env_key) =~ s/^HTTP_//;
                # "2" means length of separator ": "
                my $field_size =
                    length($field_name) + 2 + length($env->{$env_key});
                if ($field_size > $limit_field_size) {
                    return $self->handle_error(400 => 'Bad Request');
                }
            }
        }
    }

    return $self->app->($env);
}

sub handle_error {
    my($self, $code, $body) = @_;
    return [
        $code,
        [
            'Content-Type'   => 'text/plain',
            'Content-Length' => length $body,
        ],
        [ $body ],
    ];
}

1;
__END__

=head1 NAME

Plack::Middleware::LimitRequest - HTTP Request Limitation for Plack apps

=head1 SYNOPSIS

 use Plack::Builder;
 
 my $app = sub { ... };
 
 builder {
     enable 'LimitRequest',
         body       => 102400,
         fields     => 50,
         field_size => 4094,
         line       => 4094
         ;
     $app;
 };

=head1 DESCRIPTION

Plack::Middleware::LimitRequest provides HTTP request size limitation for
HTTP request body, the number of request header fields,
size of an HTTP request header field and size of a client's HTTP request-line.
It works similar to Apache core directives,
C<LimitRequestBody>, C<LimitRequestFields>, C<LimitRequestFieldSize> and
C<LimitRequestLine>.
This is useful to protect against kind of DDoS attacks.

If your application is working behind some Apache reverse proxy servers
(using mod_proxy module), most of directives above works correctly,
B<so you should configure them on the Apache configuration>.
But, only C<LimitRequestBody> directive does not work for proxied requests.
This module solves, especially in the case that demand to limit
for the size of HTTP request body.

=head1 ARGUMENTS

=head2 body

It allows to set a limit on the allowed size of an HTTP request message body.
Default is C<0>.
If you don't want to limit the size, set this argument to
C<0> (means unlimited) or unset (omit it on your .psgi file).

=head2 fields

It allows to modify the limit on the number of request header fields
allowed in an HTTP request. Default is C<100>.
If you don't want to limit the number, set this argument to
C<0> (means unlimited).

=head2 field_size

It allows to set the limit on the allowed size of an HTTP request header field.
Default is C<8190>.
If you don't want to limit the size, set this argument to
C<0> (means unlimited).

=head2 line

It allows to set the limit on the allowed size of a client's HTTP request-line.
Since the request-line consists of the HTTP method, URI, and protocol version.
Default is C<8190>. 
If you don't want to limit the size, set this argument to
C<0> (means unlimited).

=head1 AUTHOR

Koichi Taniguchi (a.k.a. nipotan) E<lt>taniguchi@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://httpd.apache.org/docs/2.4/en/mod/core.html>

=cut
