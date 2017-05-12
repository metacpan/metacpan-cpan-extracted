# vim modeline vim600: set foldmethod=marker :

package RDF::Sesame::Repository;

use strict;
use warnings;

use Carp;

our $VERSION = '0.17';

sub construct {
    my $self = shift;

    # establish some sensible defaults
    my %defaults = (
        language => 'SeRQL',
    );
    my %opts = ( %defaults, @_ );

    # validate arguments and install options
    croak "No serialization format specified" if !$opts{format};
    croak "No query specified"                if !$opts{query};

    # set up the output filehandle
    my $output_fh;
    my $output = q{};
    if ( !defined( $opts{output} ) ) {
        open($output_fh, '>', \$output);
    }
    elsif( ref($opts{output}) eq 'GLOB' ) {
        $output_fh = $opts{output};
    }
    else {
        open $output_fh, '>', $opts{output}
            or croak "construct can't open $opts{output} for writing: $!";
    }

    # construct RDF from Sesame
    my $r = $self->command(
        'evaluateGraphQuery',
        {
            serialization => $opts{format},
            queryLanguage => $opts{language},
            query         => $opts{query},
            ':content_cb' => sub { print $output_fh $_[0] },
        }
    );
    croak $r->errstr() if !$r->success();
    close $output_fh;

    return if defined $opts{output};
    return $output;
}

sub extract {
    my $self = shift;

    # establish some sensible defaults
    my %defaults = (
        compress => 'none',
        options  => [],
    );
    my %opts = ( %defaults, @_ );

    # validate arguments and install options
    croak "No serialization format specified" if !$opts{format};
    my %boolean_options;
    for my $option ( @{ $opts{options} } ) {
        $boolean_options{$option} = 'on';
    }

    # set up the output filehandle
    my $output_fh;
    my $output = q{};
    if ( !defined( $opts{output} ) ) {
        open($output_fh, '>', \$output);
    }
    elsif( ref($opts{output}) eq 'GLOB' ) {
        $output_fh = $opts{output};
    }
    else {
        open $output_fh, '>', $opts{output}
            or croak "extract can't open $opts{output} for writing: $!";
    }

    # find and initialize the 'compress' handlers
    my $handlers = ref $opts{compress}
                 ? $opts{compress}
                 : $self->_get_compress_handlers()->{ $opts{compress} }
                 ;
    my $context = $handlers->{init}->($output_fh);

    # extract RDF from Sesame
    my $r = $self->command(
        'extractRDF',
        {
            serialization => $opts{format},
            %boolean_options,
            ':content_cb' => sub {
                $handlers->{content}->($context, $output_fh, $_[0]);
            },
        }
    );
    croak $r->errstr() if !$r->success();

    $handlers->{finish}->($context, $output_fh);
    close $output_fh;

    return if defined $opts{output};
    return $output;
}

sub _get_compress_handlers {
    return {
        none => {
            init => sub { return },
            content => sub {
                my (undef, $fh, $content) = @_;
                print $fh $content;
            },
            finish => sub { return },
        },
        gz => {
            init => sub {
                my ($fh) = @_;
                require Compress::Zlib;
                binmode $fh;
                my $gz = Compress::Zlib::gzopen( $fh, 'wb' )
                    or die "gz compression cannot open filehandle: $Compress::Zlib::gzerrno";
                return $gz;    # our context object
            },
            content => sub {
                my ( $context, $fh, $content ) = @_;
                $context->gzwrite($content)
                    or die "gz compression couldn't write: $Compress::Zlib::gzerrno";
            },
            finish => sub {
                my ( $context, $fh ) = @_;
                $context->gzclose();
            },
        },
    };
}

sub query_language {
    my $self = shift;

    $self->{errstr} = ''; # assume no errors

    return $self->{lang} unless defined $_[0];

    unless( $_[0]=~/^RQL|RDQL|SeRQL$/ ) {
        $self->{errstr} = Carp::shortmess("query language must be RQL, RDQL or SeRQL");
        return $self->{lang};
    }

    my $old = $self->{lang};

    $self->{lang} = $_[0];

    return $old;
}

