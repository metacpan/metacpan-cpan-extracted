package Open::API::UI;

use 5.010;
use strict;
use warnings;
use Carp ();
use Scalar::Util ();
use File::Raw::JSON ();
use Open::API;
use Template::Stencil;
use Markdown::Simple;

our $VERSION = '0.11';

my @HEADERS = (
    'Content-Security-Policy' =>
        "default-src 'none'; script-src 'self'; style-src 'self'; "
      . "connect-src 'self'; img-src 'self' data:; frame-ancestors 'none'; "
      . "base-uri 'none'; form-action 'self'",
    'X-Content-Type-Options' => 'nosniff',
    'X-Frame-Options'        => 'DENY',
    'Referrer-Policy'        => 'no-referrer',
    'Cache-Control'          => 'no-cache',
);

my %ASSETS = (
    'app.css' => 'text/css; charset=utf-8',
    'app.js'  => 'application/javascript; charset=utf-8',
);

sub _base_dir {
    my $pm = $INC{'Open/API/UI.pm'}
        or Carp::croak("Open::API::UI: cannot locate my own installation");
    (my $dir = $pm) =~ s/\.pm\z//;
    return $dir;
}

sub new {
    my $class = shift;
    my %opts = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    my $api = delete $opts{api};
    Carp::croak("Open::API::UI->new: 'api' must be an Open::API")
        unless Scalar::Util::blessed($api) && $api->isa('Open::API');

    my $self = bless { api => $api }, $class;

    for my $k (qw(path spec_path title try_it csrf headers)) {
        $self->{$k} = delete $opts{$k} if exists $opts{$k};
    }
    Carp::croak("Open::API::UI->new: unknown option(s) "
        . join(', ', map "'$_'", sort keys %opts)) if %opts;

    $self->{path}      = '/docs'         unless defined $self->{path};
    $self->{spec_path} = '/openapi.json' unless defined $self->{spec_path};
    $self->{try_it}    = 1               unless defined $self->{try_it};
    $self->{csrf}      = { header => 'X-CSRF-Token', cookie => 'csrf' }
        unless exists $self->{csrf};

    for my $k (qw(path spec_path)) {
        Carp::croak("Open::API::UI->new: '$k' must start with '/'")
            unless $self->{$k} =~ m{\A/};
        $self->{$k} =~ s{/\z}{} if length $self->{$k} > 1;
    }
    Carp::croak("Open::API::UI->new: 'path' and 'spec_path' must differ")
        if $self->{path} eq $self->{spec_path};
    if (my $c = $self->{csrf}) {
        Carp::croak("Open::API::UI->new: 'csrf' must be a hashref or false")
            unless ref $c eq 'HASH';
        $c->{header} = 'X-CSRF-Token' unless defined $c->{header};
        $c->{cookie} = 'csrf'         unless defined $c->{cookie};
    }
    if (defined $self->{headers} && ref $self->{headers} ne 'HASH') {
        Carp::croak("Open::API::UI->new: 'headers' must be a hashref");
    }

    $self->{header_pairs} = _merge_headers($self->{headers});

    # Render eagerly: a template problem is a configuration error and
    # belongs at startup, like everything else in this stack.
    $self->{html} = $self->_render;
    return $self;
}

sub _merge_headers {
    my ($over) = @_;
    my @out;
    my %ov;
    if ($over) {
        $ov{lc $_} = [ $_, $over->{$_} ] for keys %$over;
    }
    for (my $i = 0; $i < @HEADERS; $i += 2) {
        my ($k, $v) = @HEADERS[$i, $i + 1];
        if (my $o = delete $ov{lc $k}) {
            push @out, $k, $o->[1] if defined $o->[1];
        } else {
            push @out, $k, $v;
        }
    }
    for my $k (sort keys %ov) {
        push @out, $ov{$k}[0], $ov{$k}[1] if defined $ov{$k}[1];
    }
    return \@out;
}

