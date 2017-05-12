package Plack::Middleware::TemplateToolkit;
# ABSTRACT: Serve files with Template Toolkit and Plack
$Plack::Middleware::TemplateToolkit::VERSION = '0.28';
use strict;
use warnings;
use 5.008_001;

use parent 'Exporter'; # for 'use Plack::Middleware::TemplateToolkit $version;'
use parent 'Plack::Middleware';
use Plack::Request 0.994;
use Plack::MIME;
use Template 2;
use Scalar::Util qw(blessed);
use HTTP::Status qw(status_message);
use Time::HiRes;
use Plack::Middleware::Debug::Timer;
use Encode;
use Carp;

# Configuration options as described in Template::Manual::Config
our @TT_CONFIG;
our @DEPRECATED;

BEGIN {
    @TT_CONFIG = qw(ENCODING START_TAG END_TAG OUTLINE_TAG TAG_STYLE PRE_CHOMP POST_CHOMP TRIM
        INTERPOLATE ANYCASE INCLUDE_PATH DELIMITER ABSOLUTE RELATIVE DEFAULT
        BLOCKS VIEWS AUTO_RESET RECURSION VARIABLES CONSTANTS
        CONSTANT_NAMESPACE NAMESPACE PRE_PROCESS POST_PROCESS PROCESS WRAPPER
        ERROR EVAL_PERL OUTPUT OUTPUT_PATH STRICT DEBUG DEBUG_FORMAT
        CACHE_SIZE STAT_TTL COMPILE_EXT COMPILE_DIR PLUGINS PLUGIN_BASE
        LOAD_PERL FILTERS LOAD_TEMPLATES LOAD_PLUGINS LOAD_FILTERS
        TOLERANT SERVICE CONTEXT STASH PARSER GRAMMAR
    );

    # the following ugly code is only needed to catch deprecated accessors
    @DEPRECATED = qw(pre_process process eval_perl interpolate post_chomp);
    no strict 'refs';
    my $module = "Plack::Middleware::TemplateToolkit";
    foreach my $name (@DEPRECATED) {
        *{ $module . "::$name" } = sub {
            my $correct = uc($name);
            carp $module. "$name is deprecated, use ::$correct";
            my $method = $module . "::$correct";
            &$method(@_);
            }
    }

    sub new {
        my $self = Plack::Component::new(@_);

        # Support 'root' config (matches MW::Static etc)
        # if INCLUDE_PATH hasn't been defined
        $self->INCLUDE_PATH( $self->root )
            if !$self->INCLUDE_PATH() && $self->root;

        foreach ( grep { defined $self->{$_} } @DEPRECATED ) {
            $self->$_;
        }
        $self;
    }
}

use Plack::Util::Accessor (
    qw(dir_index path extension content_type default_type tt root timer
        pass_through decode_request encode_response vars request_vars),
    @TT_CONFIG
);

sub prepare_app {
    my ($self) = @_;

    $self->dir_index('index.html')   unless $self->dir_index;
    $self->pass_through(0)           unless defined $self->pass_through;
    $self->default_type('text/html') unless $self->default_type;
    $self->decode_request('utf8')    unless defined $self->decode_request;
    $self->encode_response('utf8')   unless defined $self->encode_response;
    $self->request_vars( [] ) unless defined $self->request_vars;

    if ( not $self->vars ) {
        $self->vars( sub { return { params => shift->query_parameters } } );
    } elsif ( ref $self->vars eq 'HASH' ) {
        my $vars = $self->vars;
        $self->vars( sub { return $vars; } );
    } elsif ( ref $self->vars ne 'CODE' ) {
        die 'vars must be a code or hash reference, if defined';
    }

    my $config = {};
    foreach (@TT_CONFIG) {
        next unless $self->$_;
        $config->{$_} = $self->$_;
        $self->$_(undef);    # don't initialize twice
    }

    if ( $self->tt ) {
        die 'tt must be a Template instance'
            unless UNIVERSAL::isa( $self->tt, 'Template' );
        die 'Either specify a template with tt or Template options, not both'
            if %$config;
    } else {
        die 'No INCLUDE_PATH supplied' unless $config->{INCLUDE_PATH};
        $self->tt( Template->new($config) );
    }
}

sub call {    # adapted from Plack::Middleware::Static
    my ( $self, $env ) = @_;

    my $start = [ Time::HiRes::gettimeofday ] if $self->timer;
    my $res = $self->_handle_template($env);

    if ( !$res or ( $self->pass_through and $res->[0] == 404 ) ) {
        if ( $self->app ) {
            # pass to the next middleware/app
            $res = $self->app->($env);
            # if ( $self->catch_errors and $res->[0] =~ /^[45]/ ) {
            # TODO: process error message (but better use callback)
            # }
        } else {
            my $req = Plack::Request->new($env);
            $res = $self->process_error( 404, 'Not found', 'text/plain', $req );
        }
    }

    if ($self->timer) {
        my $end = [ Time::HiRes::gettimeofday ];
        $env->{'tt.start'} = Plack::Middleware::Debug::Timer->format_time($start);
        $env->{'tt.end'}   = Plack::Middleware::Debug::Timer->format_time($end);
        $env->{'tt.elapsed'}
            = sprintf '%.6f s', Time::HiRes::tv_interval $start, $end;
    }

    $res;
}

sub process_template {
    my ( $self, $template, $code, $vars ) = @_;

    my ( $content, $res );
    if ( $self->tt->process( $template, $vars, \$content ) ) {
        my $type = $self->content_type || do {
            Plack::MIME->mime_type($1) if $template =~ /(\.\w{1,6})$/;
            }
            || $self->default_type;
        if ( $self->encode_response ) {
            $content = encode( $self->encode_response, $content );
        }
        $res = [ $code, [ 'Content-Type' => $type ], [$content] ];
    } else {
        $res = $self->tt->error->as_string;
    }

    return $res;
}

sub process_error {
    my ( $self, $code, $error, $type, $req ) = @_;

    $code = 500 unless $code && $code =~ /^\d\d\d$/;
    $error = status_message($code) unless $error;
    $type = ( $self->content_type || $self->default_type || 'text/plain' )
        unless $type;

    # plain error without template
    return [ $code, [ 'Content-Type' => $type ], [$error] ]
        unless $self->{$code} and $self->tt;

    $req = Plack::Request->new( { 'tt.vars' => {} } )
        unless blessed $req && $req->isa('Plack::Request');
    eval { $self->_set_vars($req); };

    $req->env->{'tt.vars'}->{'error'}   = $error;
    $req->env->{'tt.vars'}->{'path'}    = $req->path_info;
    $req->env->{'tt.vars'}->{'request'} = $req;

    my $tpl = $self->{$code};
    my $res = $self->process_template( $tpl, $code, $req->env->{'tt.vars'} );

    unless ( ref $res ) {

        # processing error document failed: result in a 500 error
        if ( $code eq 500 ) {
            $res = [ 500, [ 'Content-Type' => $type ], [$res] ];
            $tpl = undef;
        } else {
            if ( ref $req->logger ) {
                $req->logger->( { level => 'warn', message => $res } );
            }
            ( $res, $tpl ) = $self->process_error( 500, $res, $type, $req );
        }
    }

    return wantarray ? ( $res, $tpl ) : $res;
}

sub _set_vars {
    my ( $self, $req ) = @_;
    my $env = $req->env;

    # we must not copy the vars by reference because
    # otherwise we might modify the same object
    my (%vars) = %{ $self->vars->($req) } if defined $self->vars;

    my $rv = $self->request_vars;
    unless ( exists $vars{request} ) {
        if ( $rv eq 'all' ) {
            $vars{request} = $req;
        } elsif ( ref $rv and @$rv ) {
            $vars{request} = {};
            foreach ( @{ $self->request_vars } ) {
                next unless $req->can($_);
                my $value = $req->$_;

              # request vars should also be byte strings, so we must decode it
                if ( $self->decode_request ) {
                    my $encoding = $self->decode_request;

                    if ( blessed($value) and $value->isa('Hash::MultiValue') )
                    {
                        my @values = $value->values;
                        @values = map { decode( $encoding, $_ ) } @values;
                        my $hash = Hash::MultiValue->new;
                        foreach my $key ( $value->keys ) {
                            $key = decode( $encoding, $key );
                            $hash->add( $key, shift @values );
                        }
                        $value = $hash;
                    } else {
                        $value = decode( $encoding, $value );
                    }
                }

                $vars{request}->{$_} = $value;
            }
        }
    }

    if ( $env->{'tt.vars'} ) {
        # add to existing vars
        foreach ( keys %vars ) {
            $env->{'tt.vars'}->{$_} = $vars{$_};
        }
    } else {
        $env->{'tt.vars'} = \%vars;
    }
}

