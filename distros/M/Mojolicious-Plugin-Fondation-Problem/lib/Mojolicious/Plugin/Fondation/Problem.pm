package Mojolicious::Plugin::Fondation::Problem;
$Mojolicious::Plugin::Fondation::Problem::VERSION = '0.01';
# ABSTRACT: Unified API (RFC 9457) and HTML error responses for Fondation

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => [],
        defaults     => {},
    };
}

sub register ($self, $app, $config) {

    $app->helper(problem => sub ($c, %args) {
        my $status   = $args{status}   // 500;
        my $title    = $args{title}    // 'Internal Server Error';
        my $detail   = $args{detail};
        my $type     = $args{type};
        my $errors   = $args{errors};
        my $instance = $args{instance};

        my $is_dev = $c->app->mode eq 'development';

        # ── Build RFC 9457 response body ──────────────────────
        my %body = (
            status => $status,
            title  => $title,
        );

        if ($is_dev) {
            $body{type}     = $type     if defined $type;
            $body{detail}   = $detail   if defined $detail;
            $body{errors}   = $errors   if defined $errors;
            $body{instance} = $instance if defined $instance;
        }

        # ── Detect API vs HTML ────────────────────────────────
        my $stack  = $c->match->stack;
        my $accept = $c->req->headers->accept // '';
        my $is_api = (
            (@$stack && $stack->[-1]{'openapi.path'})
            || ($c->req->url->path->to_string =~ m{^/api/})
            || ($accept =~ m{application/json}i
                && $accept !~ m{text/html}i)
        );

        if ($is_api) {
            $c->res->code($status);
            $c->res->headers->content_type('application/problem+json');
            $c->render(json => \%body);
        } else {
            $c->res->code($status);
            $c->stash(
                problem_status  => $status,
                problem_title   => $title,
                problem_detail  => $is_dev ? $detail : undef,
            );
            $c->render(template => 'problem');
        }
    });

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Problem - Unified API (RFC 9457) and HTML error responses for Fondation

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # In myapp.conf
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::Problem',
        ],
    };

    # In a controller
    $c->problem(
        status => 422,
        title  => 'Validation failed',
        detail => 'Field "name" is too long (60 > 50)',
        type   => '/problem/validation',
        errors => [
            { detail => 'String too long', pointer => '/name' },
        ],
    );

=head1 DESCRIPTION

C<Fondation::Problem> provides a unified error response mechanism
via the C<$c-E<gt>problem()> helper.

For API requests (routes with C<openapi.path> in the match stack),
it returns an RFC 9457 C<application/problem+json> response.

For browser (HTML) requests, it renders the C<problem> template
using the current layout.

In development mode, all fields are returned (C<type>, C<detail>,
C<errors>, C<instance>). In production mode, only C<status> and
C<title> are sent — no internal information is leaked.

=head1 NAME

Mojolicious::Plugin::Fondation::Problem - Unified API (RFC 9457) and HTML error responses for Fondation

=head1 VERSION

version 0.01

=head1 HELPERS

=head2 problem

    $c->problem(
        status   => 422,
        title    => 'Validation failed',
        detail   => 'Field "name" is too long',
        type     => '/problem/validation',
        errors   => [{ detail => '...', pointer => '/name' }],
        instance => '/logs/abc-123',
    );

All arguments are optional. Defaults: C<status> = 500, C<title> = 'Internal Server Error'.

In production mode, only C<status> and C<title> are included in the response.
C<detail>, C<type>, C<errors>, and C<instance> are suppressed.

=head1 TEMPLATES

=head2 problem.html.ep

Rendered for HTML error responses. Receives stash values:

=over 4

=item C<problem_status> — HTTP status code

=item C<problem_title> — Human-readable error title

=item C<problem_detail> — Detailed message (only in development mode)

=back

Uses C<% layout 'main'> — if C<Fondation::Layout::Bootstrap> is loaded,
its Bootstrap layout applies. Without any layout plugin, Mojo renders
the template content directly (no HTML wrapper) — the page remains
functional. A future Fondation core release may provide a minimal
HTML5 layout as a dedicated plugin loaded after Bootstrap.

=head1 RFC 9457 RESPONSE FORMAT

    Content-Type: application/problem+json

    {
      "status": 422,
      "title": "Validation failed",
      "detail": "Field \"name\" is too long (60 > 50)",
      "type": "/problem/validation",
      "errors": [
        { "detail": "String too long", "pointer": "/name" }
      ]
    }

=head1 MODE-AWARE BEHAVIOR

The plugin distinguishes between development and production modes:

    Development  → all fields (type, detail, errors, instance)
    Production   → only status + title

This follows the RFC 9457 principle that C<title> is constant per
problem type (always safe to show) while C<detail> and C<errors>
may reveal internal structure.

=head1 API DETECTION

API requests are detected using three criteria (any one match is sufficient):

=over 4

=item 1. C<openapi.path> in the match stack — set by L<Mojolicious::Plugin::Fondation::OpenAPI>

=item 2. URL path starts with C</api/> — custom API routes outside OpenAPI

=item 3. C<Accept> header contains C<application/json> but not C<text/html>

=back

Requests matching any of these criteria receive an RFC 9457
C<application/problem+json> response. All other requests receive
an HTML error page.

=head1 DEPENDENCIES

L<Mojolicious::Plugin::Fondation>

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation>,
L<RFC 9457|https://www.rfc-editor.org/rfc/rfc9457.html>,
L<Mojolicious::Plugin::Fondation::OpenAPI>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
