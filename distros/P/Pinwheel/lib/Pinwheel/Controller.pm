package Pinwheel::Controller;

use strict;
use warnings;

use Carp;
use Exporter;

require File::Find;
use File::Slurp;
use Scalar::Util qw(blessed);

use Pinwheel::Context;
use Pinwheel::Database;
use Pinwheel::Helpers;
use Pinwheel::Mapper;
use Pinwheel::Model::Time;
use Pinwheel::View::Data;
use Pinwheel::View::ERB;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    url_for
    redirect_to
    render
    render_to_string
    render_404
    render_500
    set_header
    expires_in
    expires_at
    expires_now
    accepts
    respond_to
    params
    query_params
);
our @EXPORT_OK = qw(
    connect
    dispatch
    format
    set_base_format
    set_format_param
    expand_static_path
    set_static_root
    set_templates_root
    request_time
    request_time_model
);


our $map = new Pinwheel::Mapper;
our $static_root = '.';
our $templates_root = '.';
our %template_types = (
    'tmpl' => \&Pinwheel::View::ERB::parse_template,
    'erb'  => \&Pinwheel::View::ERB::parse_template,
    'data' => \&Pinwheel::View::Data::parse_template,
);
our $format_param = 'format';
our %format_defaults = (
    'atom' => { content_type => 'application/atom+xml', layout => 0 },
    'css'  => { content_type => 'text/css', layout => 0 },
    'gif'  => { content_type => 'image/gif', layout => 0 },
    'html' => { content_type => 'text/html' },
    'ics'  => { content_type => 'text/calendar', layout => 0 },
    'json' => { content_type => 'application/json', layout => 0 },
    'mp'   => { content_type => 'text/html' },
    'ram'  => { content_type => 'audio/x-pn-realaudio', layout => 0 },
    'rdf'  => { content_type => 'application/rdf+xml' },
    'rss'  => { content_type => 'application/rss+xml', layout => 0 },
    'ssi'  => { content_type => 'text/plain', layout => 0 },
    'sssi' => { content_type => 'text/html', layout => 0 },
    'txt'  => { content_type => 'text/plain', layout => 0 },
    'wml'  => { content_type => 'text/vnd.wap.wml' },
    'xml'  => { content_type => 'application/xml', layout => 0 },
    'yaml' => { content_type => 'application/x-yaml', layout => 0 },
);
our $error_logger = \&default_error_logger;
our (%template_cache, %controllers, $layout_helpers);


sub initialise
{
    my ($hooks);

    $hooks = \%Config::Hooks::;
    $hooks->{initialise}() if (exists($hooks->{initialise}));
}

sub connect
{
    return $map->connect(@_);
}

sub dispatch
{
    my ($request, %args) = @_;
    my ($ctx, $hooks);

    # Odd idiom, just to keep coverage happy
    # Usually: $request->{time} ||= time();
    $request->{time} = time() if not $request->{time};

    Pinwheel::Context::reset();

    $ctx = Pinwheel::Context::get();
    $ctx->{request} = $request;
    $ctx->{response} = {headers => {}};
    $ctx->{rendering} = 0;

    Pinwheel::Context::get('render')->{format} = ['html'];

    $hooks = \%Config::Hooks::;
    if (exists($hooks->{before_dispatch})) {
        $hooks->{before_dispatch}($request);
    }

    eval {
        local $SIG{__DIE__} = sub {
            local $Carp::CarpLevel = $Carp::CarpLevel + 2;
            Carp::confess($_[0]);
        };
        _process_request(\%args, $ctx);
        render() unless $ctx->{headers};
        if ($hooks->{after_dispatch})
        {
            $hooks->{after_dispatch}($ctx->{headers}, \$ctx->{content});
        }
    };

    # Defensive: pass a copy of $@, not $@ itself
    render_500("$@") if ($@);

    Pinwheel::Database::finish_all();

    return ($ctx->{headers}, $ctx->{content});
}

