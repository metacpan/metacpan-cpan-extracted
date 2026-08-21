package PAGI::FastAPI::Response::Redirect;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use PAGI::FastAPI::Response;
use Exporter 'import';

our @EXPORT_OK = qw(redirect_to);

# Built on PAGI::FastAPI::Response's existing, documented public contract
# (status/body/headers + prepare_headers($c, $default_content_type)), the
# same way PAGI::FastAPI::Response::HTML and ::SSE are built, the dispatcher
# accepts any class that isa('PAGI::FastAPI::Response'), by design.

class PAGI::FastAPI::Response::Redirect :isa(PAGI::FastAPI::Response) {
    field $location :param;

    # 'field $location :param;' with no default already makes Perl's own
    # generated constructor require the argument to be PASSED, that
    # check fires before this ADJUST block runs, and produces its own
    # "Required parameter 'location' is missing" message, not this one.
    # This ADJUST only actually fires for the one case Perl's own check
    # doesn't cover: an explicitly-passed EMPTY STRING, which satisfies
    # "a value was passed" but isn't a usable location. Verified by
    # actually running both cases, see t/26-response_redirect.t.
    ADJUST {
        die "PAGI::FastAPI::Response::Redirect requires a 'location' argument"
            unless defined $location && length $location;
    }

    method prepare_headers ($c, $default_content_type = 'text/plain; charset=utf-8') {
        $self->SUPER::prepare_headers($c, $default_content_type);
        $c->set_header('location' => $location);
    }
}

# A plain sub with a signature must come AFTER a 'class ... :isa(...)' block
# in the same file, placing it before confuses the parser under
# "use experimental 'class'" in this Perl version (a 'class Name :isa(...)'
# declaration gets misread as if it were an out-of-order subroutine
# attribute). Order matters here, not just style.
#
# PAGI::FastAPI::Response's 'status' field is private with no setter, so a
# subclass cannot change its inherited default of 200, only the caller of
# ->new can, by passing status explicitly. This helper exists purely so
# callers don't have to remember "redirects need status => 302" every time.
sub redirect_to ($location, %opts) {
    return PAGI::FastAPI::Response::Redirect->new(
        location => $location,
        status   => $opts{status} // 302,
        %opts,
    );
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Response::Redirect - HTTP Redirect Response for PAGI::FastAPI

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    use PAGI::FastAPI::Response::Redirect qw(redirect_to);

    $app->get('/old-path',
        handler => async sub ($c) {
            return redirect_to('/new-path');  # defaults to 302
        }
    );

    $app->get('/permanent-move',
        handler => async sub ($c) {
            return redirect_to('/new-path', status => 301);
        }
    );

    # Or construct directly:
    use PAGI::FastAPI::Response::Redirect;

    $app->get('/old-path',
        handler => async sub ($c) {
            return PAGI::FastAPI::Response::Redirect->new(
                location => '/new-path',
                status   => 307,
            );
        }
    );

=head1 DESCRIPTION

A thin subclass of L<PAGI::FastAPI::Response> that sets the C<Location>
header and an appropriate redirect status code (defaulting to C<302 Found>
via the base class's C<status> default, pass C<status> explicitly for
C<301>, C<303>, C<307>, or C<308> as your use case requires).

=head1 METHODS

=head2 C<redirect_to($location, %opts)>

Exported on request. Convenience function equivalent to
C<< PAGI::FastAPI::Response::Redirect->new(location => $location, status => 302, %opts) >>,
so you don't have to remember to pass C<status> for the common case.
Pass C<status> in C<%opts> to override (e.g. C<301>, C<303>, C<307>, C<308>).

=head2 C<new(%options)>

=over 4

=item * C<location> - (Required) The target URL or path for the C<Location> header.

=item * C<status> - (Optional) HTTP status code. Inherited from
L<PAGI::FastAPI::Response>, whose own default is C<200>, for an actual
redirect, pass C<status> explicitly (or use C<redirect_to()> above, which
defaults it to C<302> for you).

=item * C<body> - (Optional) Response body. Defaults to C<''> (empty), which
is correct for most redirects.

=back

=head1 SEE ALSO

L<PAGI::FastAPI::Response>, L<PAGI::FastAPI::Response::HTML>, L<PAGI::FastAPI::Response::SSE>

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

    perldoc PAGI::FastAPI::Response::Redirect

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

1; # End of PAGI::FastAPI::Response::Redirect
