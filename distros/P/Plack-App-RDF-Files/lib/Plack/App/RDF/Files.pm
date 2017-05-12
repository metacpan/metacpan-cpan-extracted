package Plack::App::RDF::Files;
use strict;
use warnings;
use v5.10;

use parent 'Plack::Component';
use Plack::Util;
use Plack::Request;
use Plack::Middleware::ConditionalGET;
use Plack::Util;
use RDF::Trine qw(statement iri);
use File::Spec::Functions qw(catfile catdir);
use URI;
use Scalar::Util qw(blessed reftype);
use Carp qw(croak);
use Digest::MD5;
use HTTP::Date;
use List::Util qw(max);
use Encode qw(is_utf8 encode_utf8); 
use Moo;

our $VERSION = '0.12';

our %FORMATS = (
    ttl     => 'Turtle',
    nt      => 'NTriples',
    n3      => 'Notation3',
    json    => 'RDFJSON',
    rdfxml  => 'RDFXML'
);

has base_dir => (
    is => 'ro', required => 1,
    isa => sub { die "base_dir not found" unless -d $_[0] },
);

has base_uri => (
    is => 'ro', coerce => sub { URI->new($_[0]) },
);

has file_types => (
    is => 'ro', 
    default => sub { [qw(rdfxml nt ttl)] },
    coerce  => sub { 
        my $types = join '|', @{$_[0]}; qr/^($types)$/;
    },
);

has path_map => (
    is => 'ro', default => sub { sub { $_[0] } }
);

has index_property => (
    is => 'rw', 
    coerce => sub {
        $_[0] ? 
        iri($_[0] eq '1' ? 'http://www.w3.org/2000/01/rdf-schema#seeAlso' : $_[0])
        : undef
    },
);

has namespaces => (
    is => 'ro'
);

has normalize => (
    is => 'ro',
    coerce => sub {
        return unless $_[0];
        require Unicode::Normalize;
        $_[0] =~ /^nf(k?[dc])$/i ? uc($1) : die "unknown normalization form: $_[0]";
    }
);
  