sub _process_request
{
    my ($args, $ctx) = @_;
    my ($hooks, $route, $controller, $fn);

    $route = $map->match($ctx->{request}{path}, $ctx->{request}{method});
    $route = undef if (!_check_route_params($route));
    return render_404('No matching route') unless $route;
    # $route->{controller} and $route->{action} are now guaranteed to be
    # strings matching /^[a-z][a-z0-9_]*$/

    $controller = _get_controller($route->{controller});
    return render_404('Controller not found') unless $controller;
    $fn = $controller->{actions}{$route->{action}};
    return render_404('Action is missing or not in @ACTIONS') unless $fn;

    $ctx->{route} = $route;
    $ctx->{controller} = $controller;
    &$fn();
}

sub url_for
{
    my $name = (scalar(@_) & 1) ? shift : undef;
    my %params = @_;
    my ($ctx, $only_path, $path, $base);

    $ctx = Pinwheel::Context::get();

    $only_path = delete $params{only_path};
    $only_path = 1 unless defined($only_path);
    $path = $map->generate($name, %params, _base => $ctx->{route});
    return undef unless $path;

    if ($ctx->{request} && $path !~ /^\w+:\/\//) {
        $path = $ctx->{request}{base} . $path;
        $path = "http://$ctx->{request}{host}$path" unless $only_path;
    }
    return $path;
}

