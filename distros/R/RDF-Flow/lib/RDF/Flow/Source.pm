use strict;
use warnings;
package RDF::Flow::Source;
{
  $RDF::Flow::Source::VERSION = '0.178';
}
#ABSTRACT: Source of RDF data

use Log::Contextual::WarnLogger;
use Log::Contextual qw(:log), -default_logger
    => Log::Contextual::WarnLogger->new({ env_prefix => __PACKAGE__ });

use 5.010;
use re qw(is_regexp);

use RDF::Trine qw(iri);
use Scalar::Util qw(blessed refaddr reftype);
use Try::Tiny;
use Carp;

use URI;
use URI::Escape;
use File::Spec::Functions;

use parent 'Exporter';
our @EXPORT_OK = qw(sourcelist_args iterator_to_model empty_rdf rdflow_uri);
our %EXPORT_TAGS = (
    util => [qw(sourcelist_args iterator_to_model empty_rdf rdflow_uri)],
);

use RDF::Trine::Model;
use RDF::Trine::Parser;

#require RDF::Flow::Pipeline;

sub new {
    my $class = shift;
    my ($src, %args) = ref($_[0]) ?  @_ : (undef,@_);

    $src = delete $args{from} unless defined $src;

    my $match = delete $args{match};
    my $code;

    my $self = bless { }, $class;

    if ( $src and not ref $src ) { # load from file or directory
        my $model = RDF::Trine::Model->new;
        my @files;
        if ( $src =~ /^https?:\/\// ) {
            eval { RDF::Trine::Parser->parse_url_into_model( $src, $model ); };
            goto CHECK;
        } else {
            if ( -d $src ) {
                if ( opendir(DIR, $src) ) {
                    my $ext = join ('|', keys %RDF::Trine::Parser::file_extensions);
                    @files = map { catfile($src,$_) } grep(/\.($ext)$/,readdir(DIR));
                    closedir DIR;
                } else {
                    log_warn { "failed to open directory $src"; }
                }
            } else {
                @files = ($src);
            }
        }

        while ($src = shift @files) {
            eval { RDF::Trine::Parser->parse_file_into_model( "file:///$src", $src, $model ); };

            CHECK: # yes, it's an evil goto statement jump target :-)
            if ( @_ ) {
                log_warn { "failed to load from $src"; }
            } else {
                log_info { "loaded from $src"; }
            }
        }

        $src = $model;
    }

    if (blessed $src and $src->isa('RDF::Flow::Source')) {
        $self->{from} = $src;
        $code = sub {
            $src->retrieve( @_ );
        };
        # return $src; # don't wrap
        # TODO: use args to modify object!
    } elsif ( blessed $src and $src->isa('RDF::Trine::Model') ) {
        $self->{from} = $src;
        $code = sub {
            my $uri = rdflow_uri( shift );
            iterator_to_model( $src->bounded_description(
                iri( $uri )
            ) );
        };
    } elsif ( ref $src and ref $src eq 'CODE' ) {
        $code = $src;
    } elsif (not defined $src) {
        carp 'Missing RDF source in plain RDF::Flow::Source'
            if $class eq 'RDF::Flow::Source';
        $code = sub { };
    } else {
        croak 'expected RDF::Source, RDF::Trine::Model, or code reference'
    }

    $self->{name} = $args{name} if defined $args{name};
    $self->{code} = $code;

    $self->match( $match );

    $self->init();

    $self;
}

sub init { }

sub match { # accessor
    my $self = shift;
    return $self->{match} unless @_;

    my $match = shift;
    if ( defined $match ) {
        my $pattern = $match;
        $match = sub { $_[0] =~ $pattern; }
            if is_regexp($match);
        croak 'url parameter must be code or regexp'.reftype($match). ": $match"
            if reftype $match ne 'CODE';
        $self->{match} = $match;
    } else {
        $self->{match} = undef;
    }
}