# find out which URI to retrieve for
sub _uri {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    if (!$env->{'rdf.uri'}) {
        $env->{'rdf.uri'} = URI->new(
            ($self->base_uri // $req->base) . $self->_path($env)
        );
    } elsif (!ref $env->{'rdf.uri'}) {
        $env->{'rdf.uri'} = URI->new( $env->{'rdf.uri'} );
    }
    $env->{'rdf.uri'};
}

sub _path {
    my ($self, $env) = @_;
    my $path = substr(Plack::Request->new($env)->path, 1);

    if ($path =~ /^[a-z0-9:\._@\/-]*$/i and $path !~ /\.\.\/|^\//) {
        return $path;
    } else {
        return;
    }
}

sub _dir {
    my ($self, $path) = @_;
    my $dir = catdir( $self->base_dir, $self->path_map->($path) );
    return (-d $dir ? $dir : undef);
}

sub files {
    my ($self, $env) = @_;

    my $path = $self->_path($env);
    return if !defined $path;
    return if $path eq '' and !$self->index_property;

    my $dir = $self->_dir($path);
    return unless eval { -r $dir };
    return unless opendir(my $dh, $dir);

    my $files = { };
    while ( readdir $dh ) {
        next if $_ !~ /\.(\w+)$/;
        next if $1 !~ $self->file_types;

        my @stat = stat(catfile($dir,$_));
        $files->{$_} = {
            location => $dir,
            size     => $stat[7],
            mtime    => $stat[9],
        }
    }
    closedir $dh;

    return $files;
}

sub index_statements {
    my ($self, $req) = @_;

    my $uri       = $self->_uri($req->env);
    my $subject   = iri($uri);
    my $predicate = $self->index_property;

    my $statements = [ ];
    my $path = $self->_path($req->env);
    return [ ] if !defined $path;
    my $dir = $self->_dir($path);

    if ( opendir(my $dirhandle, $dir) ) {
        foreach my $p (readdir $dirhandle) {
            next unless -d catdir( $dir, $p ) and $p !~ /^\.\.?$/;
            push @$statements, statement(
                $subject,
                $predicate,
                RDF::Trine::Node::Resource->new( "$uri$p" )
            );
        }
        closedir $dirhandle;
    }

    return $statements;
}

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    return [405, ['Content-type' => 'text/plain', 'Allow' => 'GET,HEAD'], ['Method not allowed']]
        unless (($req->method eq 'GET') || ($req->method eq 'HEAD'));

    # find out which RDF files to retrieve
    my $files = $self->files($env);

    return [404, ['Content-type' => 'text/plain'], ['Not found']]
        unless $files;

    my $uri     = $self->_uri($env);
    my $headers = $self->headers($files);

    # negotiate serialization format
    my $serializer;
    eval {
        my %options = (
            base_url   => $env->{'rdf.uri'},
            namespaces => $self->namespaces // { },
        );
        if ( $env->{'negotiate.format'} ) {
            my $format = $FORMATS{$env->{'negotiate.format'}} 
                         // $env->{'negotiate.format'};
            $serializer = RDF::Trine::Serializer->new($format, %options);
        } else {
            my $type;
            ($type, $serializer) = RDF::Trine::Serializer->negotiate(
                request_headers => $req->headers, %options );
            $headers->set('Content-type' => $type);
            $headers->set( Vary => 'Accept');
        }
    };
    if ($@ or !$serializer) { # RDF::Trine::Error::SerializationError
        $serializer = RDF::Trine::Serializer->new('NTriples', base_uri => $uri);
        $headers->set('Content-type' => 'text/plain');
    }

    # don't bother parsing and serializing on HEAD request or conditional GET
    # (this implies these requests will not detect RDF parsing errors)
    if ( Plack::Middleware::ConditionalGET->etag_matches($headers, $env) ||
         Plack::Middleware::ConditionalGET->not_modified_since($headers, $env) ) {
         return [304, $headers->headers, []];
    }

    if ($req->method eq 'HEAD') {
        return [200, $headers->headers, []];
    }

    # parse RDF
    my $model = RDF::Trine::Model->new;
    my $triples = 0;
    my $add_statement = $self->normalize 
            ? sub { 
                my $s = $_[0];
                if ($s->object->is_literal) {
                    my $value = Unicode::Normalize::normalize($self->normalize, $s->object->literal_value);
                    $s->object->literal_value($value);
                }
                $model->add_statement($s); 
              } 
            : sub { 
                $model->add_statement($_[0]); 
            };

    while (my ($name, $file) = each %$files) {
        my $fullname = catdir($file->{location},$name);
        my $parser = RDF::Trine::Parser->guess_parser_by_filename( $fullname );
        $parser = $parser->new unless ref $parser;
        eval { # parse file into model
            $model->begin_bulk_ops;
            $parser->parse_file( $uri, $fullname, $add_statement );
            $model->end_bulk_ops();
        };
        if ($@) {
            $file->{error} = $@;
        } else {
            $file->{triples} = $model->size - $triples;
            $triples = $model->size;
        }
    }
    $env->{'rdf.files'} = $files;

    my $iterator = $model->as_stream;

    # add listing on base URI
    if ( $self->index_property and "$uri" eq ($self->base_uri // $req->base) ) {
        my $stms = $self->index_statements($req);
        if (@$stms) {
            $iterator = $iterator->concat( RDF::Trine::Iterator::Graph->new( $stms ) );
        }
    }

    # add axiomatic triple to empty graphs
    if ($iterator->finished) {
        $iterator = RDF::Trine::Iterator::Graph->new( [ statement(
            iri($uri),
            iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            iri('http://www.w3.org/2000/01/rdf-schema#Resource')
        ) ] );
    }

    # construct PSGI response
    if ( $env->{'psgi.streaming'} ) {
        $env->{'rdf.iterator'} = $iterator;
        return sub {
            my $responder = shift;
            my $body = $self->_serialize_body( $serializer, $iterator );       
            $responder->( [ 200, $headers->headers, $body ] );
        };
    } else {
        my $body = $self->_serialize_body( $serializer, $iterator );
        return [ 200, $headers->headers, $body ];
    }
}

sub _serialize_body {
    my ($self, $serializer, $iterator) = @_;

    # serialize as last as possible
    return Plack::Util::inline_object(
        getline => sub {
            return if !$iterator or $iterator->finished;

            my $string  = '';
            open ( my $fh, '>:encoding(UTF-8)', \$string );
            $serializer->serialize_iterator_to_file($fh, $iterator);
            close $fh;
            $iterator = 0;

            return $string;
        },
        close => sub { $iterator = 0 },
    );
}

sub headers {
    my ($self, $files) = @_;

    # calculate Etag based on file names, locations, sizes, and mtimes
    my $md5 = Digest::MD5->new;
    foreach my $name (sort keys %$files) {
        $md5->add( map { $files->{$name}->{$_} } sort keys %{$files->{$name}} );
    }

    # get last modification time
    my $lastmod = max map { $_->{mtime} } values %$files;

    Plack::Util::headers([
        'ETag' => 'W/"'.$md5->hexdigest.'"',
        'Last-Modified' => HTTP::Date::time2str($lastmod)
    ]);
}

use parent 'Exporter';
our @EXPORT_OK = qw(app);
sub app { Plack::App::RDF::Files->new(@_) }
 
1;
__END__

=head1 NAME
 
Plack::App::RDF::Files - serve RDF data from files

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/nichtich/Plack-App-RDF-Files.png)](https://travis-ci.org/nichtich/Plack-App-RDF-Files)
[![Coverage Status](https://coveralls.io/repos/nichtich/Plack-App-RDF-Files/badge.png)](https://coveralls.io/r/nichtich/Plack-App-RDF-Files)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Plack-App-RDF-Files.png)](http://cpants.cpanauthors.org/dist/Plack-App-RDF-Files)

=end markdown

=head1 SYNOPSIS

Create and run a Linked Open Data server in one line:

    plackup -e 'use Plack::App::RDF::Files "app"; app(base_dir=>"/path/to/rdf")'

In more detail, create a file C<app.psgi>:

    use Plack::App::RDF::Files;
    Plack::App::RDF::Files->new(
        base_dir => '/path/to/rdf/',       # mandatory
        base_uri => 'http://example.org/'  # optional
    )->to_app;

Run it as web application by calling C<plackup>. Request URLs are then mapped
to URIs and directories to return data from RDF files as following:

    http://localhost:5000/foo  =>  http://example.org/foo
                                         /path/to/rdf/foo/
                                         /path/to/rdf/foo/*.(nt|ttl|rdfxml)
    http://localhost:5000/x/y  =>  http://example.org/x/y
                                         /path/to/rdf/x/y/
                                         /path/to/rdf/x/y/*.(nt|ttl|rdfxml)

In short, each subdirectory corresponds to an RDF resource.

=head1 DESCRIPTION

This L<PSGI> application serves RDF from files. Each accessible RDF resource
corresponds to a (sub)directory, located in a common based directory. All RDF
files in a directory are merged and returned as RDF graph. If no RDF data was
found in an existing subdirectory, an axiomatic triple is returned:

    $REQUEST_URI <a <http://www.w3.org/2000/01/rdf-schema#Resource> .

Requesting the base directory, however will result in a HTTP 404 error unless
option C<index_property> is enabled.

HTTP HEAD and conditional GET requests are supported by ETag and
Last-Modified-Headers (see L<Plack::Middleware::ConditionalGET>).

=head1 CONFIGURATION

=over 4

=item base_dir

Mandatory base directory that all resource directories are located in.

=item base_uri

The base URI of all resources. If no base URI has been specified, the
base URI is taken from the PSGI request.

=item file_types

An array of RDF file types, given as extensions to look for. Set to
C<['rdfxml','nt','ttl']> by default.

=item index_property

By default a HTTP 404 error is returned if one tries to access the base
directory. Enable this option by setting it to 1 or to an URI, to also serve
RDF data from the base directory.  By default
C<http://www.w3.org/2000/01/rdf-schema#seeAlso> is used as index property, if
enabled.

=item path_map

Optional code reference that maps a local part of an URI to a relative
directory. Set to the identity mapping by default.

=item namespaces

Optional namespaces for serialization, passed to L<RDF::Trine::Serializer>.

=item normalize

Optional Unicode Normalization form (NFD, NFKC, NFC, NFKC). Requires
L<Unicode::Normalize>.

=back

=head1 METHODS

=head2 call( $env )

Core method of the PSGI application.

The following PSGI environment variables are read and/or set by the
application.

=over 4

=item rdf.uri

The requested URI as string or L<URI> object.

=item rdf.iterator

The L<RDF::Trine::Iterator> that will be used for serializing, if
C<psgi.streaming> is set. One can use this variable to catch the RDF
data in another post-processing middleware.

=item rdf.files

An hash of source filenames, each with the number of triples (on success)
as property C<size>, an error message as C<error> if parsing failed, and
the timestamp of last modification as C<mtime>. C<size> and C<error> may
not be given before parsing, if C<rdf.iterator> is set.

=item negotiate.format

RDF serialization format (See L<Plack::Middleware::Negotiate>). Supported
values are C<ttl>, C<nt>, C<n3>, C<json>, and C<rdfxml>.

=back

If an existing resource does not contain triples, the axiomatic triple
C<< $uri rdf:type rdfs:Resource >> is returned.

=head2 files( $env )

Get a list of RDF files (as hash reference) that will be read for a given
request, given as L<PSGI> environment.

The requested URI is saved in field C<rdf.uri> of the request environment.  On
success returns the base directory and a list of files, each mapped to its last
modification time.  Undef is returned if the request contained invalid
characters (everything but C<a-zA-Z0-9:.@/-> and the forbidden sequence C<../>
or a sequence starting with C</>), or if called with the base URI and
C<index_property> not enabled.

=head2 headers( $files ) 

Get a response headers object (as provided by L<Plack::Util>::headers) with
ETag and Last-Modified from a list of RDF files given as returned by the files
method.

=head1 FUNCTIONS

=head2 app( %options )

This shortcut for C<< Plack::App::RDF::Files->new >> can be exported on request
to simplify one-liners.

=head1 SEE ALSO

Use L<Plack::Middleware::Negotiate> to add content negotiation based on
an URL parameter and/or suffix.

See L<RDF::LinkedData> for a different module to serve RDF as linked data.
See also L<RDF::Flow> and L<RDF::Lazy> for processing RDF data.

See L<http://foafpress.org/> for a similar approach in PHP.

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
