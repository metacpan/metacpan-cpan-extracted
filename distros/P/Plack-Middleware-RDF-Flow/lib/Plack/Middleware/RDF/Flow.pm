use strict;
use warnings;
package Plack::Middleware::RDF::Flow;
BEGIN {
  $Plack::Middleware::RDF::Flow::VERSION = '0.171';
}
#ABSTRACT: Serve RDF as Linked Data for RDF::Flow

use Log::Contextual::WarnLogger;
use Log::Contextual qw(:log), -default_logger
    => Log::Contextual::WarnLogger->new({ env_prefix => 'PLACK_MIDDLEWARE_RDF_FLOW' });

use Try::Tiny;
use Scalar::Util qw(blessed);
use Plack::Request;
use RDF::Trine qw(0.135 iri statement);
use RDF::Trine::Serializer;
use RDF::Trine::NamespaceMap;
use RDF::Flow qw(0.175 rdflow rdflow_uri);
use Encode;
use Carp;

use parent 'Exporter', 'Plack::Middleware';

use Plack::Util::Accessor qw(
    source base formats via_param via_extension
    namespaces pass_through empty_base rewrite);

our @EXPORT_OK = qw(guess_serialization);

our %rdf_formats = (
    nt     => 'ntriples',
    rdf    => 'rdfxml',
    xml    => 'rdfxml',
    rdfxml => 'rdfxml',
    json   => 'rdfjson',
    ttl    => 'turtle'
);

sub prepare_app {
    my $self = shift;

    $self->formats( \%rdf_formats ) unless $self->formats;

    # TODO: support array ref and custom serialization formats
    ref $self->formats eq 'HASH'
        or carp 'formats must be a hash reference';

    $self->source( rdflow( $self->source || sub { } ) );

    $self->via_param(1) unless defined $self->via_param;

    $self->namespaces( RDF::Trine::NamespaceMap->new )
        unless $self->namespaces;
}

sub call {
    my $self = shift;
    my $env = shift;

    my $app = $self->app;
    my $req = Plack::Request->new( $env );

    my ($type, $serializer) = $self->guess_serialization( $env );

    unless ( defined $env->{'rdflow.uri'} ) {
        my $req = Plack::Request->new( $env );

        my $base = defined $self->base ? $self->base : $req->base;

        my $path = $req->path;
        $path =~ s/^\///;
        my $uri = $base.$path;
        # $env->{'rdflow.ignorepath'} = 1;

        # TODO: more rewriting based on Plack::App::URLMap ?
        if ($self->{rewrite}) {
            my $saved = $uri;
            for ($uri) {
                my $res = $self->{rewrite}->();
                $uri = $saved unless $res;
            }
        }

        $env->{'rdflow.uri'} = $uri;
    }

    if ( $type ) {
        $env->{'rdflow.type'}       = $type;
        $env->{'rdflow.serializer'} = $serializer;

        my $rdf = $self->_retrieve( $env );

        if ( $env->{'rdflow.error'} ) {
            return [ 500, [ 'Content-Type' => 'text/plain' ], [ $env->{'rdflow.error'} ] ];
        }

        my $rdf_data;

        if ( UNIVERSAL::isa( $rdf, 'RDF::Trine::Model' ) ) {
            $rdf_data = $serializer->serialize_model_to_string( $rdf );
        } elsif ( UNIVERSAL::isa( $rdf, 'RDF::Trine::Iterator' ) ) {
            $rdf_data = $serializer->serialize_iterator_to_string( $rdf );
        }

        if ( $rdf_data ) {
            $rdf_data = encode('utf8',$rdf_data);
            return [ 200, [ 'Content-Type' => $type ], [ $rdf_data ] ];
        }
    } elsif ( $self->pass_through ) {
        my $rdf = $self->_retrieve( $env );
        $env->{'rdflow.data'} = $rdf;
    }

    # pass through if no/unknown serializer or empty source (URI not found) or error
    if ( $app ) {
        return $app->( $env );
    } else {
        return [ 404, [ 'Content-Type' => 'text/plain' ], [ 'Not found' ] ];
    }
}