sub retrieve {
    my ($self, $env) = @_;
    $env = { 'rdflow.uri' => $env } if ($env and not ref $env);
    log_trace {
        sprintf "retrieve from %s with %s", about($self), rdflow_uri($env);
    };
    $self->timestamp( $env );

    my $result;
    if ( $self->{match} ) {
        my $uri = $env->{'rdflow.uri'};
        if ( $self->{match}->( $env->{'rdflow.uri'} ) ) {
            $result = $self->retrieve_rdf( $env );
            $env->{'rdflow.uri'} = $uri;
        } else {
            log_trace { "URI did not match: " . $env->{'rdflow.uri'} };
            $result = RDF::Trine::Model->new;
        }
    } else {
        $result = $self->retrieve_rdf( $env );
    }

    return $self->trigger_retrieved( $result );
}

sub retrieve_rdf {
    my ($self, $env) = @_;
    return try {
        $self->{code}->( $env );
    } catch {
        s/[.]?\s+$//s;
        RDF::Flow::Source::trigger_error( $self, $_, $env );
        RDF::Trine::Model->new;
    }
}

sub trigger_error {
    my ($self, $message, $env) = @_;
    $message = 'unknown error' unless $message;
    $env->{'rdflow.error'} = $message if $env;
    log_error { $message };
}

sub trigger_retrieved {
    my ($self, $result, $msg) = @_;
    log_trace {
        $msg = "%s returned %s" unless $msg;
        my $size = 'no';
        if ( $result ) {
            $size = (blessed $result and $result->can('size'))
                ? $result->size : 'some';
        };
        sprintf $msg, name($self), "$size triples";
    };
    return $result;
}

sub id {
    return "source".refaddr(shift);
}


sub graphviz {
    return scalar shift->graphviz_addnode( @_ );
}

sub graphviz_addnode {
    my $self = shift;
    my $g = ( blessed $_[0] and $_[0]->isa('GraphViz') )
            ? shift : eval { GraphViz->new( @_ ) };
    return unless $g;

    $g->add_node( $self->id, $self->_graphviz_nodeattr );

    my $i=1;
    foreach my $s ( $self->inputs ) {
        $s->graphviz($g);
        $g->add_edge( $s->id, $self->id, $self->_graphviz_edgeattr($i++) );
    }

    return $g;
}

sub _graphviz_nodeattr {
    return (label => shift->name);
}

sub _graphviz_edgeattr { }

use POSIX qw(strftime);

sub timestamp {
    my ($self, $env) = @_;
    my $now = time();
    my $tz = strftime("%z", localtime($now));
    $tz =~ s/(\d{2})(\d{2})/$1:$2/;
    $tz =~ s/00:00/Z/; # UTC aka Z-Time
    my $timestamp = strftime("%Y-%m-%dT%H:%M:%S", localtime($now)) . $tz;
    $env->{'rdflow.timestamp'} = $timestamp if $env;
    return $timestamp;
}

sub name {
    shift->{name} || 'anonymous source';
}

sub about {
    shift->name;
}

sub inputs {
    my $self = shift;
    return $self->{inputs} ? @{ $self->{inputs} } : ();
}

sub size {
    my $self = shift;
    return 1 unless $self->{inputs};
    return scalar @{ $self->{inputs} };
}

sub sourcelist_args {
    my ($inputs, $args) = ([],{});
    while ( @_ ) {
        my $s = shift @_;
        if ( ref $s ) {
            push @$inputs, map { RDF::Flow::Source->new($_) } $s;
        } elsif ( defined $s ) {
            $args->{$s} = shift @_;
        } else {
            croak 'undefined parameter';
        }
    }
    return ($inputs, $args);
}

sub iterator_to_model {
    my $iterator = shift;
    return $iterator if $iterator->isa('RDF::Trine::Model');

    my $model = shift || RDF::Trine::Model->new;

    $model->begin_bulk_ops;
    while (my $st = $iterator->next) {
        $model->add_statement( $st );
    }
    $model->end_bulk_ops;

    $model;
}

sub empty_rdf {
    my $rdf = shift;
    return 1 unless blessed $rdf;
   	return !($rdf->isa('RDF::Trine::Model') and $rdf->size > 0) &&
           !($rdf->isa('RDF::Trine::Iterator') and $rdf->peek);
}

