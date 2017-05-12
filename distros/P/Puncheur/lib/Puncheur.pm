package Puncheur;
use 5.010;
use strict;
use warnings;

use version 0.77; our $VERSION = version->declare("v0.3.0");

use Carp ();
use Clone qw/clone/;
use Config::PL ();
use Encode;
use File::Spec;
use Plack::Session;
use Plack::Util;
use Scalar::Util ();
use URL::Encode;

use Puncheur::Request;
use Puncheur::Response;
use Puncheur::Trigger qw/add_trigger call_trigger get_trigger_code/;

sub new {
    my ($base_class, %args) = @_;
    %args = (
        %{ $base_class->setting || {} },
        %args,
    );

    if ($base_class eq __PACKAGE__ && !defined $args{app_name}) {
        state $count = 0;
        $args{app_name} = "Puncheur::_Sandbox" . $count++;
    }

    my $class = $args{app_name} // $base_class;
    if ($args{app_name}) {
        local $@;
        eval {
            Plack::Util::load_class($class);
            $class->import if $class->can('import');
        };
        if ($@) {
            no strict 'refs'; @{"$class\::ISA"} = ($base_class);
        }
        Carp::croak "$class is not $base_class class" unless $class->isa($base_class);
    }
    my $self = bless { %args }, $class;
    $self->config; # surely assign config
    $self;
}
our $_CONTEXT;
sub context { $_CONTEXT }