# core function called once in 'call'
sub _handle_template {
    my ( $self, $env ) = @_;

    if ( not $env->{'tt.template'} ) {
        my $path = $env->{'tt.path'} || do {
           $env->{'tt.path'} = $env->{PATH_INFO} || '/';
        };

        my $path_match = $self->path || '/';
        for ($path) {
            my $matched
                = 'CODE' eq ref $path_match
                ? $path_match->($_)
                : $_ =~ $path_match;
            if (not $matched) {
                delete $env->{'tt.path'};
                return;
            }
        }

        $path .= $self->dir_index if $path =~ /\/$/;
        $path =~ s{^/}{};    # Do not want to enable absolute paths

        my $extension = $self->extension;
        if ( $extension and $path !~ /${extension}$/ ) {
            # This 404 will be catched in method call if pass_through is set
            my ($res, $tpl) = $self->process_error(
                404, 'Not found', 'text/plain', Plack::Request->new($env) );
            $env->{'tt.template'} = $tpl;
            return $res;
        }

        $env->{'tt.template'} = $path;
    } else {
        delete $env->{'tt.path'};
    }

    my ($res, $tpl);
    my $req = Plack::Request->new($env);
    eval { $self->_set_vars($req); };
    if ( $@ ) {
        my $error = "error setting template variables: $@";
        my $type = $self->content_type || $self->default_type;
        ( $res, $tpl ) = $self->process_error( 500, $error, $type, $req );
        $env->{'tt.template'} = $tpl;
    } else {
        $res = $self->process_template(
            $env->{'tt.template'}, 200, $env->{'tt.vars'} );
    }

    unless ( ref $res ) {
        my $type = $self->content_type || $self->default_type;
        if ( $res =~ /file error .+ not found/ ) {
            ( $res, $tpl ) = $self->process_error( 404, $res, $type, $req );
        } else {
            if ( ref $req->logger ) {
                $req->logger->( { level => 'warn', message => $res } );
            }
            ( $res, $tpl ) = $self->process_error( 500, $res, $type, $req );
        }
        $env->{'tt.template'} = $tpl;
    }

    return $res;
}

1;

__END__

=head1 NAME

    Plack::Middleware::TemplateToolkit - serve a pages via Template Toolkit

=head1 SYNOPSIS

    use Plack::Builder;

    my $root = '/path/to/html_doc_root';

    builder {

        # Page to show when requested file is missing
        enable 'ErrorDocument',    #
            404 => "$root/page_not_found.html";

        # These files can be served directly
        enable 'Static',
            path => qr{\.(gif|png|jpg|swf|ico|mov|mp3|pdf|js|css)$},
            root => $root;

        enable 'TemplateToolkit',
            INCLUDE_PATH => $root,    # required
            pass_through => 1;        # delegate missing templates to $app

        $app;
    }

A minimal L<.psgi|PSGI> script as stand-alone application:

    use Plack::Middleware::TemplateToolkit;
    Plack::Middleware::TemplateToolkit->new( INCLUDE_PATH => "/path/to/docs" );

=head1 DESCRIPTION

Enable this middleware or application to allow your Plack-based application to
serve files processed through L<Template Toolkit|Template> (TT). The idea
behind this module is to provide content that is ALMOST static, but where
having the power of TT can make the content easier to manage. You probably
only want to use this for the simplest of sites, but it should be easy
enough to migrate to something more significant later.

As L<Plack::Middleware> derives from L<Plack::Component> you can also use
this as simple application. If you just want to serve files via Template
Toolkit, treat this module as if it was called Plack::App::TemplateToolkit.

You can mix this middleware with other Plack::App applications and
Plack::Middleware which you will find on CPAN.

This middleware reads and sets the PSGI environment variable C<tt.vars> for
variables passed to templates. By default, the QUERY_STRING params are
available to the templates, but the more you use these the harder it could be
to migrate later so you might want to look at a propper framework such as
L<Catalyst> if you do want to use them:

  [% params.get('field') %] params is a L<Hash::MultiValue>
  [% request.parameters.field %] configured with request_vars => ['parameters']

A full example application is included in this module in the exmple directory.

=head1 CONFIGURATIONS

You can use all configuration options that are supported by Template Toolkit
(INCLUDE_PATH, INTERPOLATE, POST_COMP...). See L<Template::Manual::Config> for
an overview. The only mandatory option is INCLUDE_PATH to point to where the
templates live.

=over 4

=item path

Specifies an URL pattern or a callback to match with requests to serve
templates for.  See L<Plack::Middleware::Static> for further description.
Unlike Plack::Middleware::Static this middleware uses C<'/'> as default path.
You may also consider using L<Plack::App::URLMap> and the C<mount> syntax from
L<Plack::Builder> to map requests based on a path to this middleware.

