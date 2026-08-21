package Punk::Plugin::CSP;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';

# register() and the policy are C - xs/csp.xs and include/punk/punk_csp.h.

1;

__END__

=head1 NAME

Punk::Plugin::CSP - Content-Security-Policy with a per request nonce

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'CSP';

    get '/' => sub { $_[0]->render('page') };

and in C<page.tmpl>:

    <script nonce="{% csp_nonce %}">start()</script>

Both halves are needed. The header carries the nonce, the template carries the
same one, and a script is allowed to run only because they agree.

    plugin 'CSP' => { script_src => q{'self' https://cdn.example},
                      report_uri => '/csp-report' };

=head1 DESCRIPTION

C<headers> can already set a static C<Content-Security-Policy>, and that is
worth having. The policy that actually stops cross-site scripting is
C<script-src 'nonce-...'>, and a nonce is per request by definition: minted
fresh, put in the header, and threaded into every C<< <script> >> tag the
templates emit.

That thread is what cannot be a config line, and it is what this plugin is.

=head2 The nonce reaches the template on its own

    <script nonce="{% csp_nonce %}">...</script>

Nothing is passed by the handler. The nonce is bound into the variables Punk
hands the view engine, so it is there whether or not the route thought about
it - and it is bound at Punk's render call rather than inside Stencil, so any
engine that receives a variables hash sees it under its own syntax.

C<< $c->csp_nonce >> is the same value, for a handler building HTML or a JSON
payload by hand.

=head2 Caching a nonced page breaks it

A page stored with C<nonce-abc> in its script tags and served later against a
header carrying C<nonce-def> has B<every script on it blocked>.

So a response that rendered a nonce must not be cached - not by
L<Punk::Cache>, not by a reverse proxy, not by the browser. If you are caching
rendered pages, cache the ones without inline script, or move the script to a
file the policy allows by source.

This is not enforced. Detecting it means scanning response bodies, which is a
cost every response would pay for a fault a few applications can have, and
there is a development-mode body scan coming for inline handlers that can
carry the same check for free.

=head2 What the defaults are, and why

    default-src 'self'; script-src 'self' 'nonce-...';
    object-src 'none'; base-uri 'none'

C<base-uri 'none'> is the one people leave out. Without it an injected
C<< <base href> >> rewrites every relative script URL, and a nonce on a
relative C<< <script src> >> protects nothing at all. C<object-src 'none'>
closes the plugin-embedding bypasses a script-only policy leaves open.

Both are overridable, because a policy nobody can adjust is one that gets
removed rather than tuned.

=head2 Every response, including the ones with no route

The policy rides the same path the C<headers> keyword uses, which decorates
from outside the routing branch - so a 404, a 405, a 500 and a CORS preflight
carry it too. An error page is the response most likely to render something
from the request, which makes it the one a policy most needs to cover.

A response that set its own C<Content-Security-Policy> keeps it.

=head1 OPTIONS

Each directive is its own option, named with underscores: C<default_src>,
C<script_src>, C<style_src>, C<img_src>, C<connect_src>, C<font_src>,
C<frame_ancestors>, C<form_action>, C<report_uri>.

    plugin 'CSP' => { script_src => q{'self' 'strict-dynamic'} };

C<script_src> is where your own sources go; the nonce is spliced into that
same directive rather than added as a second one, which a browser would
ignore.

C<< report_only => 1 >> sends C<Content-Security-Policy-Report-Only> instead,
which enforces nothing and reports everything. Start there: a strict policy
always breaks something on first contact.

A directive value containing a newline, a NUL or a semicolon croaks at boot. It
is on its way into a response header, where a newline would split the response
and a semicolon would forge a directive nobody wrote.

=head2 Report-only, and both at once

    plugin 'CSP' => { report_only => 1 };

sends C<Content-Security-Policy-Report-Only> instead of the enforcing header:
the policy is evaluated and violations are reported, but nothing is blocked.

A hashref there means something more useful - a B<second> policy, reported
alongside the first rather than instead of it:

    plugin 'CSP' => {
        script_src  => q{'self' 'unsafe-inline'},   # what is trusted today
        report_only => { script_src => q{'self'} }, # what to move to
    };

The loose policy you already trust keeps enforcing while the strict one you
are moving to reports what it would have broken. Both carry the same nonce,
because they describe one response.

That combination is how a strict policy actually gets deployed. Treating the
two as exclusive would mean choosing between protection now and knowing what
breaks later, and nobody chooses the second.

=head2 The report endpoint

    plugin 'CSP' => { report_uri => '/csp-report' };

When C<report_uri> is a local path the plugin B<mounts the endpoint itself>,
with its own limits: a 16 KB body ceiling and a rate limit of 60 a minute per
address.

That is the reason it belongs here rather than in your application. It is a
public, unauthenticated C<POST> that takes a body from anybody, and without
limits it is a free log-flooding endpoint. Leaving them to the application
means the one application that forgets has an open one.

Reports are logged at C<warn> with their fields, and counted -
C<< Punk::Plugin::CSP->stats >> returns C<reports> and C<malformed>. A rising
C<malformed> is somebody probing rather than a browser reporting.

An absolute URL is somebody else's collector: it is named in the policy and no
route is mounted for it.

A body that makes no sense is still a C<204>. Nothing reads the response, and
an error status invites a retry from a browser that cannot fix what it sent.

=head2 The inline-handler check, in development

A script nonce does B<not> cover inline event handlers. One C<onclick="...">
in one template silently requires C<'unsafe-inline'> in C<script-src>, and
adding that back defeats the policy for every page - including every page that
had no inline handler at all.

Nobody decides on that. They deploy a strict policy, get a console full of
violations, add C<'unsafe-inline'> to stop them, and arrive one fix at a time
at a policy that is a header and nothing more.

So in development the rendered body is scanned, and a template carrying an
C<on*=> attribute warns once, naming the template and the attribute:

    Punk::Plugin::CSP: checkout has an inline `onclick=` handler, which a
    script nonce does NOT cover ...

Three things keep it useful rather than annoying:

=over 4

=item * B<Development only.> Scanning every response in production is a cost
on the hot path to tell somebody something they cannot act on at the time.

=item * B<It warns, and never blocks.> It has no authority over the response;
a checker that breaks a page is a checker that gets removed.

=item * B<Once per template, not once per response.> The same page warning on
every request is noise, and noise gets ignored - which is how the original
problem happens.

=back

A template that knowingly needs an inline handler exempts itself by containing
the string C<csp-allow-inline>. That keeps the exemption next to the thing
being exempted, rather than in a config file that outlives the reason.
C<< inline_check => 0 >> turns the whole thing off.

The same pass catches a B<stale nonce> - markup rendering a nonce that is not
the current request's, which is what a cached page looks like.

=head2 On C<'strict-dynamic'>

It is the mode that makes a strict policy survivable, because a nonced script
can load its own dependencies without every URL being listed. Be aware that
supporting browsers B<ignore host allowlists> when it is present, so a policy
carrying both behaves differently on different browsers.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