sub select {
    my $self = shift;
    $self->{errstr} = q{};   # assume no error

    # process the arguments
    my %defaults = (
        query    => @_ == 1 ? shift : q{},
        language => $self->query_language(),
        strip    => $self->{strip},
        format   => 'binary',
    );
    my %opts = ( %defaults, @_ );

    my $r = $self->command(
        'evaluateTableQuery',
        {
            query         => $opts{query},
            queryLanguage => $opts{language},
            resultFormat  => $opts{format},
        }
    );

    if( !$r->success() ) {
        $self->{errstr} = Carp::shortmess($r->errstr);
        return q{};
    }

    return RDF::Sesame::TableResult->new($r, strip => $opts{strip});
}

sub upload_data {
    my $self = shift;

    $self->{errstr} = '';  # assume no error

    # establish some sensible defaults
    my %defaults = (
        data   => '',
        format => 'ntriples',
        verify => 1,
    );

    # set the defaults for any option we weren't given
    my %opts;
    if( @_ == 1 ) {
        $opts{data} = shift;
    } else {
        %opts = @_;
    }
    while( my ($k,$v) = each %defaults ) {
        $opts{$k} = $v unless exists $opts{$k};
    }

    # verify the format parameter
    if( $opts{format} !~ /^rdfxml|ntriples|turtle$/ ) {
        $self->{errstr} = Carp::shortmess("Format must be rdfxml, ntriples or turtle");
        return 0;
    }

    my $params = {
        data         => $opts{data},
        dataFormat   => $opts{format},
        verifyData   => $opts{verify} ? 'on' : 'off',
        resultFormat => 'xml',
    };

    # add in the base URI if we got it
    $params->{baseURI} = $opts{base} if exists $opts{base};

    my $r = $self->command( 'uploadData', $params );

    unless( $r->success ) {
        $self->{errstr} = Carp::shortmess($r->errstr);
        return 0;
    }

    foreach ( @{$r->parsed_xml->{status}} ) {
        my $triple_count;
        if( $_->{msg} =~ /^Data is correct and contains ([\d,]+) statement/ ) {
            $triple_count = $1;
        }
        if( $_->{msg} =~ /^Processed ([\d,]+) statement/ ) {
            $triple_count = $1;
        }
        if (defined $triple_count) {
            $triple_count =~ s{,}{}xmsg;
            return $triple_count;
        }
    }

    $self->{errstr} = Carp::shortmess('Unknown error');
    return 0;
}

sub upload_uri {
    my $self = shift;

    $self->{errstr} = '';  # assume no error

    # set some sensible defaults
    my %defaults = (
        uri => '',
        format => 'rdfxml',
        verify => 1,
        server_file => 0,
    );

    # set the defaults for any option we weren't given
    my %opts;
    if( @_ == 1 ) {
        $opts{uri} = shift;
    } else {
        %opts = @_;
    }
    while( my ($k,$v) = each %defaults ) {
        $opts{$k} = $v unless exists $opts{$k};
    }

    # set the default for the base URI
    $opts{base} = $opts{uri} unless exists $opts{base};

    # validate the format option
    if( $opts{format} !~ /^rdfxml|ntriples|turtle$/ ) {
        $self->{errstr} = Carp::shortmess("Format must be rdfxml, ntriples or turtle");
        return 0;
    }

    # handle the "file:" URI scheme
    if( $opts{uri} =~ /^file:/ && !$opts{server_file} ) {
        require LWP::Simple;
        my $content = LWP::Simple::get($opts{uri});
        unless( defined $content ) {
            $self->{errstr} = Carp::shortmess("No data in $opts{uri}");
            return 0;
        }

        delete $opts{uri};
        return $self->upload_data(
            data   => $content,
            %opts
        );
    }

    my $params = {
        url          => $opts{uri},
        dataFormat   => $opts{format},
        verifyData   => $opts{verify} ? 'on' : 'off',
        resultFormat => 'xml',
        baseURI      => $opts{base},
    };

    my $r = $self->command( 'uploadURL', $params );

    unless( $r->success ) {
        $self->{errstr} = Carp::shortmess($r->errstr);
        return 0;
    }

    foreach ( @{$r->parsed_xml->{status}} ) {
        my $triple_count;
        if( $_->{msg} =~ /^Data is correct and contains ([\d,]+) statement/ ) {
            $triple_count = $1;
        }
        elsif( $_->{msg} =~ /^Processed ([\d,]+) statement/ ) {
            $triple_count = $1;
        }
        if (defined $triple_count) {
            $triple_count =~ s{,}{}xmsg;
            return $triple_count;
        }
    }

    $self->{errstr} = Carp::shortmess('Unknown error');
    return 0;
}

