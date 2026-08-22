package PAGI::FastAPI::Response;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.5');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;

class PAGI::FastAPI::Response {
    field $body    :param = '';
    field $status  :param = 200;
    field $headers :param = [];

    method body    () { return $body }
    method status  () { return $status }
    method headers () { return $headers }

    method prepare_headers ($c, $default_content_type = 'text/html; charset=utf-8') {
        $c->status($status);

        # Set default content type
        $c->set_header('content-type' => $default_content_type);

        for my $header (@$headers) {
            $c->set_header(lc($header->[0]) => $header->[1]);
        }
    }

    method TO_JSON () {
        return $body;
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Response - Base HTTP Response Class for PAGI::FastAPI

=head1 VERSION

Version v1.2.5

=head1 SYNOPSIS

    use PAGI::FastAPI::Response;

    my $res = PAGI::FastAPI::Response->new(
        body   => 'Plain text content',
        status => 200,
    );

=head1 DESCRIPTION

C<PAGI::FastAPI::Response> serves as the base class for specialised HTTP
responses in L<PAGI::FastAPI> (such as L<PAGI::FastAPI::Response::HTML> and
L<PAGI::FastAPI::Response::SSE>).

=head1 SEE ALSO

L<PAGI::FastAPI::Response::HTML>, L<PAGI::FastAPI::Response::SSE>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Response

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::Response
