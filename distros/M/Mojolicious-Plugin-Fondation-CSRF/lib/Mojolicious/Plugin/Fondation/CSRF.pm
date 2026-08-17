package Mojolicious::Plugin::Fondation::CSRF;
$Mojolicious::Plugin::Fondation::CSRF::VERSION = '0.01';
# ABSTRACT: CSRF protection plugin for Fondation — route condition, OpenAPI integration, JS injection

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub fondation_meta {
    return {
        dependencies => ['Fondation::Problem'],
        defaults     => {
            auto_protect => 1,
            exemptions   => [],
        },
    };
}

sub register ($self, $app, $config) {

    # ═══════════════════════════════════════════════════════════════════════
    # 1. Route condition: fondation.csrf
    # ═══════════════════════════════════════════════════════════════════════

    $app->routes->add_condition('fondation.csrf' => sub {
        my ($route, $c, $captures) = @_;

        # GET, HEAD, OPTIONS are safe — no CSRF needed
        return 1 if $c->req->method =~ /^(GET|HEAD|OPTIONS)$/;

        # Bearer token auth bypasses CSRF — no session cookie, no CSRF risk
        my $auth = $c->req->headers->authorization;
        return 1 if $auth && $auth =~ /^Bearer\s+/i;

        # Delegate to Mojo's built-in csrf_protect (validates csrf_token
        # from form field or X-CSRF-Token header against session token)
        $c->validation->csrf_protect;

        unless ($c->validation->has_error('csrf_token')) {
            return 1;
        }

        $c->problem(status => 403, title => 'CSRF token missing or invalid');
        return undef;
    });

    # ═══════════════════════════════════════════════════════════════════════
    # 2. OpenAPI integration — subscribe to openapi_routes_added hook
    #    Runs when OpenAPI generates routes during its fondation_finalyze.
    #    register() always runs before any fondation_finalyze, so this
    #    subscription is guaranteed active when the hook fires.
    # ═══════════════════════════════════════════════════════════════════════

    $app->plugins->on(openapi_routes_added => sub {
        my ($openapi, $routes) = @_;
        for my $r (@$routes) {
            my $defaults = $r->pattern->defaults;
            my $method   = $defaults->{'openapi.method'} // '';
            next unless $method =~ /^(post|put|patch|delete)$/i;
            $r->requires('fondation.csrf');
        }
    });

    # ═══════════════════════════════════════════════════════════════════════
    # 3. around_dispatch — blanket protection for HTML routes
    # ═══════════════════════════════════════════════════════════════════════

    if ($config->{auto_protect}) {
        my $exemptions = $config->{exemptions} // [];

        $app->hook(around_dispatch => sub ($next, $c) {

            # Safe methods
            return $next->() if $c->req->method =~ /^(GET|HEAD|OPTIONS)$/;

            # Bearer token auth bypasses CSRF — no session cookie, no CSRF risk
            my $auth = $c->req->headers->authorization;
            return $next->() if $auth && $auth =~ /^Bearer\s+/i;

            # Configurable exemptions (regex patterns on path)
            my $path = $c->req->url->path->to_string;
            for my $pattern (@$exemptions) {
                return $next->() if $path =~ $pattern;
            }

            $c->validation->csrf_protect;

            unless ($c->validation->has_error('csrf_token')) {
                return $next->();
            }

            $c->problem(status => 403, title => 'CSRF token missing or invalid');
            return;
        });
    }

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::CSRF - CSRF protection plugin for Fondation — route condition, OpenAPI integration, JS injection

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # In myapp.conf
    plugin 'Fondation' => {
        dependencies => [
            'Fondation::SessionStore',     # sessions required for CSRF tokens
            'Fondation::CSRF',
        ],
    };

    # Per-route opt-in (when auto_protect is disabled):
    $r->post('/secure-action')->requires('fondation.csrf')->to('mycontroller#action');

    # With exemptions:
    'Fondation::CSRF' => {
        auto_protect => 1,
        exemptions   => [qr{^/webhook/}, qr{^/api/public/}],
    },

=head1 DESCRIPTION

C<Mojolicious::Plugin::Fondation::CSRF> provides Cross-Site Request Forgery
protection for Fondation applications. It uses Mojolicious' built-in CSRF
token mechanism (stored in session, validated via L<Validation/csrf_protect>).

Three protection layers, all using the same underlying Mojo validation:

=over 4

=item 1. Route condition C<fondation.csrf> — explicit opt-in on any route

=item 2. OpenAPI auto-protection — POST/PUT/PATCH/DELETE routes generated
by L<Fondation::OpenAPI> automatically get C<requires('fondation.csrf')>

=item 3. C<around_dispatch> blanket protection — all mutating requests
(POST/PUT/PATCH/DELETE) are checked unless the path matches an exemption

=back

Token transmission works two ways, both handled automatically by Mojo:

=over 4

=item Form field C<csrf_token> — standard HTML forms via L<TagHelpers/csrf_field>

=item Header C<X-CSRF-Token> — AJAX requests (the plugin provides a JS zone
that reads the CSRF meta tag and patches C<fetch> and C<XMLHttpRequest>)

=back

=head1 CONFIGURATION

=over 4

=item auto_protect

Enable/disable the C<around_dispatch> blanket protection.
Default: C<1> (enabled). Set to C<0> to use only explicit route conditions.

=item exemptions

Arrayref of regex patterns. Paths matching any pattern are skipped by
C<around_dispatch>. Useful for webhooks, public API endpoints, etc.
Default: C<[]> (no exemptions).

=back

=head1 DEPENDENCIES

L<Mojolicious::Plugin::Fondation>.

Sessions must be enabled (L<Fondation::SessionStore> or Mojolicious' default
signed cookies). The CSRF token lives in C<$c-E<gt>session-E<gt>{csrf_token}>.

=head1 STATIC JS FILE

The plugin ships C<share/public/js/csrf.js> — a standalone script that
reads the CSRF token from C<< <meta name="csrf-token"> >> and auto-injects
it as C<X-CSRF-Token> header on all C<fetch> and C<XMLHttpRequest>
POST/PUT/PATCH/DELETE calls.

Add it to your assetpack.def:

    < js/csrf.js

Or include it directly in your layout:

    <script src="/js/csrf.js"></script>

The meta tag must be present in the page. L<Fondation::Layout-Bootstrap>
provides it by default:

    <meta name="csrf-token" content="<%= csrf_token %>">

=head1 END-TO-END FLOW

When the CSRF plugin is loaded alongside the standard Fondation stack
(Layout-Bootstrap, Asset, OpenAPI, Auth), protection works automatically:

=over 4

=item 1. Layout-Bootstrap injects C<< <meta name="csrf-token"> >> in C<< <head> >>.

=item 2. C<csrf.js> (loaded via AssetPack bundle or C<< <script src> >>) patches
C<fetch> and C<XMLHttpRequest> to inject C<X-CSRF-Token> on all mutating AJAX calls.

=item 3. HTML forms (login, etc.) include C<< <%= csrf_field %> >> to embed
the token as a hidden field.

=item 4. OpenAPI routes (POST/PUT/PATCH/DELETE) automatically get
C<requires('fondation.csrf')> via the C<openapi_routes_added> hook.

=item 5. HTML POST routes are protected by C<around_dispatch> when
C<auto_protect> is enabled (default), or by explicit C<requires('fondation.csrf')>.

=item 6. Mojo's C<csrf_protect> validates the token from form field or
C<X-CSRF-Token> header against the session token.

=back

=head1 HOW TOKEN VALIDATION WORKS

The route condition and C<around_dispatch> both delegate to Mojo's
C<csrf_protect> validation:

=over 4

=item 1. Mojo generates a unique token on first session access

=item 2. Token is stored in C<$c-E<gt>session-E<gt>{csrf_token}>

=item 3. Client sends the token back (form field or C<X-CSRF-Token> header)

=item 4. C<csrf_protect> compares the submitted token with the session token

=item 5. Mismatch → validation error C<csrf_token> → 403

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation>,
L<Mojolicious::Plugin::Fondation::OpenAPI>,
L<Mojolicious::Guides::Routing>,
L<Mojolicious::Validator::Validation>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