sub redirect_to
{
    my ($ctx, $status);
    my $url = shift;
    my %options = ();

    %options = @_ if (scalar(@_)>1);
    $status = delete $options{status} || 302;

    $ctx = Pinwheel::Context::get();
    if (defined $url && $url =~ /\//) {
        $url = "http://$ctx->{request}{host}$url" if ($url !~ /^\w+:\/\//);
    } else {
        $url = url_for($url, %options, only_path => 0);
    }

    # XXX $url might be undef, which should trigger a 500-ish error
    render(text => "Please see $url\n", status => $status, location => $url);
}

sub render
{
    my %options = @_;
    my ($ctx, $content, $format);

    $ctx = Pinwheel::Context::get();

    # XXX an error has occurred (double render) if this happens: don't silently
    # ignore it!
    return if ($ctx->{headers});

    # Set the top-level output format
    if (!$ctx->{rendering} && $options{format}) {
        Pinwheel::Context::get('render')->{format} = [$options{format}];
    }

    $ctx->{rendering}++;
    ($content, $format) = _render_content(\%options);
    $ctx->{rendering}--;

    if ($ctx->{rendering} == 0) {
        $content = $content->to_string($format) if ref($content);
        set_header('Content-Length', length($content));
        $ctx->{headers} = _render_headers(\%options, $format);
        $ctx->{content} = $content;
    }
    return $content;
}

sub render_to_string
{
    my %options = @_;
    my ($ctx, $content);

    $ctx = Pinwheel::Context::get();
    $ctx->{rendering}++;
    ($content) = _render_content(\%options);
    $ctx->{rendering}--;
    return $content;
}

sub default_error_logger
{
    my ($status, $msg, $depth) = @_;
    Carp::cluck("render_error [$depth]: $status $msg")
        if $status == 500;
}

sub render_error
{
    my ($status, $msg) = @_;
    my ($ctx, $format, $template);

    $ctx = Pinwheel::Context::get();
    $ctx->{headers} = undef;
    $ctx->{rendering} = 0;
    $ctx->{error}++ if ($status == 500);

    &$error_logger($status, $msg, $ctx->{error}||0);

    if (($ctx->{error} || 0) < 2) {
        $format = Pinwheel::Context::get('render')->{format}[0];
        $template = _get_template("shared/error$status.$format");
    }

    if (!$template) {
        render(text => $msg, status => $status);
    } else {
        eval {
            render(
                template => "shared/error$status",
                status => $status,
                locals => { msg => $msg }
            );
        };

        # Defensive: pass a copy of $@, not $@ itself
        render_500("$@") if $@;
    }

    $ctx->{error}-- if ($status == 500);
}

sub render_404
{
    render_error(404, @_);
}

sub render_500
{
    render_error(500, @_);
}

sub set_header
{
    my ($key, $value) = @_;
    my ($ctx);

    $ctx = Pinwheel::Context::get();
    $ctx->{response}{headers}{lc($key)} = [$key, $value];
}

sub request_time
{
    my $ctx = Pinwheel::Context::get();
    return $ctx->{request}{time};
}

sub request_time_model
{
    my $ctx = Pinwheel::Context::get();
    return Pinwheel::Model::Time->new($ctx->{request}{time});
}

sub expires_in
{
    my ($seconds) = @_;
    my ($ctx, $now);

    $ctx = Pinwheel::Context::get();
    $now = Pinwheel::Model::Time->new($ctx->{request}{time});
    set_header('Date', $now->rfc822);
    set_header('Expires', $now->add($seconds)->rfc822);
    set_header('Cache-Control', 'max-age=' . $seconds);
}

sub expires_at
{
    my ($expires) = @_;
    my ($ctx, $now, $seconds);

    $ctx = Pinwheel::Context::get();
    $now = Pinwheel::Model::Time->new($ctx->{request}{time});
    $seconds = $expires->timestamp - $now->timestamp;
    set_header('Date', $now->rfc822);
    set_header('Expires', $expires->rfc822);
    set_header('Cache-Control', 'max-age=' . $seconds);
}

sub expires_now
{
    set_header('Cache-Control', 'no-cache');
    set_header('Pragma', 'no-cache');
}

sub accepts
{
    my ($ctx, $format);

    $ctx = Pinwheel::Context::get('render');
    $format = Pinwheel::Context::get()->{route}{$format_param};
    $format = $ctx->{format}[0] if (!$format);

    foreach (@_) {
        if ($format eq $_) {
            $ctx->{format}[0] = $format;
            return 1;
        }
    }
    render_error(404, 'Format not supported');
    return 0;
}

sub respond_to
{
    my ($ctx, $format, $old_format, $fn);

    $ctx = Pinwheel::Context::get('render');
    $old_format = pop @{$ctx->{format}};
    $format = Pinwheel::Context::get()->{route}{$format_param};
    $format = $old_format if (!$format);
    push @{$ctx->{format}}, $format;

    my %handlers;
    while (@_)
    {
        my $key = shift;
        my $handler = ((ref($_[0]) eq "CODE") ? shift : undef);
        $handlers{$key} = $handler;
    }

    if (!exists($handlers{$format})) {
        render_error(404, 'Format not supported');
    } else {
        $fn = $handlers{$format};
        if (defined($fn)) {
            &$fn();
        } else {
            render(format => $format);
        }
    }

    $ctx->{format}[-1] = $old_format;
}

sub params
{
    my $route = Pinwheel::Context::get()->{route};

    return $route->{$_[0]} if scalar(@_) == 1;
    return [map { $route->{$_} } @_];
}

sub query_params
{
    my ($ctx, $q);

    $ctx = Pinwheel::Context::get();
    unless ($q = $ctx->{query}) {
        my $t = $ctx->{request}{query};
        $t = '' if not defined $t;
        $q = $ctx->{query} = {
            map { ($_ eq "") ? () : _query_key_value($_) } split(/&+/, $t)
        };
    }

    return $q->{$_[0]} if scalar(@_) == 1;
    return [map { $q->{$_} } @_];
}

sub _query_key_value
{
    my ($s) = @_;
    my ($key, $value);

    $s =~ tr/+/ /;

    ($key, $value) = split('=', $s, 2);
    $key =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    $value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge if $value;

    return ($key, $value || '');
}

sub format
{
    return Pinwheel::Context::get('render')->{format}[-1];
}

sub set_base_format
{
    Pinwheel::Context::get('render')->{format}[0] = $_[0];
}

sub set_format_param
{
    $format_param = $_[0];
}

sub expand_static_path
{
    my ($path) = @_;
    my ($ctx, $base);

    $path = '/' . $path unless $path =~ /^\//;

    $ctx = Pinwheel::Context::get();
    if ($ctx->{request}) {
        $base = $ctx->{request}{base};
        $path =~ s/^$base//;
    }

    return if ($path =~ /\/\./);

    $path =~ s/\/{2,}/\//g;
    return $static_root . $path;
}

sub set_static_root
{
    $static_root = shift;
}

sub set_templates_root
{
    $templates_root = shift;
}


# ==============================================================================


sub _render_headers
{
    my ($opts, $format) = @_;
    my ($h, $type);

    $h = Pinwheel::Context::get()->{response}{headers};

    $h->{'status'} = ['Status', $opts->{status}] if $opts->{status};
    $h->{'status'} = ['Status', 200] unless $h->{'status'};

    $type = $format_defaults{$format}{content_type} if $format;
    $type = 'text/html' unless $type;
    $type = $h->{'content-type'}[1] if $h->{'content-type'};
    $type = $opts->{content_type} if $opts->{content_type};
    $h->{'content-type'} = ['Content-Type', $type];

    $h->{'location'} = ['Location', $opts->{location}] if $opts->{location};

    return $h;
}

sub _render_content
{
    my $options = shift;
    my ($ctx, $renderctx, $name, $format, $srcformat);
    my ($content, $template, $layout);

    if (exists($options->{text})) {
        # Render a static piece of text
        $content = $options->{text};
        $format = 'txt';
    } else {
        $ctx = Pinwheel::Context::get();
        $renderctx = Pinwheel::Context::get('render');

        $name = _make_template_name($options, $ctx->{route});
        croak "Invalid template name" unless $name;
        $format = $options->{format};
        $format = $renderctx->{format}[-1] if !$format;
        $srcformat = $options->{via};
        $srcformat = $format if !$srcformat;
        $template = _get_template("$name.$srcformat");
        croak "Unable to find template $name" unless $template;
        $layout = _get_layout($srcformat, $options);

        push @{$renderctx->{format}}, $srcformat;
        $content = _render_template($template, $layout, $options->{locals});
        pop @{$renderctx->{format}};
    }

    return ($content, $format);
}

sub _render_template
{
    my ($template, $layout, $locals) = @_;
    my ($ctx, $globals, $helpers, $content);

    $ctx = Pinwheel::Context::get();

    $locals = {} if (!$locals);
    $globals = Pinwheel::Context::get('template');
    $helpers = $ctx->{controller}{helpers};
    $helpers = _get_helpers(['Pinwheel::Helpers', 'Application']) if (!$helpers);
    # Any supplied locals are sent to the layout too, so don't pass a reference
    # to the original here or it might be changed
    $content = $template->({%$locals}, $globals, $helpers);

    # The layout (if any) is added afterwards so that it has access to any
    # state built up by the content template, eg a list of Javascript or CSS
    # files to include
    if ($layout) {
        Pinwheel::Context::get('render')->{content}{'layout'} = $content;
        $content = $layout->($locals, $globals, _get_layout_helpers());
    }

    return $content;
}

sub preload_templates
{
    my ($types, $w);

    $types = join('|', keys %template_types);
    $w = sub {
        if (/^\Q${templates_root}\E\/(.+)\.(${types})$/) {
            # Ignore errors.  Could mean there are files in the templates
            # directory that aren't named like valid templates.
            _get_template($1) if -f $_;
        }
    };

    File::Find::find({ no_chdir => 1, wanted => $w }, $templates_root);
}

sub _get_template
{
    my ($name) = @_;
    my ($ext, $filename, $template);

    return $template_cache{$name} if exists($template_cache{$name});
    return if $name !~ m{^\w+/\w+\.\w+$};

    foreach $ext (keys %template_types) {
        next unless -f ($filename = "$templates_root/$name.$ext");
        $template = read_file($filename, binmode => ':raw');
        $template = $template_types{$ext}->($template, $name);
        $template_cache{$name} = $template;
        return $template;
    }

    # Cache failed lookups to avoid hitting the filesystem repeatedly for
    # non-existent layout files etc.
    $template_cache{$name} = undef;
}

sub _get_layout
{
    my ($format, $options) = @_;
    my ($ctx, $controller, $base, $name, $layout);

    $ctx = Pinwheel::Context::get();
    $controller = $ctx->{route}{controller};

    # When rendering a partial the layout comes from the same directory,
    # otherwise it comes from 'layouts'.
    if ($options->{partial}) {
        $base = $1 if $options->{partial} =~ /^(\w+)\//;
        $base = $controller if !$base;
        $base = $base . '/_';
    } else {
        $base = 'layouts/';
    }

    if (defined($options->{layout})) {
        $name = $options->{layout};
    } elsif ($options->{partial}) {
        $name = 0;
    } elsif (defined($ctx->{controller}{layout})) {
        $name = $ctx->{controller}{layout};
    } else {
        $name = $format_defaults{$format}{layout};
    }

    if (!defined($name)) {
        # Automatic layout (eg, no layout option or layout => undef)
        $layout = _get_template("${base}$controller.$format") if $controller;
        $layout = _get_template("${base}application.$format") if !$layout;
    } elsif ($name) {
        # Specified layout (eg, layout => 'foo')
        $layout = _get_template("${base}$name.$format");
        croak "Unable to find ${base}$name" unless $layout;
    } else {
        # Layout disabled (eg, layout => 0)
    }
    return $layout;
}


sub _get_controller
{
    my $name = shift;
    my ($info, $pkgname, $pkg, $layout, $helpers);

    return $info if ($info = $controllers{$name});

    $pkgname = _make_mixed_case($name);
    $pkg = _get_package('Controllers::' . $pkgname);
    return unless $pkg->{'ACTIONS'};

    $layout = $pkg->{'LAYOUT'};
    $layout = $$layout if $layout;
    $helpers = $pkg->{'HELPERS'} || [];
    $helpers = ['Pinwheel::Helpers', 'Application', @$helpers, $pkgname];
    return $controllers{$name} = {
        layout => $layout,
        helpers => _get_helpers($helpers),
        actions => _get_actions($pkg)
    };
}

sub _get_layout_helpers
{
    if (!$layout_helpers) {
        $layout_helpers = _get_helpers(['Pinwheel::Helpers', 'Application']);
    }
    return $layout_helpers;
}

sub _get_helpers
{
    my $helpers = shift;
    my ($name, $fns, $pkg, $exports);

    $fns = {};
    foreach $name (@$helpers) {
        $name = "Helpers::$name" unless $name =~ /::/;
        $pkg = _get_package($name);
        next unless $exports = $pkg->{'EXPORT_OK'};
        foreach (@$exports) {
            next unless $pkg->{$_};
            $fns->{$_} = \&{$pkg->{$_}};
        }
    }
    return $fns;
}

sub _get_actions
{
    my $pkg = shift;
    my ($actions, $fns);

    $actions = $pkg->{'ACTIONS'};
    foreach (@$actions) {
        next unless $pkg->{$_};
        $fns->{$_} = \&{$pkg->{$_}};
    }

    return $fns;
}


sub _check_route_params
{
    my ($params) = @_;

    return (
        $params
        && $params->{controller} =~ /^[a-z][a-z0-9_]*$/
        && $params->{action} =~ /^[a-z][a-z0-9_]*$/
    );
}


sub _make_template_name
{
    my ($options, $route) = @_;
    my ($name, $format);

    if ($options->{action}) {
        $name = "$route->{controller}/$options->{action}";
    } elsif ($options->{template}) {
        $name = $options->{template};
    } elsif ($options->{partial}) {
        $name = $options->{partial};
        $name = "$route->{controller}/$name" unless $name =~ /\//;
        $name =~ s!/!/_!;
    } else {
        $name = "$route->{controller}/$route->{action}";
    }

    return unless $name =~ m{^(\w+/\w+)$};
    return $name;
}


sub _make_mixed_case
{
    my $name = shift;
    # Convert some_name to SomeName
    $name =~ s/_+/ /g;
    $name =~ s/\b(\w)/\U$1/g;
    $name =~ s/ +//g;
    return $name;
}

sub _get_package
{
    my $name = shift;
    my $pkg = \%::;
    $pkg = $pkg->{"$_\::"} foreach split(/::/, $name);
    return $pkg;
}

1;

__DATA__


=head1 NAME 

Controller - Root application controller/dispatcher

=head1 SYNOPSIS

    my ($cgi, $request, $headers, $content);

    BEGIN {
        Pinwheel::Controller::connect(':controller/:action/:id');
    }

    $cgi = new CGI();
    $request = {
        host => $ENV{'HTTP_HOST'},
        path => $ENV{'PATH_INFO'},
        base => '/'
    };
    ($headers, $content) = Controller::dispatch($request);
    print $cgi->header(%$headers);
    print $content;

=head1 DESCRIPTION

Dispatch an HTTP request to the appropriate controller package and return the
generated headers and content.

=head1 ROUTINES

=over 4

=item connect(...)

Add a route to the list recognised by the application.  See L<Pinwheel::Mapper/connect>.  

=item dispatch(REQUEST, ARGS)

TODO, document me.

=item url_for([NAME], PARAMS)

Generate a URL from a route (added with L</connect>).  See L<Pinwheel::Mapper/generate>.

As well as the params allowed by C<$mapper-E<gt>generate>, the following additional params are supported:

=over 4

=item only_path

Boolean; defaults to true.

Normally, URLs for this site will be partial, e.g. "/some/path".
Setting C<only_path => 0> causes such URLs to become absolute, e.g.
"http://host.example.com/some/path".

=back

=item redirect_to(URL) or redirect_to([NAME], PARAMS)

Render a 302 redirect.  The target URL (i.e. the "Location" header of the
response) is found as follows:

The form C<redirect_to($url)> is recognised by the fact that C<$url> contains
at least one "/".  The url is prefixed by "http://" plus this request's "Host"
header, unless C<$url> matches C<m[^\w+://]>.

Otherwise, the URL is found by calling C<url_for([NAME], PARAMS, only_path =E<gt> 0)>.

=item render(OPTIONS)

TODO, document me.

=item render_to_string(OPTIONS)

TODO, document me.

=item render_error(STATUS, MESSAGE)

TODO, document me.

Note: not exportable.

Before doing whatever it is that C<render_error> does, it calls the sub given
by C<$Controller::error_logger> in void context with three arguments: STATUS,
MESSAGE, and the error depth.  (TODO: define the error depth).

C<$Controller::error_logger> defaults to C<\&Controller::default_error_logger>,
which shows the error via C<Carp::cluck> if the STATUS is 500.

=item render_404(MSG)

Calls C<render_error(404, MSG)>

=item render_500(MSG)

Calls C<render_error(500, MSG)>

=item set_header(KEY, VALUE)

TODO, document me.

=item $time = request_time()

Returns the start time of the request, as specified by the 'time' argument to
C<dispatch>.  (Hence, expressed as seconds since the epoch).

=item $time = request_time_model()

Like C<request_time>, but returns the answer as a C<Pinwheel::Model::Time> object.
(Always returns a new model object, so it's safe to modify the returned object if you wish).

=item expires_in($seconds)

Adds headers via C<set_header> such that the response expires C<$seconds>
seconds after the request time.

=item expires_at($time)

Adds headers via C<set_header> such that the response expires at the time
specified by $time (which should be a Pinwheel::Model::Time object).

=item expires_now()

Adds headers via C<set_header> such that the response expires now.

=item accepts(...)

TODO, document me.

=item respond_to("$format"[, $handler_sub], ...)

C<respond_to> is called with an alternating list of (format-name,
handler-coderef) pairs, except that each handler-coderef is optional.  For
example:

  respond_to('html', 'txt', 'xml' => \&xml_handler, 'json');

Once a format is selected (TODO, document this) the handler is then invoked;
if no handler was specified, the following is used:

            render(format => $format);

TODO, also document 404 "Format not supported" errors and the format stack.

=item params(KEY, [KEY, ...])

TODO, document me.

=item query_params(...)

TODO, document me.

=item format(...)

TODO, document me.

=item set_base_format(...)

TODO, document me.

=item set_format_param($name)

Sets C<$format_param>.  This specifies the name of the route parameter used to select
among multiple formats, as used by C<accepts> and C<respond_to>.

The default format_param is "format".

=item expand_static_path(...)

TODO, document me.

=item set_static_root(ROOT)

TODO, document me.

=item set_templates_root(ROOT)

TODO, document me.

=item preload_templates()

Preloads all templates found under the templates_root.

=back

=head1 EXPORTS

Exported by default: url_for redirect_to render render_to_string render_404
render_500 set_header expires_in expires_at expires_now accepts respond_to
params query_params

May be exported: connect dispatch format set_base_format set_format_param
expand_static_path set_static_root set_templates_root request_time request_time_model

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut
