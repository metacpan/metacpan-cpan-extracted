package Punk::DevError;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.28';

# Development error pages. Loaded only when the application compiles in the
# development environment (Punk::App::compile_extras) - an opt-in: punk dev,
# or PUNK_ENV=development, or the config env. Production (the default) never
# requires this file and keeps the C dispatcher's fixed 500 byte-identical.
# The whole feature lives on the cold path: a middleware that records the
# stack at throw time (the C dispatcher catches dies under G_EVAL, so the
# frames must be captured where the die happens), and an on_error that
# renders them - HTML for a browser, the production JSON shape plus a
# trace for anything else.

# What the last die inside the middleware's scope looked like: message and
# frames. Compared against the error that reaches on_error before use, so
# an unrelated inner eval's die cannot decorate someone else's page.
our $CAUGHT;

my $MAX_FRAMES  = 40;
my $SNIP_BEFORE = 4;
my $SNIP_AFTER  = 4;

sub _install {
    my ($app) = @_;
    my $user = $app->{on_error};
    my $resolved = (defined $user && (ref $user || length $user))
        ? $app->_resolve_target($user, 'on_error') : undef;
    $app->on_error(sub {
        my ($c, $err) = @_;
        if ($resolved) {                # the user's handler keeps priority
            my $r = eval { $resolved->($c, $err) };
            return $r if ref $r;
        }
        return render($c, $err);
    });
    $app->middleware(\&_trace_mw);
    return;
}

# Wrap the PSGI app so a die anywhere under it records its frames.
sub _trace_mw {
    my ($inner) = @_;
    return sub {
        my ($env) = @_;
        local $CAUGHT = undef;
        local $SIG{__DIE__} = sub {
            my ($e) = @_;
            my (@frames, $i);
            for ($i = 0; my @f = caller $i; $i++) {
                last if @frames >= $MAX_FRAMES;
                next if $f[0] eq __PACKAGE__;
                my @up = caller $i + 1;
                push @frames, {
                    pkg  => $f[0], file => $f[1], line => $f[2],
                    sub  => @up ? $up[3] : '(main)',
                };
            }
            $CAUGHT = { msg => "$e", frames => \@frames };
            die @_;
        };
        return $inner->($env);
    };
}

# on_error's fallback in development: the debug response, flowing out
# through punk_handle_error's ordinary coercion.
sub render {
    my ($c, $err) = @_;
    my $msg    = "$err";
    my $frames = ($CAUGHT && $CAUGHT->{msg} eq $msg) ? $CAUGHT->{frames} : [];
    my $accept = eval { $c->req->header('accept') }       // '';
    my $ctype  = eval { $c->req->header('content-type') } // '';
    if ($accept =~ m{text/html}i && $ctype !~ /json/i) {
        return $c->html(_page($c, $msg, $frames), 500);
    }
    return $c->json({ errors => [ {
        message => $msg,
        trace   => [ map { "$_->{file}:$_->{line} in $_->{sub}" } @$frames ],
    } ] }, 500);
}

# ---- the page ----------------------------------------------------------------

sub _e {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
}

my $REDACT = qr/pass|secret|token/i;