sub _retrieve {
    my ($self,$env) = @_;

    rdflow_uri( $env );

    if (!$self->empty_base and $env->{'rdflow.uri'} eq ($self->base||'')) {
        log_trace { "empty base" };
        return RDF::Trine::Model->new;
    }

    log_trace { 'Retrieve from source' };
    my $rdf = $self->source->retrieve( $env );

    return $rdf;
}

sub guess_serialization {
    my $env = shift;
    my ($self, $possible_formats);

    if (blessed $env and $env->isa('Plack::Middleware::RDF::Flow')) {
        ($self, $env) = ($env, shift);
        $possible_formats = $self->formats;
    } else {
        $possible_formats = \%rdf_formats;
    }

    # TODO: check $env{rdflow.type} / $env{rdflow.serializer}

    my $accept = $env->{HTTP_ACCEPT} || '';
    my $req    = Plack::Request->new( $env );
    my $format;

    if ($self->via_param and $req->param('format')) {
        $format = $req->param('format');
    } elsif ($self->via_extension) {
        my $path = $env->{PATH_INFO} || '';
        if ( $path =~ /^(.*)\.([^.]+)$/ and $possible_formats->{$2} ) {
            $env->{PATH_INFO} = $1;
            $format = $2;
        }
    }

    my ($type, $serializer);

    if ($format) {
        my $ser = $possible_formats->{$format};
        if ( blessed $ser and $ser->isa('RDF::Trine::Serializer') ) {
            $serializer = $ser;
        } elsif ( $ser and not ref $ser ) {
            try {
                my $namespaces = $self->namespaces;
                $serializer = RDF::Trine::Serializer->new( $ser, namespaces => $namespaces );
            }
        }
        ($type) = $serializer->media_types if $serializer;
    } else {
        ($type, $serializer) = try {
            RDF::Trine::Serializer->negotiate( request_headers => $req->headers );
            # TODO: maybe add extend => ...
        };
        if ($serializer) {
            ($type) = grep { index($accept,$_) >= 0 } $serializer->media_types;
            return unless $type; # the client must *explicitly* ask for this RDF serialization
        }
    }

    if ( $type ) {
        log_trace { "Guessed serialization $type with " . ref($serializer) };
    }

    return ($type, $serializer);
}


1;

__END__
=pod

=head1 NAME

Plack::Middleware::RDF::Flow - Serve RDF as Linked Data for RDF::Flow

=head1 VERSION

version 0.171

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Request;
    use RDF::Flow qw(rdflow_uri);

    my $model = RDF::Trine::Model->new( ... );

    my $app = sub {
        my $env = shift;
        my $uri = rdflow_uri( $env );

        [ 404, ['Content-Type'=>'text/plain'],
               ["URI $uri not found or not requested as RDF"] ];
    };

    builder {
        enable 'RDF::Flow', source => $model;
        $app;
    }

=head1 DESCRIPTION

This L<Plack::Middleware> provides a PSGI application to serve Linked Data.
An HTTP request is mapped to an URI, that is used to retrieve RDF data from
a L<RDF::Trine::Model> or L<RDF::Flow::Source>. Depending on the request and
settings, the data is either returned in a requested serialization format or
it is passed to the next PSGI application for further processing.

In detail each request is processed as following:

=over 4

=item 1

Determine query URI and serialization format (mime type) and set the request
variables C<rdflow.uri>, C<rdflow.type>, and C<rdflow.serializer>. The request
URI is either taken from C<< $env->{'rdflow.uri'} >> (if defined) or
constructed from request's base and path. Query parameters are ignored by
default.

=item 2

Retrieve data from a L<RDF::Trine::Model> or a L<RDF::Flow::Source> about the
resource identified by C<rdflow.uri>, if a serialization format was determined
or if C<pass_through> is set.