sub rdflow_uri {
    my $env = shift;
    return ($env || '') unless ref $env; # plain scalar or undef

    return $env->{'rdflow.uri'} if defined $env->{'rdflow.uri'};

    # a few lines of code from Plack::Request, so we don't require all of Plack
    my $base = ($env->{'psgi.url_scheme'} || "http") .
        "://" . ($env->{HTTP_HOST} || (($env->{SERVER_NAME} || "") .
        ":" . ($env->{SERVER_PORT} || 80))) . ($env->{SCRIPT_NAME} || '/');
    $base = URI->new($base)->canonical;

    my $path_escape_class = '^A-Za-z0-9\-\._~/';

    my $path = URI::Escape::uri_escape( $env->{PATH_INFO} || '', $path_escape_class );

    $path .= '?' . $env->{QUERY_STRING} if !$env->{'rdflow.ignorepath'} &&
        defined $env->{QUERY_STRING} && $env->{QUERY_STRING} ne '';

    $base =~ s!/$!! if $path =~ m!^/!;

    $env->{'rdflow.uri'} = URI->new( $base . $path )->canonical->as_string;

    $env->{'rdflow.uri'} =~ s/^https?:\/\/\/$//;
    $env->{'rdflow.uri'};
}

# put at the end to prevent circular references in require
require RDF::Flow::Pipeline;

sub pipe_to {
   my ($self, $next) = @_;
   return RDF::Flow::Pipeline->new( $self, $next );
}

1;


__END__
=pod

=head1 NAME

RDF::Flow::Source - Source of RDF data

=head1 VERSION

version 0.178

=head1 SYNOPSIS

    $src = rdflow( "mydata.ttl", name => "RDF file as source" );
    $src = rdflow( "mydirectory", name => "directory with RDF files as source" );
    $src = rdflow( \&mysource, name => "code reference as source" );
    $src = rdflow( $model, name => "RDF::Trine::Model as source" );

    package MySource;
    use parent 'RDF::Flow::Source';

    sub retrieve_rdf {
        my ($self, $env) = @_;
        my $uri = $env->{'rdflow.uri'};

        # ... your logic here ...

        return $model;
    }

=head1 DESCRIPTION

Each RDF::Flow::Source provides a C<retrieve> method, which returns RDF data on
request. RDF data is always returned as instance of L<RDF::Trine::Model> or as
instance of L<RDF::Trine::Iterator> with simple statements. The
L<request format|/REQUEST FORMAT> is specified below. Sources can access RDF
for instance parsed from a file or multiple files in a directory, via HTTP,
from a L<RDF::Trine::Store>, or from a custom method. All sources share a set
of common configurations options.

=head1 METHODS

=head2 new ( $from {, %configuration } )

Create a new RDF source by wrapping a code reference, a L<RDF::Trine::Model>,
or loading RDF data from a file or URL.

If you pass an existing RDF::Flow::Source object, it will not be wrapped.

A source returns RDF data as instance of L<RDF::Trine::Model> or
L<RDF::Trine::Iterator> when queried by a L<PSGI> requests. This is
similar to PSGI applications, which return HTTP responses instead of
RDF data. RDF::Light supports three types of sources: code references,
instances of RDF::Flow, and instances of RDF::Trine::Model.

This constructor is exported as function C<rdflow> by L<RDF::Flow>:

  use RDF::Flow qw(rdflow);

  $src = rdflow( @args );               # short form
  $src = RDF:Source->new( @args );      # explicit constructor

=head2 init

Called from the constructor. Can be used in your sources.

=head2 retrieve

Retrieve RDF data. Always returns an instance of L<RDF::Trine::Model> or
L<RDF::Trine::Iterator>. You can use the method L</empty_rdf> to check
whether the RDF data contains some triples or not.

=head2 retrieve_rdf

Internal method to retrieve RDF data. You should define this when
L<subclassing RDF::Flow::Source|RDF::Flow/DEFINING NEW SOURCE TYPES>, it
is called by method C<retrieve>.

=head2 trigger_retrieved ( $source, $result [, $message ] )

Creates a logging event at trace level to log that some result has been
retrieved from a source. Returns the result. By default the logging messages is
constructed from the source's name and the result's size. This function is
automatically called at the end of method C<retrieve>, so you do not have to
call it, if your source only implements the method C<retrieve_rdf>.