=item extension

Limit to only files with this extension. Requests for other files within
C<path> will result in a 404 response or be passed to the next application if
C<pass_through> is set.

=item content_type

Specify the Content-Type header you want returned. If not specified, the
content type will be guessed by L<Plack::MIME> based on the file extension
with C<default_type> as default.

=item default_type

Specify the default Content-Type header. Defaults to to C<text/html>.

=item dir_index

Which file to use as a directory index, defaults to C<index.html>.

=item vars

Specify a hash reference with template variables or a code reference that
gets a L<Plack::Request> objects and returns a hash reference with template
variables. By default only the QUERY_STRING params are provided as 'params'.
Templates variables specified by this option are added to existing template
variables in the tt.vars environment variable.

=item request_vars

Specify a list of request variables from L<Plack::Request> to be collected in a
template variable 'request'. For instance C< ['path','base'] > gives you the
template variables C<request.path> and C<request.base>. Setting this parameter
to 'all' gives you the original Plack::Request object, but this is unstable,
bad practice because the object may change and your templates may damage the
request object.

By default the request variables are decoded from byte strings to Unicode.
You can change this with the configuration value C<decode_request>.

=item pass_through

If this option is enabled, requests are passed back to the application, if
the incoming request path matches with the C<path> but the requested template
file is not found. Disabled by default, so all matching requests result in
a valid response with status code 200, 404, or 500.

=item tt

Directly set an instance of L<Template> instead of creating a new one:

  Plack::Middleware::TemplateToolkit->new( %tt_options );

  # is equivalent to:

  my $tt = Template->new( %tt_options );
  Plack::Middleware::TemplateToolkit->new( tt => $tt );

=item encode_response

If your templates or template variables are Unicode strings, the output must be
encoded, because PSGI expects the content body to be a byte stream. You can
specify an encoding, such as C<utf8> with this parameter, so the output is
encoded to a byte string. The default setting is C<utf8> which encodes to UTF-8
bytes.  This default option is useful if your input contains non-ASCII
characters, but it may lead to double encoded UTF-8 bytes, if you accidently
mix strings with UTF-8 flag and without.  To find such implicit encoding
conversions, try L<encoding::warnings>.

=item decode_request

Similar to C<encode_response>, this parameter decodes the input request from a
byte string to an encoding of your choice. Set to C<utf8> by default.

It is highly recommended to use L<Plack::Middleware::Lint> and test your app
with Unicode from several sources (templates, variables, parameters, ...).

=item timer

Time the processing and add C<tt.start>, C<tt.end>, and C<tt.elapsed> to the
environment.

=item 404 and 500

Specifies an error template that is processed when a file was not found (404)
or on server error (500). The template variables C<error> with an error message,
C<path> with the request path, and C<request> with the request objects are set
for processing. If an error template count not be found and processed, another
error with status code 500 is returned, possibly also as template.

=back

=head1 ENVIRONMENT

This middleware inspects and/or manipulates the following variables from
the PSGI environment:

=over 4

=item tt.vars

Injected as template variables if defined. Set to the template variables.

=item tt.path

Set to the template that was asked to process. This is equal to the local path
(C<path_info> in L<Plack::Request>) if the request matched. If this variable is
set I<before> the middleware is called, it uses its value instead of path_info.

=item tt.template

Set to the template that has actually been processed. If this variable is set
I<before> the middleware is called, the specified template is processed. In this
all other settings (path, extensions, dir_index, and tt.path) are ignored.

=back

You can view these variables with L<Plack::Middleware::Debug::TemplateToolkit>.

=head1 METHODS

In addition to the call() method derived from L<Plack::Middleware>, this
class defines the following methods for internal use.

=head2 process_template ( $template, $code, \%vars )

Calls the process() method of L<Template> and returns the output in a PSGI
response object on success. The first parameter indicates the input template's
file name. The second parameter is the HTTP status code to return on success.
A reference to a hash with template variables may be passed as third parameter.
On failure this method returns an error message instead of a reference.

=head2 process_error ( $code, $error, $type, $req ) = @_;

Returns a PSGI response to be used as error message. Error templates are used
if they have been specified and prepare_app has been called before. This method
tries hard not to fail: undefined parameters are replaced by default values.
In list context this returns a PSGI response and the actual template that has
been used to create the error document.

=head1 SEE ALSO

L<Plack>, L<Template>, L<Plack::Middleware::Debug::TemplateToolkit>

=head1 AUTHORS

Leo Lapworth (started) and Jakob Voss (most of the work!)

=cut