sub clear {
    my $self = shift;

    my $r = $self->command('clearRepository', { resultFormat => 'xml' });

    return '' unless $r->success;

    foreach ( @{ $r->parsed_xml->{status} } ) {
        if( $_->{msg} eq 'Repository cleared' ) {
            return 1;
        }
    }

    return 0;
}

sub remove {
    my $self = shift;

    # prepare the parameters for the command
    my $params = { resultFormat => 'xml' };
    $params->{subject}   = $_[0] if defined $_[0];
    $params->{predicate} = $_[1] if defined $_[1];
    $params->{object}    = $_[2] if defined $_[2];

    my $r = $self->command('removeStatements', $params);

    unless( $r->success ) {
        return 0;
    }

    foreach ( @{ $r->parsed_xml->{notification} } ) {
        if( $_->{msg} =~ /^Removed (\d+)/ ) {
            return $1;
        }
    }

    return 0;
}

sub errstr {
    my $self = shift;

    return $self->{errstr};
}

sub command {
    my $self = shift;

    $self->{conn}->command($self->{id}, $_[0], $_[1]);
}

# This method should really only be called from
# RDF::Sesame::Connection::open.
# As parameters, it takes an RDF::Sesame::Connection object and
# some named parameters
sub new {
    my $class = shift;
    my $conn  = shift;

    # prepare the options we were given
    my %opts;
    if( @_ == 1 ) {
        $opts{id} = shift;
    } else {
        %opts = @_;
    }
    return '' unless defined $opts{id};

    my $self = bless {
        id     => $opts{id}, # our repository ID
        conn   => $conn,     # a connection for accessing the server
        lang   => 'SeRQL',   # the default query language
        errstr => '',        # the most recent error string
        strip  => 'none',    # the default strip option for select()
    }, $class;

    if( exists $opts{query_language} ) {
        $self->query_language($opts{query_language});
    }

    $self->{strip} = $opts{strip} if exists $opts{strip};

    return $self;
}

1;

__END__

=head1 NAME

RDF::Sesame::Repository - A repository on a Sesame server

=head1 DESCRIPTION

This class is the workhorse of RDF::Sesame.  Adding triples, removing triples
and querying the repository are all done through instances of this class.
Only SELECT queries are supported at this point, but it should be fairly
straightforward to add CONSTRUCT functionality.  If you do it, send me a
patch ;-)

=head1 METHODS

=head2 construct ( %opts )

Evaluates a construct query and returns the RDF serialization of the resulting
RDF graph.  A minimal invocation looks something like:

    my $q = qq(
        CONSTRUCT {Parent} ex:hasChild {Child}
        FROM {Child} ex:hasParent {Parent}
        USING NAMESPACE
            ex = <http://example.org/things#>
    );
    my $rdf = $repo->construct(
        query  => $q,
        format => 'turtle',
    );

If an error occurs during the construction, an exception is thrown.  This is
different from some RDF::Sesame methods which return C<undef>.

=head3 format

    Required: Yes

Indicates the RDF serialization format that the Sesame server should return.
Acceptable values are 'rdfxml', 'turtle' and 'ntriples'.

=head3 language

    Default: SeRQL

Specifies the language in which the construct query is written.  This is only
included for forwards-compatibility since the only query language supported by
Sesame is SeRQL.

=head3 output

    Default: undef

Indicates where the RDF serialization should be placed.  The default value of
C<undef> means that the serialization should simply be returned as the value
of the C<construct> method.

If the value is a filehandle, the serialization is written to that filehandle.
The filehandle must already be open for writing.  Otherwise, the value is
taken to be a filename which is opened for writing (clobbering existing
contents) and the serialization is written to the file.