=head2 name

Returns the name of the source.

=head2 about

Returns a string with short information (name and size) of the source.

=head2 size

Returns the number of inputs (for multi-part sources, such as
L<RDF::Flow::Source::Union>).

=head2 inputs

Returns a list of inputs (unstable).

=head2 id

Returns a unique id of the source, based on its memory address.

=head2 pipe_to

Pipes the source to another source (L<RDF::Flow::Pipeline>).
C<< $a->pipe_to($b) >> is equivalent to C<< RDF::Flow::Pipeline->new($a,$b) >>.

=head2 timestamp

Returns an ISO 8601 timestamp and possibly sets in
C<rdflow.timestamp> environment variable.

=head2 trigger_error

Triggers an error and possibly sets the C<rdflow.error> environment variable.

=head2 graphviz

Purely experimental method for visualizing nets of sources.

=head2 graphviz_addnode

Purely experimental method for visualizing nets of sources.

=head1 CONFIGURATION

=over 4

=item name

Name of the source. Defaults to "anonymous source".

=item from

Filename, URL, directory, L<RDF::Trine::Model> or code reference to retrieve
RDF from. This option is not supported by all source types.

=item match

Optional regular expression or code reference to match and/or map request URIs.
For instance you can rewrite URNs to HTTP URIs like this:

    match => sub { $_[0] =~ s/^urn:isbn:/http://example.org/isbn/; }

The URI in C<rdflow.uri> is set back to its original value after retrieval.

=back

=head1 REQUEST FORMAT

A valid request can either by an URI (as byte string) or a hash reference, that
is called an environment. The environment must be a specific subset of a
L<PSGI> environment with the following variables:

=over 4

=item C<rdflow.uri>

A request URI as byte string. If this variable is provided, no other variables
are needed and the following variables will not modify this value.

=item C<psgi.url_scheme>

A string C<http> (assumed if not set) or C<https>.

=item C<HTTP_HOST>

The base URL of the host for constructing an URI. This or SERVER_NAME is
required unless rdflow.uri is set.

=item C<SERVER_NAME>

Name of the host for construction an URI. Only used if HTTP_HOST is not set.

=item C<SERVER_PORT>

Port of the host for constructing an URI. By default C<80> is used, but not
kept as part of an HTTP-URI due to URI normalization.

=item C<SCRIPT_NAME>

Path for constructing an URI. Must start with C</> if given.

=item C<QUERY_STRING>

Portion of the request URI that follows the ?, if any.

=item C<rdflow.ignorepath>

If this variable is set, no query part is used when constructing an URI.

=back

The method reuses code from L<Plack::Request> by Tatsuhiko Miyagawa. Note that
the environment variable REQUEST_URI is not included. When this method
constructs a request URI from a given environment hash, it always sets the
variable C<rdflow.uri>, so it is always guaranteed to be set after calling.
However it may be the empty string, if an environment without HTTP_HOST or
SERVER_NAME was provided.

=head1 FUNCTIONS

The following functions are defined to be used in custom source types.

=head2 rdflow_uri ( $env | $uri )

Prepares and returns a request URI, as given by an evironment hash or by an
existing URI. Sets C<rdflow.uri> if an environment has been given. URI
construction is based on code from L<Plack>, as described in the L</REQUEST
FORMAT>. The following environment variables are used: C<psgi.url_scheme>,
C<HTTP_HOST> or C<SERVER_NAME>, C<SERVER_PORT>, C<SCRIPT_NAME>, C<PATH_INFO>,
C<QUERY_STRING>, and C<rdflow.ignorepath>.

=head2 sourcelist_args ( @_ )

Parses a list of inputs (code or other references) mixed with key-value pairs
and returns both separated in an array and and hash.

=head2 iterator_to_model ( [ $iterator ] [, $model ] )

Adds all statements from a L<RDF::Trine::Iterator> to a (possibly new)
L<RDF::Trine::Model> model and returns the model.

=head2 empty_rdf ( $rdf )

Returns true if the argument is an empty L<RDF::Trine::Model>, an
empty L<RDF::Trine::Iterator>, or no RDF data at all.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