=item 3

Create and return a serialization, if a serialization format was determined.
Otherwise store the retrieved RDF data in C<rdflow.data> and pass to the next
application.

=back

=head2 CONFIGURATION

The following options can be set when creating a new object with C<new>.

=over 4

=item source

Sets a L<RDF::Trine::Model>, a code reference, or another kind of
L<RDF::Flow::Source> to retrieve RDF data from.  For testing you can use
L<RDF::Flow::Source::Dummy> which always returns a single triple.

=item base

Maps request URIs to a given URI prefix, similar to L<Plack::App::URLMap>.

For instance if you deploy you application at C<http://your.domain/> and set
base to C<http://other.domain/> then a request for C<http://your.domain/foo>
is be mapped to the URI C<http://other.domain/foo>.

=item rewrite

Code reference to rewrite the request URI.

=item pass_through

Retrieve RDF data also if no serialization format was determined. In this case
RDF data is stored in C<rdflow.data> and passed to the next layer.

=item formats

Defines supported serialization formats. You can either specify an array
reference with serializer names or a hash reference with mappings of format
names to serializer names or serializer instances. Serializer names must exist
in RDF::Trine's L<RDF::Trine::Serializer>::serializer_names and serializer
instances must be subclasses of L<RDF::Trine::Serializer>.

  Plack::Middleware::RDF::Flow->new ( formats => [qw(ntriples rdfxml turtle)] )

  # Plack::Middleware::RDF::Foo
  my $fooSerializer = Plack::Middleware::RDF->new( 'foo' );

  Plack::Middleware::RDF::Flow->new ( formats => {
      nt  => 'ntriples',
      rdf => 'rdfxml',
      xml => 'rdfxml',
      ttl => 'turtle',
      foo => $fooSerializer
  } );

By default the formats rdf, xml, and rdfxml (for L<RDF::Trine::Serializer>),
ttl (for L<RDF::Trine::Serializer::Turtle>), json (for
L<RDF::Trine::Serializer::RDFJSON>), and nt (for
L<RDF::Trine::Serializer::NTriples>) are supported.

=item via_param

Detect serialization format via 'format' parameter. For instance
C<foobar?format=ttl> will serialize URI foobar in RDF/Turtle.
This is enabled by default.

=item via_extension

Detect serialization format via "file extension". For instance
C<foobar.rdf> will serialize URI foobar in RDF/XML.
This is disabled by default.

=item extensions

Enable file extensions (not implemented yet).

    http://example.org/{id}
    http://example.org/{id}.html
    http://example.org/{id}.rdf
    http://example.org/{id}.ttl

=back

=head2 _retrieve ( $env )

Given a L<PSGI> environment, this internal (!) method queries the source(s) for
a requested URI (if given) and either returns undef or a non-empty
L<RDF::Trine::Model> or L<RDF::Trine::Iterator>. On error this method does not
die but sets the environment variable rdflow.error. Note that if there are
multiple source, there may be both an error, and a return value.

=head1 FUNCTIONS

=head2 guess_serialization ( $env )

Given a PSGI request this function checks whether an RDF serialization format
has been B<explicitly> asked for, either by HTTP content negotiation or by
format query parameter or by file extension. You can call this as method or
as function and export it on request.

=head1 LIMITATIONS

By now this package is experimental. Extensions are not supported yet. In
contrast to other Linked Data applications, URIs must not have query parts and
the distinction between information-resources and non-information resources is
disregarded (some Semantic Web evangelists may be angry about this).

=head2 SEE ALSO

For a more complete package see L<RDF::LinkedData>. You should always use
L<Plack::Test> and L<Test::RDF> to test you application.

=head2 ACKNOWLEDGEMENTS

This package is actually a very thin layer on top of existing packages such as
L<RDF::Trine>, L<Plack>, and L<Template>. Theirs authors deserve all thanks.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

