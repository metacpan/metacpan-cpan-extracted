package Mojo::HTTPStatus;

use Mojo::Base 'Exporter';

use Package::Constants;

use constant {
    # --- 1×× Informational
    CONTINUE                           => 100,
    SWITCHING_PROTOCOLS                => 101,
    PROCESSING                         => 102,

    # --- 2×× Success
    OK                                 => 200,
    CREATED                            => 201,
    ACCEPTED                           => 202,
    NON_AUTHORITATIVE_INFORMATION      => 203,
    NO_CONTENT                         => 204,
    RESET_CONTENT                      => 205,
    PARTIAL_CONTENT                    => 206,
    MULTI_STATUS                       => 207,
    ALREADY_REPORTED                   => 208,
    IM_USED                            => 226,
    MULTIPLE_CHOICES                   => 300,

    # -- 3×× Redirection
    MOVED_PERMANENTLY                  => 301,
    FOUND                              => 302,
    SEE_OTHER                          => 303,
    NOT_MODIFIED                       => 304,
    USE_PROXY                          => 305,
    TEMPORARY_REDIRECT                 => 307,
    PERMANENT_REDIRECT                 => 308,
    BAD_REQUEST                        => 400,

    # ---4×× Client Error
    UNAUTHORIZED                       => 401,
    PAYMENT_REQUIRED                   => 402,
    FORBIDDEN                          => 403,
    NOT_FOUND                          => 404,
    METHOD_NOT_ALLOWED                 => 405,
    NOT_ACCEPTABLE                     => 406,
    PROXY_AUTHENTICATION_REQUIRED      => 407,
    REQUEST_TIMEOUT                    => 408,
    CONFLICT                           => 409,
    GONE                               => 410,
    LENGTH_REQUIRED                    => 411,
    PRECONDITION_FAILED                => 412,
    PAYLOAD_TOO_LARGE                  => 413,
    REQUEST_URI_TOO_LONG               => 414,
    UNSUPPORTED_MEDIA_TYPE             => 415,
    REQUESTED_RANGE_NOT_SATISFIABLE    => 416,
    EXPECTATION_FAILED                 => 417,
    I_M_A_TEAPOT                       => 418,
    MISDIRECTED_REQUEST                => 421,
    UNPROCESSABLE_ENTITY               => 422,
    LOCKED                             => 423,
    FAILED_DEPENDENCY                  => 424,
    UPGRADE_REQUIRED                   => 426,
    PRECONDITION_REQUIRED              => 428,
    TOO_MANY_REQUESTS                  => 429,
    REQUEST_HEADER_FIELDS_TOO_LARGE    => 431,
    CONNECTION_CLOSED_WITHOUT_RESPONSE => 444,
    UNAVAILABLE_FOR_LEGAL_REASONS      => 451,
    CLIENT_CLOSED_REQUEST              => 499,
    INTERNAL_SERVER_ERROR              => 500,

    # -- 5×× Server Error
    NOT_IMPLEMENTED                    => 501,
    BAD_GATEWAY                        => 502,
    SERVICE_UNAVAILABLE                => 503,
    GATEWAY_TIMEOUT                    => 504,
    HTTP_VERSION_NOT_SUPPORTED         => 505,
    VARIANT_ALSO_NEGOTIATES            => 506,
    INSUFFICIENT_STORAGE               => 507,
    LOOP_DETECTED                      => 508,
    NOT_EXTENDED                       => 510,
    NETWORK_AUTHENTICATION_REQUIRED    => 511,
    NETWORK_CONNECT_TIMEOUT_ERROR      => 599,
};

our @EXPORT_OK = ( Package::Constants->list(__PACKAGE__) );

our $VERSION = '0.0.2';

1;

=encoding utf8

=head1 NAME

Mojo::HTTPStatus - Readable HTTP status codes

=head1 SYNOPSIS

    use Mojo::HTTPStatus qw(CREATED I_M_A_TEAPOT);

    sub create {
        my $self = shift();

        my $body = ...;

        return $self->render(json => $body, status => CREATED);
    }

    sub another_action {
        my $self = shift();

        ...

        return $self->render(text => 'Ooops' status => I_M_A_TEAPOT);
    }

=head1 DESCRPTION

The module exports a list of readable constants for HTTP status code. For more descriptions of the codes please visit L<https://httpstatuses.com/>

=head2 CONSTANTS

=head3 1×× Informational

    CONTINUE                            100
    SWITCHING_PROTOCOLS                 101
    PROCESSING                          102

=head3 2×× Success

    OK                                  200
    CREATED                             201
    ACCEPTED                            202
    NON_AUTHORITATIVE_INFORMATION       203
    NO_CONTENT                          204
    RESET_CONTENT                       205
    PARTIAL_CONTENT                     206
    MULTI_STATUS                        207
    ALREADY_REPORTED                    208
    IM_USED                             226

=head3 3×× Redirection

    MULTIPLE_CHOICES                    300
    MOVED_PERMANENTLY                   301
    FOUND                               302
    SEE_OTHER                           303
    NOT_MODIFIED                        304
    USE_PROXY                           305
    TEMPORARY_REDIRECT                  307
    PERMANENT_REDIRECT                  308

=head3 4×× Client Error

    BAD_REQUEST                         400
    UNAUTHORIZED                        401
    PAYMENT_REQUIRED                    402
    FORBIDDEN                           403
    NOT_FOUND                           404
    METHOD_NOT_ALLOWED                  405
    NOT_ACCEPTABLE                      406
    PROXY_AUTHENTICATION_REQUIRED       407
    REQUEST_TIMEOUT                     408
    CONFLICT                            409
    GONE                                410
    LENGTH_REQUIRED                     411
    PRECONDITION_FAILED                 412
    PAYLOAD_TOO_LARGE                   413
    REQUEST_URI_TOO_LONG                414
    UNSUPPORTED_MEDIA_TYPE              415
    REQUESTED_RANGE_NOT_SATISFIABLE     416
    EXPECTATION_FAILED                  417
    I_M_A_TEAPOT                        418
    MISDIRECTED_REQUEST                 421
    UNPROCESSABLE_ENTITY                422
    LOCKED                              423
    FAILED_DEPENDENCY                   424
    UPGRADE_REQUIRED                    426
    PRECONDITION_REQUIRED               428
    TOO_MANY_REQUESTS                   429
    REQUEST_HEADER_FIELDS_TOO_LARGE     431
    CONNECTION_CLOSED_WITHOUT_RESPONSE  444
    UNAVAILABLE_FOR_LEGAL_REASONS       451
    CLIENT_CLOSED_REQUEST               499

=head3 5×× Server Error

    INTERNAL_SERVER_ERROR               500
    NOT_IMPLEMENTED                     501
    BAD_GATEWAY                         502
    SERVICE_UNAVAILABLE                 503
    GATEWAY_TIMEOUT                     504
    HTTP_VERSION_NOT_SUPPORTED          505
    VARIANT_ALSO_NEGOTIATES             506
    INSUFFICIENT_STORAGE                507
    LOOP_DETECTED                       508
    NOT_EXTENDED                        510
    NETWORK_AUTHENTICATION_REQUIRED     511
    NETWORK_CONNECT_TIMEOUT_ERROR       599

=head1 AUTHOR

Tudor Marghidanu L<tudor@marghidanu.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Tudor Marghidanu.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut

__END__