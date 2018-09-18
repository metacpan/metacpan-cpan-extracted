package Plack::App::FakeApache1::Constants;

{
  $Plack::App::FakeApache1::Constants::DIST = 'Plack-App-FakeApache1';
}
$Plack::App::FakeApache1::Constants::VERSION = '0.0.6';
# ABSTRACT: Define Apache1 constants
use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [ qw/
        OK
        DONE
        DECLINED
        REDIRECT

        HTTP_OK

        HTTP_MOVED_TEMPORARILY

        HTTP_BAD_REQUEST
        HTTP_UNAUTHORIZED
        HTTP_PAYMENT_REQUIRED
        HTTP_FORBIDDEN
        HTTP_NOT_FOUND
        HTTP_METHOD_NOT_ALLOWED
        HTTP_NOT_ACCEPTABLE
        HTTP_PROXY_AUTHENTICATION_REQUIRED
        HTTP_REQUEST_TIME_OUT
        HTTP_CONFLICT
        HTTP_GONE
        HTTP_LENGTH_REQUIRED
        HTTP_PRECONDITION_FAILED
        HTTP_REQUEST_ENTITY_TOO_LARGE
        HTTP_REQUEST_URI_TOO_LARGE
        HTTP_UNSUPPORTED_MEDIA_TYPE
        HTTP_RANGE_NOT_SATISFIABLE
        HTTP_EXPECTATION_FAILED
        HTTP_UNPROCESSABLE_ENTITY
        HTTP_LOCKED
        HTTP_FAILED_DEPENDENCY
        HTTP_INTERNAL_SERVER_ERROR
    / ],
    groups => {
        default => [ qw/OK/ ],
        common  => [ qw/OK DONE DECLINED REDIRECT/ ],
        http    => [ qw/HTTP_MOVED_TEMPORARILY/ ],
        '2xx'   => [ qw/HTTP_OK/ ],
        '3xx'   => [ qw/HTTP_MOVED_TEMPORARILY/ ],
        '4xx'   => [ qw/
                        HTTP_BAD_REQUEST
                        HTTP_UNAUTHORIZED
                        HTTP_PAYMENT_REQUIRED
                        HTTP_FORBIDDEN
                        HTTP_NOT_FOUND
                        HTTP_METHOD_NOT_ALLOWED
                        HTTP_NOT_ACCEPTABLE
                        HTTP_PROXY_AUTHENTICATION_REQUIRED
                        HTTP_REQUEST_TIME_OUT
                        HTTP_CONFLICT
                        HTTP_GONE
                        HTTP_LENGTH_REQUIRED
                        HTTP_PRECONDITION_FAILED
                        HTTP_REQUEST_ENTITY_TOO_LARGE
                        HTTP_REQUEST_URI_TOO_LARGE
                        HTTP_UNSUPPORTED_MEDIA_TYPE
                        HTTP_RANGE_NOT_SATISFIABLE
                        HTTP_EXPECTATION_FAILED
                        HTTP_UNPROCESSABLE_ENTITY
                        HTTP_LOCKED
                        HTTP_FAILED_DEPENDENCY
                     /],
        '5xx'   => [ qw/HTTP_INTERNAL_SERVER_ERROR/ ],
    },
};

# useful values from httpd.h
# added on a 'needed to use' basis

# 2xx status codes
sub HTTP_OK                            { 200; }

# 3xx status codes
sub HTTP_MOVED_TEMPORARILY             { 302; }

# 4xx status codes
sub HTTP_BAD_REQUEST                   { 400; }
sub HTTP_UNAUTHORIZED                  { 401; }
sub HTTP_PAYMENT_REQUIRED              { 402; }
sub HTTP_FORBIDDEN                     { 403; }
sub HTTP_NOT_FOUND                     { 404; }
sub HTTP_METHOD_NOT_ALLOWED            { 405; }
sub HTTP_NOT_ACCEPTABLE                { 406; }
sub HTTP_PROXY_AUTHENTICATION_REQUIRED { 407; }
sub HTTP_REQUEST_TIME_OUT              { 408; }
sub HTTP_CONFLICT                      { 409; }
sub HTTP_GONE                          { 410; }
sub HTTP_LENGTH_REQUIRED               { 411; }
sub HTTP_PRECONDITION_FAILED           { 412; }
sub HTTP_REQUEST_ENTITY_TOO_LARGE      { 413; }
sub HTTP_REQUEST_URI_TOO_LARGE         { 414; }
sub HTTP_UNSUPPORTED_MEDIA_TYPE        { 415; }
sub HTTP_RANGE_NOT_SATISFIABLE         { 416; }
sub HTTP_EXPECTATION_FAILED            { 417; }
sub HTTP_UNPROCESSABLE_ENTITY          { 422; }
sub HTTP_LOCKED                        { 423; }
sub HTTP_FAILED_DEPENDENCY             { 424; }

# 5xx status codes
sub HTTP_INTERNAL_SERVER_ERROR         { 500; }

sub DONE        { -2; }
sub DECLINED    { -1; }
sub OK          {  0; }
sub REDIRECT    { HTTP_MOVED_TEMPORARILY; }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::FakeApache1::Constants - Define Apache1 constants

=head1 VERSION

version 0.0.6

=head1 2xx Status Codes

=head2 HTTP_OK

=head1 3xx Status Codes

=head2 HTTP_MOVED_TEMPORARILY

=head1 4xx Status Codes

=head2 HTTP_BAD_REQUEST

=head2 HTTP_UNAUTHORIZED

=head2 HTTP_PAYMENT_REQUIRED

=head2 HTTP_FORBIDDEN

=head2 HTTP_NOT_FOUND

=head2 HTTP_METHOD_NOT_ALLOWED

=head2 HTTP_NOT_ACCEPTABLE

=head2 HTTP_PROXY_AUTHENTICATION_REQUIRED

=head2 HTTP_REQUEST_TIME_OUT

=head2 HTTP_CONFLICT

=head2 HTTP_GONE

=head2 HTTP_LENGTH_REQUIRED

=head2 HTTP_PRECONDITION_FAILED

=head2 HTTP_REQUEST_ENTITY_TOO_LARGE

=head2 HTTP_REQUEST_URI_TOO_LARGE

=head2 HTTP_UNSUPPORTED_MEDIA_TYPE

=head2 HTTP_RANGE_NOT_SATISFIABLE

=head2 HTTP_EXPECTATION_FAILED

=head2 HTTP_UNPROCESSABLE_ENTITY

=head2 HTTP_LOCKED

=head2 HTTP_FAILED_DEPENDENCY

=head1 5xx Status Codes

=head2 HTTP_INTERNAL_SERVER_ERROR

=head1 APACHE1 RETURN CODES

=head2 DONE

=head2 DECLINED

=head2 OK

=head2 REDIRECT

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
