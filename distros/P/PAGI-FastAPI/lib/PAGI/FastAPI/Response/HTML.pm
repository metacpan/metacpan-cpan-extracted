package PAGI::FastAPI::Response::HTML;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;
use PAGI::FastAPI::Response;

class PAGI::FastAPI::Response::HTML :isa(PAGI::FastAPI::Response) {

    method prepare_headers ($c, $default_content_type = 'text/html; charset=utf-8') {
        $self->SUPER::prepare_headers($c, 'text/html; charset=utf-8');
    }

    async method send ($c, $pagi_writer) {
        $self->prepare_headers($c);
        await $pagi_writer->write($self->body);
    }
}

use overload '""' => sub { shift->body }, fallback => 1;

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Response::HTML - HTML Response Class for PAGI::FastAPI

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    use PAGI::FastAPI::Response::HTML;

    # Direct construction
    my $res = PAGI::FastAPI::Response::HTML->new(
        body   => '<h1>Hello World</h1>',
        status => 200,
    );

    # Or via Context helper method inside route handlers
    $app->get('/', handler => async sub ($c) {
        return $c->html('<h1>Welcome</h1>');
    });

=head1 DESCRIPTION

C<PAGI::FastAPI::Response::HTML> handles HTTP responses with a C<Content-Type> of C<text/html; charset=utf-8>.

=head1 CONSTRUCTOR

=head2 C<new(%options)>

=over 4

=item * C<body> (Optional)

The HTML string body. Defaults to an empty string.

=item * C<status> (Optional)

HTTP status code integer. Defaults to C<200>.

=item * C<headers> (Optional)

ArrayRef of additional header key-value pairs (e.g., C<< [ ['X-Frame-Options' => 'DENY'] ] >>).

=back

=head1 METHODS

=head2 C<send($c, $pagi_writer)>

Applies status code, sets the C<Content-Type> header to C<text/html; charset=utf-8>, and writes the HTML body string asynchronously to the response stream writer.

=head1 SEE ALSO

L<PAGI::FastAPI::Context>, L<PAGI::FastAPI>

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

    perldoc PAGI::FastAPI::Response::HTML

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

1; # End of PAGI::FastAPI::Response::HTML