# Plumbing a page reader almost never wants leading the stack: the
# framework's own dispatch, the PSGI middleware between it and the server,
# the server, and the test client. The application's frames come first with
# snippets; these collapse into a summary list.
sub _is_plumbing {
    my ($f) = @_;
    return 1 if ($f->{pkg} // '') =~ /\A(?:Punk|Plack|Hyperman|HTTP)(?:::|\z)/;
    return 1 if ($f->{sub} // '') =~ /\A(?:Punk|Plack|Hyperman|HTTP)::/;
    return 1 if ($f->{file} // '') =~ m{[/\\](?:Plack|Hyperman)[/\\]};
    return 0;
}

# The raw query string re-assembled with matching names' values redacted -
# it is shown verbatim in the page header otherwise, which would bypass
# the parameter table's redaction.
sub _redacted_query {
    my ($q) = @_;
    return '' unless defined $q && length $q;
    return join '&', map {
        my ($k, $v) = split /=/, $_, 2;
        defined $v && $k =~ $REDACT ? "$k=[redacted]" : $_;
    } split /&/, $q;
}

sub _rows {
    my ($h, $redact_all) = @_;
    my $out = '';
    for my $k (sort keys %$h) {
        my $v = $h->{$k};
        $v = defined $v ? "$v" : '';
        $v = '[redacted]' if $redact_all->($k);
        $v = substr($v, 0, 2048) . '...' if length $v > 2048;
        $out .= '<tr><th>' . _e($k) . '</th><td>' . _e($v) . "</td></tr>\n";
    }
    return $out;
}

sub _snippet {
    my ($file, $line) = @_;
    return '' if !defined $file || $file =~ /\(eval/ || !-r $file;
    open my $fh, '<', $file or return '';
    my @lines = <$fh>;
    close $fh;
    my $from = $line - $SNIP_BEFORE; $from = 1 if $from < 1;
    my $to   = $line + $SNIP_AFTER;  $to = @lines if $to > @lines;
    my $has_eshu = eval { require Eshu; Eshu->can('highlight_string') };
    my $out = qq{<pre class="snippet">};
    for my $n ($from .. $to) {
        my $src  = $lines[$n - 1] // '';
        chomp $src;
        my $code = $has_eshu
            ? (eval { Eshu->highlight_string($src, lang => 'perl') } // _e($src))
            : _e($src);
        $code =~ s/\n\z//;
        my $cls = $n == $line ? 'ln hit' : 'ln';
        $out .= sprintf qq{<span class="%s"><i>%4d</i> %s\n</span>},
                        $cls, $n, $code;
    }
    return $out . '</pre>';
}

sub _page {
    my ($c, $msg, $frames) = @_;
    my $env    = eval { $c->env } || {};
    my $method = $env->{REQUEST_METHOD} // '';
    my $path   = $env->{PATH_INFO}      // '';
    my $query  = $env->{QUERY_STRING}   // '';

    my $headers = eval { $c->req->headers } || {};
    my %hdr = map { $_ => $headers->{$_} } keys %$headers;
    my $hdr_rows = _rows(\%hdr, sub {
        my ($k) = @_;
        return $k =~ /\A(?:cookie|authorization)\z/i || $k =~ $REDACT;
    });

    my $params = eval { scalar $c->params } || {};
    my %prm; %prm = %$params if ref $params eq 'HASH';
    for (keys %prm) { delete $prm{$_} if ref $prm{$_} }
    my $prm_rows = _rows(\%prm, sub { $_[0] =~ $REDACT });

    my $match = eval { $c->match };
    my %rt;
    if (ref $match eq 'HASH') {
        for my $k (sort keys %$match) {
            my $v = $match->{$k};
            if (ref $v eq 'HASH') {
                $rt{"$k.$_"} = $v->{$_} for keys %$v;
            }
            elsif (!ref $v) { $rt{$k} = $v }
        }
    }
    my $rt_rows = _rows(\%rt, sub { 0 });

    my (@app, @plumbing);
    for my $f (@$frames) {
        if (_is_plumbing($f)) { push @plumbing, $f }
        else                  { push @app, $f }
    }
    # a die thrown from inside the framework with no app frame at all
    # still deserves snippets - show everything rather than nothing
    if (!@app && @plumbing) { @app = @plumbing; @plumbing = () }

    my $frame_html = '';
    for my $f (@app) {
        $frame_html .= '<div class="frame"><p>'
            . _e("$f->{file} line $f->{line}") . ' <b>in '
            . _e($f->{sub}) . '</b></p>'
            . _snippet($f->{file}, $f->{line})
            . "</div>\n";
    }
    if (@plumbing) {
        $frame_html .= '<details><summary>'
            . scalar(@plumbing)
            . ' framework frame(s)</summary><table>'
            . join('', map {
                  '<tr><th>' . _e("$_->{file}:$_->{line}") . '</th><td>'
                . _e($_->{sub}) . "</td></tr>\n"
              } @plumbing)
            . '</table></details>' . "\n";
    }
    $frame_html = '<p class="none">No frames were captured - the exception '
        . 'surfaced outside the request scope (a deferred future, most '
        . 'likely).</p>' unless $frame_html;

    my $title = _e((split /\n/, $msg)[0] // 'error');
    my $emsg  = _e($msg);
    my ($em, $ep) = (_e($method), _e($path));
    my $eq    = _e(_redacted_query($query));
    my $qline = length $eq ? "?$eq" : '';

    return <<"HTML";
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Punk error: $title</title>
<style>
  body { margin: 0; font: 15px/1.5 -apple-system, BlinkMacSystemFont,
         "Segoe UI", sans-serif; color: #24292f; background: #f6f8fa; }
  header { background: #b31d28; color: #fff; padding: 1.2rem 2rem; }
  header h1 { margin: 0 0 .4rem; font-size: 1.1rem; font-weight: 600; }
  header pre { margin: 0; font-size: 1rem; white-space: pre-wrap; }
  main { padding: 1.5rem 2rem; max-width: 70rem; }
  h2 { font-size: .95rem; text-transform: uppercase; letter-spacing: .05em;
       color: #57606a; margin: 2rem 0 .6rem; }
  table { border-collapse: collapse; width: 100%; background: #fff;
          border: 1px solid #d0d7de; font-size: .85rem; }
  th, td { text-align: left; padding: .35rem .6rem;
           border-bottom: 1px solid #d8dee4; vertical-align: top; }
  th { width: 16rem; font-weight: 600; color: #57606a; }
  .frame { margin-bottom: 1rem; }
  .frame p { margin: 0 0 .3rem; font-size: .85rem; }
  pre.snippet { margin: 0; background: #fff; border: 1px solid #d0d7de;
                padding: .5rem 0; overflow-x: auto; font-size: .8rem;
                line-height: 1.45; }
  pre.snippet span.ln { display: block; padding: 0 .75rem; }
  pre.snippet span.ln.hit { background: #fff1f1; }
  pre.snippet i { font-style: normal; color: #8c959f; user-select: none; }
  .esh-k { color: #cf222e; } .esh-b { color: #8250df; }
  .esh-s { color: #0a3069; } .esh-c { color: #6e7781; }
  .esh-n { color: #0550ae; } .esh-p { color: #953800; }
  .esh-v { color: #24292f; }
  .none { color: #57606a; font-style: italic; }
  details { margin: .6rem 0 1rem; }
  details summary { cursor: pointer; font-size: .85rem; color: #57606a; }
  details table { margin-top: .4rem; }
  footer { padding: 1rem 2rem 2rem; color: #8c959f; font-size: .8rem; }
</style>
</head>
<body>
<header>
  <h1>$em $ep$qline</h1>
  <pre>$emsg</pre>
</header>
<main>
  <h2>Stack</h2>
  $frame_html
  <h2>Route</h2>
  <table>$rt_rows</table>
  <h2>Parameters</h2>
  <table>$prm_rows</table>
  <h2>Request headers</h2>
  <table>$hdr_rows</table>
</main>
<footer>Punk $Punk::VERSION in development (opted in via punk dev or
PUNK_ENV=development) - the production default answers a plain JSON
500.</footer>
</body>
</html>
HTML
}

1;

__END__

=head1 NAME

Punk::DevError - the development error page

=head1 SYNOPSIS

    # nothing to call: in development a die becomes a debug page
    punk dev                                  # sets it for you
    PUNK_ENV=development plackup app.psgi     # or opt in by hand

    # the default is production: the plain JSON 500
    plackup app.psgi

=head1 DESCRIPTION

When the application compiles in the C<development> environment - an
opt-in: C<punk dev> sets it, or C<PUNK_ENV=development>, or the loaded
config's C<env>; the default is C<production> - a die inside a handler
renders a debug response
instead of the bare 500: the exception message, the stack at the point
of the throw with a source snippet per frame, the matched route, the
request parameters and the request headers.

Content negotiation is per request: a client whose C<Accept> includes
C<text/html> (and that did not send a JSON body) gets the HTML page;
everything else gets the production JSON shape plus a C<trace> array -

    { "errors": [ { "message": "...", "trace": ["file:12 in MyApp::x"] } ] }

so API clients in development stay parseable by the same code that
parses production errors.

In any other environment this module is never loaded and the response
is the C dispatcher's fixed C<500 {"errors":[{"message":...}]}>,
byte-identical to previous releases.

=head1 HOW IT HOOKS IN

C<Punk::App::compile_extras> installs two things at C<to_app>, both on
the cold path - the hot dispatch is untouched:

A middleware records the stack at throw time via a request-scoped
C<$SIG{__DIE__}> - the dispatcher catches dies deep in C under
C<G_EVAL>, so the frames must be captured where the die happens. The
recorded message is compared against the error that reaches the
handler, so an inner eval's unrelated die cannot decorate someone
else's page. A die that surfaces outside the request scope (a deferred
L<Punk::Future> callback on a later loop tick) renders gracefully with
the message alone.

An C<on_error> wrapper renders the page - but only when the
application's own C<on_error> handler (if any) declined: a user handler
returning a reference keeps absolute priority, in development exactly
as in production.

=head1 WHAT IS REDACTED

The C<Cookie> and C<Authorization> header values; any header or
parameter whose name matches C</pass|secret|token/i>; parameter values
are truncated at 2KB. The session contents, the session secret and the
application config are never rendered.

=head1 SYNTAX HIGHLIGHTING

If L<Eshu> is installed the source snippets are highlighted; without it
they render plain. Eshu is a C<recommends>, never required.

=head1 SEE ALSO

L<Punk>, L<Punk::App>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