my %_SETTING;
sub setting {
    my ($class, %args) = @_;

    if (%args) {
        Carp::croak qq[can't set class setting of $class] if $class eq __PACKAGE__;

        my %prev = %{ $_SETTING{$class} || {} };
        $_SETTING{$class} = {
            %prev,
            %args,
        };
    }
    $_SETTING{$class};
}

# -------------------------------------------------------------------------
# Hook points:
# You can override them.
sub create_request  { Puncheur::Request->new($_[1], $_[0]) }
sub create_response {
    shift;
    my $res = Puncheur::Response->new(@_);
    $res->header( 'X-Content-Type-Options' => 'nosniff' );
    $res->header( 'X-Frame-Options'        => 'DENY'    );
    $res->header( 'Cache-Control'          => 'private' );
    $res;
}

# -------------------------------------------------------------------------
# Application settings:
sub app_name {
    my $self = shift;
    ref $self || $self;
}

sub asset_dir {
    my $self = shift;

    my $asset_dir;
    if (ref $self and $asset_dir = $self->{asset_dir}) {
        $asset_dir = File::Spec->catfile($self->base_dir, $asset_dir)
            unless File::Spec->file_name_is_absolute($asset_dir);
    }
    elsif ($self->can('share_dir')) {
        $asset_dir = $self->share_dir;
    }
    else {
        $asset_dir = File::Spec->catfile($self->base_dir, 'share');
    }
    $self->_cache_method($asset_dir);
}

sub base_dir {
    my $self = shift;
    my $class = $self->app_name;

    my $base_dir = do {
        my $path = $class;
        $path =~ s!::!/!g;
        my $app_name = ref $self && $self->{app_name};
        if (!$app_name and my $libpath = $INC{"$path.pm"}) {
            $libpath =~ s!\\!/!g; # win32
            if ($libpath =~ s!(?:blib/)?lib/+$path\.pm$!!) {
                File::Spec->rel2abs($libpath || './');
            }
            else {
                File::Spec->rel2abs('./');
            }
        }
        else {
            File::Spec->rel2abs('./');
        }
    };
    $class->_cache_method($base_dir);
}

sub mode_name  { $ENV{PLACK_ENV} }
sub debug_mode { $ENV{PUNCHEUR_DEBUG} }

# you can override 2 methods below
sub html_content_type { 'text/html; charset=UTF-8' }
sub encoding { state $enc = Encode::find_encoding('utf-8') }

# -------------------------------------------------------------------------
# view and render:
# You can override them
sub template_dir {
    my $self = shift;
    my $class = $self->app_name;

    my $tmpl = $self->{template_dir} ? $self->{template_dir} : File::Spec->catfile($self->asset_dir, 'tmpl');
    my @tmpl = ref $tmpl ? @$tmpl : ($tmpl);

    @tmpl = map {
        ref $_ && ref $_ eq 'CODE'                      ? $_->() :
        ref $_ || File::Spec->file_name_is_absolute($_) ? $_     :
                                                          File::Spec->catfile($self->base_dir, $_)
    } @tmpl;

    $self->_cache_method(\@tmpl);
}

sub create_view {
    my $self = shift;

    state $settings = {
        MT => {
            'Text::MicroTemplate::Extended' => {
                include_path => $self->template_dir,
                use_cache    => 1,
                macro         => {
                    raw_string => sub($) { Text::MicroTemplate::EncodedString->new($_[0]) },
                    uri_for    => sub { $self->context->uri_for(@_) },
                    uri_with   => sub { $self->context->req->uri_with(@_) }
                },
                template_args => {
                    c => sub { $self->context },
                    s => sub { $self->context->stash },
                }
            },
        },
        Xslate => {
            'Text::Xslate' => {
                path => $self->template_dir,
                module   => [
                    'Text::Xslate::Bridge::Star',
                ],
                function => {
                    c         => sub { $self->context },
                    uri_for   => sub { $self->context->uri_for(@_) },
                    uri_with  => sub { $self->context->req->uri_with(@_) }
                },
                ($self->debug_mode ? ( warn_handler => sub {
                    Text::Xslate->print( # print method escape html automatically
                        '[[', @_, ']]',
                    );
                } ) : () ),
            },
        },
    };

    my @args;
    if (my $v = $self->{view}) {
        @args = !ref $v ? %{ $settings->{$v} } : %$v;
    }
    else {
        @args = %{ $settings->{Xslate} };
    }

    require Tiffany;
    my $view = Tiffany->load(@args);
}

sub view {
    my $self = shift;

    $self->_cache_method($self->create_view);
}

sub render {
    my $self = shift;
    my $html = $self->view->render(@_);

    for my $code ($self->get_trigger_code('HTML_FILTER')) {
        $html = $code->($self, $html);
    }

    $html = Encode::encode($self->encoding, $html);
    return $self->create_response(
        200,
        [
            'Content-Type'   => $self->html_content_type,
            'Content-Length' => length($html)
        ],
        [$html],
    );
}

# -------------------------------------------------------------------------
# dispatcher and dispatch:
# You can override them
sub create_dispatcher {
    my $self = shift;
    my $class = $self->app_name;

    my $dispatcher_pkg = $class . '::Dispatcher';
    local $@;
    eval {
        Plack::Util::load_class($dispatcher_pkg);
        $dispatcher_pkg->import if $dispatcher_pkg->can('import');
    };
    if ($@) {
        my $base_dispatcher = $self->{dispatcher} // 'PHPish';

        $base_dispatcher = Plack::Util::load_class($base_dispatcher, 'Puncheur::Dispatcher');
        $base_dispatcher->import if $base_dispatcher->can('import');
        no strict 'refs'; @{"$dispatcher_pkg\::ISA"} = ($base_dispatcher);
    }

    $dispatcher_pkg->can('new') ? $dispatcher_pkg->new($self) : $dispatcher_pkg;
}

sub dispatcher {
    my $self = shift;

    $self->_cache_method($self->create_dispatcher);
}

sub dispatch {
    my $self = shift;
    $self->dispatcher->dispatch($self);
}

# -------------------------------------------------------------------------
# Config:
# You can override them
sub load_config {
    my $self = shift;

    my $config_file = $self->{config} || File::Spec->catfile('config', 'common.pl');
    return $config_file if ref $config_file;
    $config_file = File::Spec->catfile($self->base_dir, $config_file)
        unless File::Spec->file_name_is_absolute($config_file);

    -e $config_file ? scalar Config::PL::config_do($config_file) : {};
}
sub config {
    my $self = shift;

    $self->_cache_method($self->load_config);
}

# -------------------------------------------------------------------------
# Util:
sub add_method {
    my ($klass, $method, $code) = @_;
    no strict 'refs';
    *{"${klass}::${method}"} = $code;
}

sub _cache_method {
    my ($self, $stuff) = @_;
    return $stuff unless ref $self; # don't cache in class method

    my $class = $self->app_name;

    my (undef, undef, undef, $sub) = caller(1);
    $sub = +(split /::/, $sub)[-1];
    my $code = sub { $stuff };
    $class->add_method($sub, $code);
    $stuff;
}

# -------------------------------------------------------------------------
# Attributes:
sub request           { $_[0]->{request} }
sub req               { $_[0]->{request} }

sub session {
    my $c = shift;
    $c->{session} ||= Plack::Session->new($c->request->env);
}

sub stash {
    my $c = shift;
    $c->{stash} ||= {};
}

# -------------------------------------------------------------------------
# Methods:
sub redirect {
    my ($self, $location, $params) = @_;
    my $url = do {
        if ($location =~ m{^https?://}) {
            $location;
        }
        else {
            my $url = $self->req->base;
            $url =~ s{/+$}{};
            $location =~ s{^/+([^/])}{/$1};
            $url .= $location;
        }
    };
    if (my $ref = ref $params) {
        my @ary = $ref eq 'ARRAY' ? @$params : %$params;
        my $uri = URI->new($url);
        $uri->query_form($uri->query_form, map { Encode::encode($self->encoding, $_) } @ary);
        $url = $uri->as_string;

    }
    return $self->create_response(
        302,
        ['Location' => $url],
        []
    );
}

sub _build_query {
    my ($self, $query) = @_;

    my @query = !$query ? () : ref $query eq 'HASH' ? %$query : @$query;
    my @q;
    while (my ($key, $val) = splice @query, 0, 2) {
        $val = URL::Encode::url_encode(Encode::encode($self->encoding, $val));
        push @q, "${key}=${val}";
    }
    @q ? '?' . join('&', @q) : '';
}

sub _build_uri {
    my ($self, $root, $path, $query) = @_;

    $root =~ s{([^/])$}{$1/};
    $path =~ s{^/}{};

    $root . $path . $self->_build_query($query);
}

sub uri_for {
    my ($self, $path, $query) = @_;
    my $root = $self->req->{env}->{SCRIPT_NAME} || '/';

    $self->_build_uri($root, $path, $query);
}

sub abs_uri_for {
    my ($self, $path, $query) = @_;
    my $root = $self->req->base;

    $self->_build_uri($root, $path, $query);
}

# -------------------------------------------------------------------------
# PSGInise:
sub to_psgi {
    my ($self, ) = @_;

    $self = $self->new unless ref $self;
    return sub { $self->handle_request(shift) };
}
sub to_app { goto \&to_psgi }

sub run {
    my $self = shift;
    my %opts = @_ == 1 ? %{$_[0]} : @_;

    my %server;
    my $server = delete $opts{server};
    $server{server} = $server if $server;

    my @options = %opts;
    require Plack::Runner;

    my $runner = Plack::Runner->new(
        %server,
        options => \@options,
    );
    $runner->run($self->to_app);
}

sub handle_request {
    my ($self, $env) = @_;

    my $c = $self->clone;
    $c->{request} = $c->create_request($env);

    local $_CONTEXT = $c;

    my $response;
    for my $code ($c->get_trigger_code('BEFORE_DISPATCH')) {
        $response = $code->($c);
        goto PROCESS_END if Scalar::Util::blessed($response) && $response->isa('Plack::Response');
    }
    $response = $c->dispatch or die "cannot get any response";
PROCESS_END:
    $c->call_trigger('AFTER_DISPATCH' => $response);

    return $response->finalize;
}

# -------------------------------------------------------------------------
# Plugin
sub load_plugins {
    my ($class, @args) = @_;
    while (@args) {
        my $module = shift @args;
        my $conf   = @args > 0 && ref $args[0] ? shift @args : undef;
        $class->load_plugin($module, $conf);
    }
}

sub load_plugin {
    my ($class, $module, $conf) = @_;

    $module = Plack::Util::load_class($module, 'Puncheur::Plugin');
    {
        no strict 'refs';
        for my $method ( @{"${module}::EXPORT"} ){
            use strict 'refs';
            $class->add_method($method, $module->can($method));
        }
    }
    $module->init($class, $conf) if $module->can('init');
}

# -------------------------------------------------------------------------
# Raise Error:
my %StatusCode = (
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Request Range Not Satisfiable',
    417 => 'Expectation Failed',
    418 => 'I\'m a teapot',            # RFC 2324
    422 => 'Unprocessable Entity',            # RFC 2518 (WebDAV)
    423 => 'Locked',                          # RFC 2518 (WebDAV)
    424 => 'Failed Dependency',               # RFC 2518 (WebDAV)
    425 => 'No code',                         # WebDAV Advanced Collections
    426 => 'Upgrade Required',                # RFC 2817
    428 => 'Precondition Required',
    429 => 'Too Many Requests',
    431 => 'Request Header Fields Too Large',
    449 => 'Retry with',                      # unofficial Microsoft
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295
    507 => 'Insufficient Storage',            # RFC 2518 (WebDAV)
    509 => 'Bandwidth Limit Exceeded',        # unofficial
    510 => 'Not Extended',                    # RFC 2774
    511 => 'Network Authentication Required',
);

while ( my ($code, $msg) = each %StatusCode) {
    no strict 'refs';
    *{__PACKAGE__ ."::res_$code"} = sub {
        use strict 'refs';
        my $self = shift;
        my $content = $self->error_html($code, $msg);
        $self->create_response(
            $code,
            [
                'Content-Type' => 'text/html; charset=utf-8',
                'Content-Length' => length($content),
            ],
            [$content]
        );
    }
}

# You can override it
sub error_html {
    my ($self, $code, $msg) = @_;
sprintf q[<!doctype html>
<html>
    <head>
        <meta charset=utf-8 />
    </head>
    <body>
        <div class="code">%s</div>
        <div class="message">%s</div>
    </body>
</html>], $code, $msg;
}

1;
__END__

=encoding utf-8

=head1 NAME

Puncheur - a web application framework

=head1 SYNOPSIS

    package MyApp;
    use parent 'Puncheur';
    use Puncheur::Dispatcher::Lite;
    use Data::Section::Simple ();
    __PACKAGE__->setting(
        template_dir => [Data::Section::Simple::get_data_section],
    );
    any '/' => sub {
        my $c = shift;
        $c->render('index.tx');
    };
    1;
    __DATA__
    @@ index.tx
    <h1>It Works!</h1>

And in your console,

    % plackup -MMyApp -e 'MyApp->new->to_psgi'

=head1 DESCRIPTION

Puncheur is a web application framework.

B<THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.>

=head1 INTERFACE

=head2 Constructor

=head3 new

    my $app = MyApp->new(%opt);

=over

=item view

=item config

=item dispatcher

=item template_dir

=item asset_dir

=item app_name

=back

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

