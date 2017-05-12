package Spike::Site::Router;

use strict;
use warnings;

use base qw(Spike::Site::Handler);

use Spike::Error;
use Spike::Site::Router::Route;
use Spike::Cache;

use Carp;

use HTTP::Status qw(:constants);
use Plack::MIME;

use POSIX qw(strftime);
use Date::Parse;

use List::Util qw(first uniq);
use List::MoreUtils qw(zip);
use Scalar::Util qw(blessed);

sub route { (shift->{route} ||= Spike::Site::Router::Route->new)->route(@_) }

sub config {
    my $self = shift;
    my $config = $self->{config} ||= Spike::Config->new;

    return $config->(@_) if @_;
    return $config;
}

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = $class->SUPER::new;

    $self->startup;
    $self->_init_config;

    return $self;
}

sub cache {
    my $self = shift;
    my $config = $self->config->site_route_cache;

    return $self->{cache} ||= Spike::Cache->new(
        name          => 'Route cache',
        debug         => $self->debug,

        max_records   => $config->max_records('int', 10240),
        max_ttl       => $config->max_ttl('int', 3600),
        max_idle_time => $config->max_idle_time('int', 300),
        purge_time    => $config->purge_time('int', 300),
    );
}

sub _init_config {
    my $self = shift;

    (my $site_name = lc ref $self) =~ s/::.*$//;
    my $site_home = "$FindBin::Bin/..";

    my %defaults = (
        site_name       => $site_name,
        config_path     => "$site_home/conf",
        template_path   => "$site_home/tmpl/$site_name",
        static_path     => "$site_home/web/$site_name",
    );

    $self->config->site->$_(set => $defaults{$_})
        for keys %defaults;
}

sub _find_handlers {
    my ($self, $route) = @_;

    my (@routes, %errors, @names);

    while ($route) {
        unshift @routes, $route;
        unshift @names, $route->name;

        $route = $route->parent;
    }

    shift @names; # exclude root

    my $prepare = sub { @_ };
    my $finalize = sub {};

    for $route (@routes) {
        $prepare = $route->prepare || $prepare;
        $finalize = $route->finalize || $finalize;

        $errors{$_} = [ $route->error($_), $prepare, $finalize ]
            for $route->errors;
    }

    return $prepare, $finalize, \%errors, \@names;
}

sub _try_static {
    my ($self, $req, $res, $path) = @_;

    return if $path =~ m!(^|/)\.!;

    my @files = length $path ? ($path, "$path/index.html") : ("index.html");

    for my $file (@files) {
        my $full_path = $self->config->site->static_path."/".$file;

        next unless -f $full_path && open my $fh, '<', $full_path;

        return 1 if $req->method ne 'GET';

        my ($size, $mtime) = (stat $fh)[7, 9];

        $res->header('Last-Modified' => strftime('%c', localtime $mtime));

        my $req_mtime = first { defined $_ } map { str2time($_) }
            $req->header('If-Modified-Since');

        if (!$req_mtime || $req_mtime < $mtime) {
            my $suffix = ($file =~ m!(\.[^/.]+)?$!)[0] || '.html';

            $res->content_length($size);
            $res->content_type(Plack::MIME->mime_type($suffix));

            $res->body($fh);
        }
        else {
            $res->status(HTTP_NOT_MODIFIED);
        }

        throw Spike::Error::HTTP_OK;
    }

    return;
}

sub _handle_error {
    my ($self, $req, $res, $error, $errors) = @_;

    $error = new Spike::Error::HTTP($error) if !ref $error;

    my $class = ref $error;
    my $is_http = $error->isa('Spike::Error::HTTP');

    my $handlers = $errors->{$class} || ($is_http && $errors->{$error->value});

    throw $error if !$handlers;

    %$res = %{ $is_http ?
        $req->new_response($error->value, $error->headers) :
        $req->new_response(HTTP_INTERNAL_SERVER_ERROR)
    };

    my ($handler, $prepare, $finalize) = @$handlers;

    $finalize->($req, $res,
        $handler->($req, $res,
            $prepare->($req, $res, $error)
        )
    );
}

sub handler {
    my ($self, $req, $res) = @_;

    my $path = $req->safe_path;

    my @methods = $self->debug &&
        $self->_try_static($req, $res, $path) ? qw(GET) : ();

    my @handlers = $self->cache->get($path);

    if (!@handlers) {
        my ($found, $last_found) = $self->route->find($path);

        @handlers = (
            $found,
            $self->_find_handlers($found || $last_found),
            [ split m!/!, $path ],
        );

        $self->cache->store($path, @handlers);
    }

    my ($route, $prepare, $finalize, $errors, $names, $values) = @handlers;

    $req->_bind_named_url_parameters(zip @$names, @$values);

    my $handler;

    if ($route) {
        $handler = $route->method($req->method) || $route->method;
        push @methods, $route->methods;
    }

    if (!$handler) {
        if (@methods) {
            $self->_handle_error($req, $res, new Spike::Error::HTTP(
                HTTP_METHOD_NOT_ALLOWED, allow => join(', ', uniq @methods),
            ), $errors);
        }
        else {
            $self->_handle_error($req, $res, HTTP_NOT_FOUND, $errors);
        }
        return;
    }

    eval {
        $finalize->($req, $res,
            $handler->($req, $res,
                $prepare->($req, $res)
            )
        );
    };
    if (my $error = $@) {
        if (blessed $error) {
            if ($error->isa('Spike::Error::HTTP_OK')) {
                throw $error;
            }
            elsif ($error->isa('Spike::Error::HTTP')) {
                carp "HTTP error: status=".$error->value.", text=\"".$error->text."\"";
                $self->_handle_error($req, $res, $error, $errors);
            }
            elsif ($error->isa('Spike::Error')) {
                carp "Error: class=".ref($error).", text=\"".$error->text."\"";
                $self->_handle_error($req, $res, $error, $errors);
            }
            else {
                carp "Error: class=".ref($error).", text=\"".($error->can('text') ? $error->text : "$error")."\"";
                $self->_handle_error($req, $res, HTTP_INTERNAL_SERVER_ERROR, $errors);
            }
        }
        else {
            carp $error;
            $self->_handle_error($req, $res, HTTP_INTERNAL_SERVER_ERROR, $errors);
        }
    }
}

sub startup {}

1;