sub _build_data {
    my ($self) = @_;
    my $spec = $self->{api}->spec;
    my $info = $spec->{info} || {};

    # OpenAPI descriptions are CommonMark; render the ones the shell owns
    # (info, tags, operations) once, at boot. Markdown::Simple's GFM
    # defaults strip raw HTML and dangerous URLs, so the output is safe to
    # inject with {% raw %}.
    my $md = Markdown::Simple->new;
    my $mdh = sub {
        my ($text) = @_;
        return '' unless defined $text && length $text;
        return $md->render($text);
    };

    my %tag_desc = map { ($_->{name} // '') => ($_->{description} // '') }
        grep { ref $_ eq 'HASH' } @{ $spec->{tags} || [] };

    my (@tags, %tag_by_name);
    for my $o (@{ $self->{api}->operations }) {
        my $raw = $spec->{paths}{ $o->{path} }{ lc $o->{method} } || {};
        my $tname = (ref $raw->{tags} eq 'ARRAY' && @{ $raw->{tags} })
            ? $raw->{tags}[0] : 'default';
        my $tag = $tag_by_name{$tname} ||= do {
            (my $slug = lc $tname) =~ s/[^a-z0-9]+/-/g;
            $slug =~ s/\A-+|-+\z//g;
            my $t = { name => $tname, slug => ($slug || 'default'),
                      description_html => $mdh->($tag_desc{$tname}),
                      ops => [] };
            push @tags, $t;
            $t;
        };
        push @{ $tag->{ops} }, {
            id               => $o->{operationId},
            method           => uc $o->{method},
            method_lc        => lc $o->{method},
            path             => $o->{path},
            summary          => $raw->{summary} // '',
            deprecated       => $raw->{deprecated} ? 1 : 0,
            description_html => $mdh->($raw->{description}),
        };
    }

    my @servers = map {
        { url => $_->{url} // '', description => $_->{description} // '' }
    } grep { ref $_ eq 'HASH' } @{ $spec->{servers} || [] };

    my @schemes;
    my $ss = ($spec->{components} || {})->{securitySchemes} || {};
    for my $name (sort keys %$ss) {
        my $s = $ss->{$name};
        next unless ref $s eq 'HASH';
        my $type = $s->{type} // '';
        my $label =
            $type eq 'apiKey' ? "apiKey in $s->{in} ($s->{name})"
          : $type eq 'http'   ? "http " . ($s->{scheme} // '')
          : $type eq 'oauth2' ? 'oauth2 (paste a bearer token)'
          : $type eq 'openIdConnect' ? 'openIdConnect (paste a bearer token)'
          : $type;
        push @schemes, {
            name   => $name,
            type   => $type,
            scheme => $s->{scheme} // '',
            in     => $s->{in} // '',
            key    => $s->{name} // '',
            label  => $label,
        };
    }

    my $config_json = File::Raw::JSON::file_json_encode({
        basePath => $self->{path},
        specPath => $self->{spec_path},
        tryIt    => $self->{try_it} ? 1 : 0,
        csrf     => $self->{csrf} ? { %{ $self->{csrf} } } : 0,
    });
    # The config rides inside a <script type="application/json"> block;
    # a '<' in any value must never be able to close it.
    $config_json =~ s/</\\u003c/g;

    return {
        title       => $self->{title} // $info->{title} // 'API',
        base        => $self->{path},
        config_json => $config_json,
        info        => {
            title            => $info->{title} // 'API',
            version          => $info->{version} // '',
            description_html => $mdh->($info->{description}),
        },
        servers => \@servers,
        schemes => \@schemes,
        tags    => \@tags,
    };
}

sub _render {
    my ($self) = @_;
    my $stencil = Template::Stencil->new(
        template_dir => _base_dir() . '/templates',
        wrapper      => 'wrapper.tmpl',
    );
    return $stencil->render('index', $self->_build_data);
}

sub index_html { $_[0]{html} }

# The same page as a fragment, for a host page that already has a
# <head> of its own - a product page showing the docs for a spec
# somebody just pasted, rather than a documentation site.
#
# It carries the config block, because app.js reads its settings from
# there and a fragment without it is inert. It does not carry the
# stylesheet or script tags: the host is serving those assets from
# wherever it serves assets, and only the host knows where that is.
sub embed_html {
    my ($self) = @_;
    return $self->{embed} if defined $self->{embed};
    my $data = $self->_build_data;
    my $stencil = Template::Stencil->new(
        template_dir => _base_dir() . '/templates',
    );
    return $self->{embed} =
          qq{<script type="application/json" id="oa-config">}
        . $data->{config_json}
        . qq{</script>\n}
        . $stencil->render('index', $data);
}

sub spec_json {
    my ($self) = @_;
    $self->{spec_json} //=
        File::Raw::JSON::file_json_encode($self->{api}->spec);
}

sub asset {
    my ($self, $name) = @_;
    return unless defined $name && $ASSETS{$name};
    unless (defined $self->{assets}{$name}) {
        my $file = _base_dir() . "/static/$name";
        open my $fh, '<:raw', $file
            or Carp::croak("Open::API::UI: cannot read $file: $!");
        local $/;
        $self->{assets}{$name} = <$fh>;
    }
    return ($ASSETS{$name}, $self->{assets}{$name});
}

sub headers { [ @{ $_[0]{header_pairs} } ] }

sub routes {
    my ($self) = @_;
    return $self->{routes} if $self->{routes};
    my $hdrs = $self->{header_pairs};
    my $static = sub {
        my ($ct, $bytes) = @_;
        return sub {
            [ 200,
              [ 'Content-Type'   => $ct,
                'Content-Length' => length $bytes,
                @$hdrs ],
              [ $bytes ] ];
        };
    };
    my $html = $static->('text/html; charset=utf-8', $self->index_html);
    my ($css_ct, $css) = $self->asset('app.css');
    my ($js_ct,  $js)  = $self->asset('app.js');
    my $p = $self->{path};
    return $self->{routes} = [
        { method => 'GET', path => $p,           response => $html },
        { method => 'GET', path => "$p/",        response => $html },
        { method => 'GET', path => "$p/app.js",  response => $static->($js_ct, $js) },
        { method => 'GET', path => "$p/app.css", response => $static->($css_ct, $css) },
        { method => 'GET', path => $self->{spec_path},
          response => $static->('application/json', $self->spec_json) },
    ];
}

sub _table {
    my ($self) = @_;
    return { map { $_->{path} => $_->{response} } @{ $self->routes } };
}

sub to_app {
    my ($self) = @_;
    my $table = $self->_table;
    return sub {
        my $env = shift;
        my $m = $env->{REQUEST_METHOD} || 'GET';
        if (($m eq 'GET' || $m eq 'HEAD')
            and my $r = $table->{ $env->{PATH_INFO} || '/' }) {
            my $resp = $r->();
            $resp->[2] = [''] if $m eq 'HEAD';
            return $resp;
        }
        return [ 404, [ 'Content-Type' => 'text/plain' ], ['Not Found'] ];
    };
}

sub _wrap_psgi {
    my ($plack, $app) = @_;
    my $ui_opt = $plack->ui;
    my %opts = ref $ui_opt eq 'HASH' ? %$ui_opt : ();

    my $api = $plack->api
        or Carp::croak("Open::API::UI: the Plack object has no api");

    # The JS must speak the server's actual CSRF dialect, so the names come
    # from the Plack csrf option, never from ui options.
    my $csrf = $plack->csrf;
    if (ref $csrf eq 'HASH') {
        $opts{csrf} = {
            header => defined $csrf->{header} ? $csrf->{header} : 'X-CSRF-Token',
            cookie => defined $csrf->{cookie} ? $csrf->{cookie} : 'csrf',
        };
    } else {
        $opts{csrf} = 0;
    }

    my $ui = Open::API::UI->new(api => $api, %opts);

    for my $r (@{ $ui->routes }) {
        my @m = $api->match($r->{method}, $r->{path});
        next unless @m;
        Carp::croak(defined $m[0]
            ? "Open::API::UI: path '$r->{path}' is declared by spec "
              . "operation '$m[0]'; choose another ui path"
            : "Open::API::UI: path '$r->{path}' is declared by the spec; "
              . "choose another ui path");
    }

    my $table = $ui->_table;
    return sub {
        my $env = shift;
        my $m = $env->{REQUEST_METHOD} || 'GET';
        if (($m eq 'GET' || $m eq 'HEAD')
            and my $r = $table->{ $env->{PATH_INFO} || '/' }) {
            my $resp = $r->();
            $resp->[2] = [''] if $m eq 'HEAD';
            return $resp;
        }
        return $app->($env);
    };
}

1;

__END__

=encoding utf8

=head1 NAME

Open::API::UI - a Swagger UI clone for a compiled spec

=head1 SYNOPSIS

    # the usual way: one option on the Plack app
    my $app = Open::API::Plack->new(
        spec     => 'openapi.json',
        handlers => { ... },
        ui       => 1,                    # serve /docs and /openapi.json
    )->to_app;

    # or standalone, for other frameworks and mounting by hand
    use Open::API::UI;

    my $ui = Open::API::UI->new(api => $api);
    my $html   = $ui->index_html;         # the whole docs page
    my $spec   = $ui->spec_json;          # the document, JSON-encoded
    my $routes = $ui->routes;             # the adapter contract
    my $app    = $ui->to_app;             # standalone PSGI app

=head1 DESCRIPTION

An interactive documentation UI for an L<Open::API> spec, in the spirit of
Swagger UI but written from scratch: one HTML page, one stylesheet, one
script, all shipped inside this distribution. No CDN, no bundled
third-party code, works offline.

=head1 CONSTRUCTOR

=head2 new

    my $ui = Open::API::UI->new(
        api       => $api,              # required, an Open::API
        path      => '/docs',           # UI mount prefix
        spec_path => '/openapi.json',   # where the spec JSON is served
        title     => undef,             # page title; defaults to info.title
        try_it    => 1,                 # render try-it-out forms
        csrf      => { header => 'X-CSRF-Token', cookie => 'csrf' },
        headers   => { ... },           # adjust the UI response headers
    );

C<api> is the compiled L<Open::API> whose document the page describes.
Unknown options croak. The page is rendered here, so a template problem is
a startup error, never a per-request one.

C<csrf> names the header the try-it-out script sends its token in and the
cookie it reads a rotated token from; give a false value to disable CSRF
handling in the browser entirely. When the UI is mounted through
L<Open::API::Plack>'s C<ui> option these names are taken from the app's
own C<csrf> configuration automatically and this option is ignored.

C<headers> adjusts the response header set stamped on every UI response,
with the same semantics as L<Open::API::Plack/RESPONSE HEADERS>: a listed
name overrides the default (matched case-insensitively), an unlisted name
is added, and mapping a name to C<undef> removes it. The defaults are

    Content-Security-Policy: default-src 'none'; script-src 'self';
        style-src 'self'; connect-src 'self'; img-src 'self' data:;
        frame-ancestors 'none'; base-uri 'none'; form-action 'self'
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    Referrer-Policy: no-referrer
    Cache-Control: no-cache

The page carries no inline script or style, so C<'self'> covers all of
it. C<connect-src 'self'> means try-it-out reaches the same origin only;
to exercise a cross-origin entry from the spec's C<servers> list, widen
C<connect-src> here (and configure CORS on the target).

=head1 METHODS

Everything the page needs is precomputed and cached on the object; these
accessors hand out bytes.

=head2 index_html

    my $bytes = $ui->index_html;

The complete documentation page as UTF-8 bytes.

=head2 embed_html

    my $html = $ui->embed_html;

The same page as a fragment, for a host page that already has a C<head>
of its own - a product page showing the documentation for a spec
somebody has just pasted, rather than a documentation site.

It carries the C<oa-config> block, because F<app.js> reads its settings
from there and a fragment without it is inert. It does not carry the
stylesheet or script tags: the host is serving those assets from
wherever it serves assets, and only the host knows where that is.

    <link rel="stylesheet" href="/static/openapi-ui.css">
    <script src="/static/openapi-ui.js" defer></script>
    ...
    <div class="oa-embed">[% ui_html %]</div>

The host's own Content-Security-Policy applies, so it needs to allow the
script and stylesheet it is serving, and C<connect-src> wide enough to
reach whatever the spec's C<servers> point at. Setting C<servers> to a
path on the host itself keeps try-it same-origin and needs neither.

=head2 spec_json

    my $bytes = $ui->spec_json;

The spec document (exactly what L<Open::API/spec> returns) encoded as
JSON, cached after the first call. This is what is served at C<spec_path>
and what F<app.js> renders from.

=head2 asset

    my ($content_type, $bytes) = $ui->asset('app.js');   # or 'app.css'

One static asset with its content type. Any other name returns the empty
list.

=head2 headers

    my $pairs = $ui->headers;   # [ name => value, ... ]

A fresh arrayref of the header pairs stamped on every UI response, after
the C<headers> option has been applied.

=head2 routes

    for my $r (@{ $ui->routes }) {
        # { method => 'GET', path => '/docs', response => sub { ... } }
    }

The framework contract. Every UI route is a static C<GET>; C<path> is
absolute and already prefixed; C<response> returns a finished PSGI-shaped
triplet - C<[ $status, \@headers, [ $bytes ] ]> - fresh on every call, so
an adapter may mutate it freely. The set is the index page (with and
without a trailing slash), the two assets, and the spec JSON. A Catalyst
adapter unpacks the triplet into C<< $c->res >>; a Mojolicious adapter
into C<< $c->render >>; a PSGI framework can use it as-is.

=head2 to_app

    my $app = $ui->to_app;

A standalone PSGI app serving exactly L</routes> (C<GET> and C<HEAD>;
anything else is a 404). Useful under C<Plack::Builder>'s C<mount> or for
serving the docs separately from the API.

=head1 THE PAGE

The shell lists every operation grouped by its first tag, collapsed, with
method, path and summary. Expanding an operation renders its parameter
tables, request body schema, response schemas and - when C<try_it> is on -
a form that executes real requests with C<fetch()> and shows the status,
headers, body and elapsed time. Schemas resolve C<$ref> into
C<components.schemas> (cycles guarded), and a schema browser for the
components sits at the bottom of the page. Deep links work:
C<#op-E<lt>operationIdE<gt>> expands and scrolls to an operation.

Descriptions are CommonMark, as the OpenAPI spec says: the info, tag and
operation descriptions are rendered to HTML at boot with
L<Markdown::Simple> (GFM defaults - raw HTML and dangerous URLs are
stripped, so a hostile spec cannot script the page). Parameter and schema
descriptions, built in the browser, stay plain text.

A request body declared as C<multipart/form-data> gets one field per
schema property - a file picker where the schema says
C<format: binary> (C<multiple> for arrays of them), a text input
otherwise - and is sent as real C<FormData>, the browser writing the
boundary. An C<application/octet-stream> (or any body whose schema is
C<format: binary>) gets a single file picker and ships the file raw.

The Authorize box takes a bearer token, an API key, or basic credentials
per scheme declared in the spec. Values live in page memory; an explicit
checkbox opts into C<sessionStorage>. OAuth2 token flows are out of
scope - paste an already-issued token.

For CSRF-protected specs the script sends the configured header on every
unsafe request, preferring a manually pasted token and falling back to
the configured cookie, so the rotate-on-use flow of
L<Open::API::Plack/CSRF> just works. If the app restricts C<csrf>
C<origins>, list the docs origin there or try-it-out requests will be
rejected.

Not currently supported: XML rendering, OAuth2 token
flows (paste an already-issued token).

=head1 SEE ALSO

L<Open::API>, L<Open::API::Plack>, L<Template::Stencil>,
L<Markdown::Simple>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