=head3 query

    Required : Yes

The text of the construct query.

=head2 extract ( %opts )

Extract an RDF representation of all the triples in the repository.  The only
required option is L</format> which specifies the serialization format of the
resulting RDF.  The minimal method invocation looks like

    my $rdf = $repo->extract( format => 'turtle' )

where C<$rdf> is a reference to a scalar containing the serialization of all
the triples in the repository.  The streaming results returned by Sesame are
handled appropriately so that memory usage in minimized.  If the output is
sent to a file (see L</output>), only one "chunk" is held in memory at a time
(subject to caching by your OS).  The serialization may also be compressed (or
otherwise processed) as it's being streamed from the server (see
L</compress>).

Error handling is done differently in this method than in other methods in
L<RDF::Sesame>.  Namely, if an error occurs, an exception is thrown (rather
than returning undef and setting C<errstr()>.  Eventually, I'd like all
methods to behave this way.

=head3 compress

    Default: 'none'

Indicates how the RDF serialization returned by the Sesame server should be
compressed (or otherwise processed) before it's sent to the designated output
destination (see L</output)>.  The default value of C<none> indicates that no
compression or processing should be performed.  The value C<gz> indicates that
L<Compress::Zlib> should be used to compress the serialization into the gzip
file format.  Unfortunately, gzip compression is incompatible with an C<undef>
value of the L</output> option.  This is because of a problem with
L<Compress::Zlib> writing to in-memory filehandles.  If you try it, you'll get
an error message about a "bad file descriptor".

One may also specify a hash reference as the value of this option.  The hash
reference should contain the keys 'init', 'content', and 'finish'.  The value
for each key should be a subroutine reference which will be called during the
extraction process.

The 'init' coderef is called before any data is received from Sesame.  It
receives an output filehandle as its sole argument and should return a
"context" value which will be passed to the 'content' and 'finish' callbacks.
The context may be any value, but objects and hashrefs seem to be the most
useful.

The 'content' coderef is called once for each chunk of data returned from the
Sesame server.  It receives the context, the output filehandle and a
serialization chunk as arguments.  Its return value is ignored.

The 'finish' coderef is called after all data has been received from the
server and after the last call to the 'content' coderef has completed.
'finish' receives the context and the output filehandle as arguments.  Its
return value is ignored.

Here is a short example of using callbacks to implement gzip compression (of
course gzip compression is already implemented by specifying 'gz' as the
compression value):

    my $rdf_gz = $repo->extract(
        format   => 'turtle',
        compress => {
            init => sub {
                my ($fh) = @_;
                require Compress::Zlib;
                binmode $fh;
                my $gz = Compress::Zlib::gzopen( $fh, 'wb' );
                return $gz;    # our context object
            },
            content => sub {
                my ( $context, $fh, $content ) = @_;
                $context->gzwrite($content);
            },
            finish => sub {
                my ( $context, $fh ) = @_;
                $context->gzclose();
            },
        },
    );

=head3 format

    Required: Yes

Indicates the RDF serialization format that the Sesame server should return.
Acceptable values are 'rdfxml', 'turtle' and 'ntriples'.

=head3 options

    Default: []

Specifies various boolean extraction options provided by Sesame for extracting
RDF from the repository.  Acceptable options are 'niceOutput', 'explicitOnly',
'data', 'schema'.  The values of these options have the meanings indicated in
the "User Guide for Sesame 1.2" section 8.1.6.  See
L<http://www.openrdf.org/doc/sesame/users/ch08.html#d0e3026>.

=head3 output

    Default: undef

Indicates where the RDF serialization (including processing done according to
the 'compress' argument) should be placed.  The default value of C<undef>
means that the serialization should simply be returned as the value of the
C<extract> method.

If the value is a filehandle, the serialization is written to that filehandle.
The filehandle must already be open for writing.  Otherwise, the value is
taken to be a filename which is opened for writing (clobbering existing
contents) and the serialization is written to the file.

=head2 query_language ( [ $language ] )

Sets or gets the default query language.  Acceptable values for $language
are "RQL", "RDQL" and "SeRQL" (case sensitive).  If an unacceptable value
is given, query_language() behaves as if no C<$language> had been provided.

When an RDF::Sesame::Repository object is first created, the default query
language is SeRQL.  It is not necessary to change the default query language
because the language can be specified on a per query basis by using the 
C<$language> parameter of the select() method (documented below).

 Parameters :
    $language  The query language to use for queries in which the
        language is not otherwise specified.
 
 Returns :
    If setting, the old value is returned.  If getting, the current
    value is returned.
    
=head2 select ( %opts )

Execute a query against this repository and return an RDF::Sesame::TableResult
object.  This object can be used to access the table of results in a number of
useful ways.

Only SELECT queries are supported through this method. A list of the options
which are currently understood is provided below.  If a single scalar is
provided instead of C<%opts>, the scalar is used as the value of the 'query'
option.

Returns an RDF::Sesame::TableResult on success or the empty string on failure.

If an error occurs, call errstr() for an explanation.

=head3 format

Specifies the results format that the Sesame should return.  The default value
is 'binary' indicates that the "Binary RDF Table Results" format should be
used.  The value 'xml' indicates that Sesame's XML results format should be
used.

My own simple benchmarks show that the binary results format parses 40 to 400
times faster than the XML format (depending on whether you use a C-based or a
pure Perl XML parser).  The binary results format is also significantly
smaller in size than the XML format, so it's particularly useful in
bandwidth-constrained environments. Because the performance with binary
results is so much better, binary results are the default.  See
C<bench-parse.pl> that came with this distribution for a simple benchmarking
program.  C<t/a.*>, C<t/b.*> and C<t/c.*> in the distribution are samples
against which the benchmarks can be run.

There are three circumstances in which the binary results format should not be
used.  These limitations are a result of limitations in the binary format:
This list is current as of Sesame 1.2.4:

=over

=item *

Values (literals and column names) with a null byte are not decoded correctly
by RDF::Sesame.  See L<http://www.openrdf.org/issues/browse/SES-244> for
background.

=item *

Values outside of the Unicode Basic Multilingual Plane are not decoded
correctly.  See
L<http://en.wikipedia.org/w/index.php?title=UTF-8&oldid=49058202#Java> for
background.

=item *

Values longer than 65,536 bytes are not encoded correctly in the binary
results format.  See L<http://www.openrdf.org/issues/browse/SES-245> for
details.

=back

=head3 language

The query language used by the query. The option accepts the same values as
the L</query_language ( [ $language ] )> method.

If this option is not provided, the default language that was set through
query_language() is used.  If query_language() has not been called, then
"SeRQL" is assumed.

=head3 query

The text of the query to execute.  The format of this text is dependent on
the query language you're using.

Default: ''

=head3 strip

Determines whether N-Triples encoding will be stripped from the
query results.  Normally, a literal is surrounded with double quotes and a
URIref is surrounded with angle brackets.  Literals may also have language
or datatype information.  By using the strip option, this behavior can be
changed.

The value of the strip option is a scalar describing how you want the
query results to be stripped.  Acceptable values are listed below.
The default for all calls to select may be changed by specifying the
strip option to RDF::Sesame::Connection::open

=over 4

=item B<literals>

strip N-Triples encoding from Literals

=item B<urirefs>

strip N-Triples encoding from URIrefs

=item B<all>

strip N-Triples encoding from Literals and URIrefs

=item B<none>

the default; leave N-Triples encoding intact

=back

For example, to strip all N-Triples encoding, call select() like this

 $repo->select(
    query => $serql,
    strip => 'all',
 );

=head2 upload_data ( %opts )

Upload triples to the repository.  C<%opts> is a hash of named options
to use when uploading the data.  Acceptable option names are documented
below.  If a single scalar is provided instead of C<%opts>, the scalar
will be used as the value of the 'data' option.

This method is mostly useful for uploading triples which your program
has generated itself.  If you want to upload the data from a URI or even
a local file (using the "file:" URI scheme) then use the C<upload_uri>
method.  It will take care of fetching the data and uploading it all in
one step.

Returns the number of triples processed or 0 on error.  If an error
occurs during the upload, call errstr() to find out why.

=head3 data

The triples that should be uploaded.  The 'format' option specifies the
format of the triples.

Default: ''

=head3 format

The format of the 'data' option.  Acceptable values are 'rdfxml', 'ntriples'
and 'turtle'.  If a value other than these is specified, 0 is returned
and calling C<errstr> will return an explanatory message.

Default : ntriples

=head3 base

The base URI to use for resolving relative URIs.  The default is not useful so
be sure to specify this parameter if the data has relative URIs.

=head3 verify

Indicates whether data uploaded to Sesame should be verified before it is
added to the repository.

Default : true

=head2 upload_uri ( %opts )

Uploads the triples from the resource located at a given URI.  This method
supports the "file:" URI scheme.  If the L</server_file> option is specified,
the URI is interpreted as a file stored directly on the Sesame server;
otherwise, LWP::Simple is used to retrieve the contents off the local machine.
Those contents are then passed as the 'data' option to upload_data().  For any
URI scheme besides "file:", the Sesame server will retrieve the data on its
own.

The C<%opts> parameter provides a list of named options to use when uploading
the data.  If a single scalar is provided instead of C<%opts>, the scalar
is used as the value of the 'uri' option.  A list of acceptable options
is provided below.

Returns the number of triples processed or 0 on error.  If an error
occurs during the upload, call errstr() to find out why.

=head3 uri

The URI of the resource to upload.  The scheme of the URI may be 'file:' or
anything supported by Sesame.

Default: ''

=head3 format

The format of the data located at the given URI.  This can be one of 'rdfxml',
'ntriples' or 'turtle'.

Default: 'rdfxml'

=head3 server_file

If true, forces 'file:' URIs to be fetched by the Sesame server instead of
fetched off the local machine.  This allows one to upload an RDF file that is
stored directly on the Sesame server.

Default: 0

=head3 base

The base URI of the data for resolving any relative URIs.  The default
base URI is the URI of the resource to upload.

=head3 verify

Indicates whether data uploaded to Sesame should be verified before it is
added to the repository.

Default : true

=head2 clear

Removes all triples from the repository.  When this method is finished, all
the data in the repository will be gone, so be careful.

 Return : 
    1 for success and the empty string for failure.

=head2 remove ($subject, $predicate, $object)

Removes from the repository triples which match the specified pattern.
C<undef> is a wildcard which matches any value at that position.  For
example:

 $repo->remove(undef, "<http://xmlns.com/foaf/0.1/gender>", '"male"')

will remove from the repository all the foaf:gender triples which have a
value of "male".  Notice also that the values should be encoded in NTriples
syntax:

  * URI    : <http://foo.com/bar>
  * bNode  : _:nodeID
  * literal: "Hello", "Hello"@en and "Hello"^^<http://bar.com/foo>


 Parameters :
    $subject  The NTriples-encoded subject of the triples to
        remove.  If this is undef, it will match all
        subjects.
 
    $predicate  The NTriples-encoded predicate of the triples
        to remove.  If this is undef, it will match
        all predicates.
 
    $object  The NTriples-encoded object of the triples to remove.
        If this is undef, it will match all objects.
 
 Return : 
    The number of statements removed (including 0 on error).

=head2 errstr( )

Returns a string explaining the most recent error from this repository.
Returns the empty string if no error has occured yet or the most recent
method call succeeded.

=head1 INTERNAL METHODS

These methods are used internally by RDF::Sesame::Repository.  They will
probably not be helpful to general users of the class, but they are
documented here just in case.

=head2 command ( $name [, $parameters ] )

Execute a command against a Sesame repository.  This method is generally
used internally, but is provided and documented in case others want to
use it for their own reasons.

It's a simple wrapper around the RDF::Sesame::Connection::command method
which simply adds the name of this repository to the list of parameters
before executing the command.


  Parameters :
    $name  The name of the command to execute.  This name should be
        the name used by Sesame.  Example commands are "login"
        or "listRepositories"
 
    $parameters  An optional hashref giving the names and values
        of parameters for the command.
 
  Return : 
    RDF::Sesame::Response

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2005-2006 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
