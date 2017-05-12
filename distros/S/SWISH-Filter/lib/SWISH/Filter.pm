package SWISH::Filter;

use 5.005;
use strict;
use File::Basename;
use Carp;
use SWISH::Filter::MIMETypes;
use SWISH::Filter::Document;
use SWISH::Filters::Base;
use Module::Pluggable
    search_path => 'SWISH::Filters',
    except      => 'SWISH::Filters::Base',
    sub_name    => 'filters_found',
    require     => 1,
    instantiate => 'new';

use vars qw/ $VERSION %extra_methods /;

$VERSION = '0.191';

# Define the available parameters
%extra_methods = map { $_ => 1 } qw( meta_data name user_data );

# For testing only

if ( $0 =~ 'Filter.pm' && @ARGV >= 2 && shift =~ /^test/i ) {
    die "Please use the 'swish-filter-test' program.\n";
}

=head1 NAME

SWISH::Filter - filter documents for indexing with Swish-e

=head1 SYNOPSIS

  use SWISH::Filter;

  # load available filters into memory
  my $filter = SWISH::Filter->new;


  # convert a document

  my $doc = $filter->convert(
        document     => \$scalar_ref,  # path or ref to a doc
        content_type => $content_type, # content type if doc reference
        name         => $real_path,    # optional name for this file (useful for debugging)
        user_data    => $whatever,     # optional data to make available to filters
   );

  return unless $doc;  # empty doc, zero size, or no filters installed

  # Was the document converted by a filter?
  my $was_filtered = $doc->was_filtered;

  # Skip if the file is not text
  return if $doc->is_binary;

  # Print out the doc
  my $doc_ref = $doc->fetch_doc;
  print $$doc_ref;

  # Fetch the final content type of the document
  my $content_type = $doc->content_type;

  # Fetch Swish-e parser type (TXT*, XML*, HTML*, or undefined)
  my $doc_type = $doc->swish_parser_type;

=head1 DESCRIPTION

SWISH::Filter provides a unified way to convert documents into a type that
Swish-e can index.  Individual filters are installed as separate subclasses (modules).
For example, there might be a filter that converts from PDF format to HTML
format.

SWISH::Filter is a framework that relies on other packages to do the heavy lifting
of converting non-text documents to text.  B<Additional helper
programs or Perl modules may need to be installed to use SWISH::Filter to filter
documents.>  For example, to filter PDF documents you must install the C<Xpdf>
package.

The filters are automatically loaded when C<SWISH::Filters-E<gt>new()> is
called.  Filters define a type and priority that determines the processing
order of the filter.  Filters are processed in this sort order until a filter
accepts the document for filtering. The filter uses the document's content type
to determine if the filter should handle the current document.  The
content-type is determined by the files suffix if not supplied by the calling
program.

The individual filters are not designed to be used as separate modules.  All
access to the filters is through this SWISH::Filter module.

Normally, once a document is filtered processing stops.  Filters can filter the
document and then set a flag saying that filtering should continue (for example
a filter that uncompresses a MS Word document before passing on to the filter
that converts from MS Word to text).  All this should be transparent to the end
user.  So, filters can be pipe-lined.

The idea of SWISH::Filter is that new filters can be created, and then
downloaded and installed to provide new filtering capabilities.  For example,
if you needed to index MS Excel documents you might be able to download a
filter from the Swish-e site and magically next time you run indexing MS Excel
docs would be indexed.

The SWISH::Filter setup can be used with -S prog or -S http.  It works best
with the -S prog method because the filter modules only need to be loaded and
compiled one time.  The -S prog program F<spider.pl> will automatically use
SWISH::Filter when spidering with default settings (using "default" as the
first parameter to spider.pl).

The -S http indexing method uses a Perl helper script called F<swishspider>.
F<swishspider> has been updated to work with SWISH::Filter, but (unlike
spider.pl) does not contain a "use lib" line to point to the location of
SWISH::Filter.  This means that by default F<swishspider> will B<not> use
SWISH::Filter for filtering.  The reason for this is because F<swishspider>
runs for every URL fetched, and loading the Filters for each document can be
slow.  The recommended way of spidering is using -S prog with spider.pl, but if
-S http is desired the way to enable SWISH::Filter is to set PERL5LIB before
running swish so that F<swishspider> will be able to locate the SWISH::Filter
module.  Here's one way to set the PERL5LIB with the bash shell:

  $ export PERL5LIB=`swish-filter-test -path`



=head1 METHODS

=head2 new( %I<opts> )

new() creates a SWISH::Filter object.  You may pass in options as a list or a hash reference.

=head3 Options

There is currently only one option that can be passed in to new():

=over 4

=item ignore_filters

Pass in a reference to a list of filter names to ignore.  For example, if you have two filters installed
"Pdf2HTML" and "Pdf2XML" and want to avoid using "Pdf2XML":

    my $filter = SWISH::Filter->new( ignore_filters => ['Pdf2XML'];

=back

=cut

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my %attr = ref $_[0] ? %{ $_[0] } : @_ if @_;

    my $self = bless {}, $class;

    $self->{skip_filters} = {};

    $self->ignore_filters( delete $attr{ignore_filters} )
        if $attr{ignore_filters};

    warn "Unknown SWISH::Filter->new() config setting '$_'\n" for keys %attr;

    $self->{mimetypes} = SWISH::Filter::MIMETypes->new;

    $self->create_filter_list(%attr);

    $self->{doc_class} ||= 'SWISH::Filter::Document';

    return $self;
}

sub ignore_filters {
    my ( $self, $filters ) = @_;

    unless ($filters) {
        return unless $self->{ignore_filter_list};
        return @{ $self->{ignore_filter_list} };
    }

    @{ $self->{ignore_filter_list} } = @$filters;

    # create lookup hash for filters to skip
    $self->{skip_filters} = { map { $_, 1 } @$filters };
}

=head2 doc_class

If you subclass SWISH::Filter::Document with your own class, indicate your class
name in the new() method with the C<doc_class> param. The return value of doc_class()
is used in convert() for instatiating the Document object. The default value is
C<SWISH::Filter::Document>.

=cut

sub doc_class {
    return $_[0]->{doc_class};
}

=head2 convert

This method filters a document.  Returns an object belonging to doc_class()
on success. If passed an empty document, a filename that cannot be read off disk, or
if no filters have been loaded, returns undef.

See the SWISH::Filter::Document documentation.

You must pass in a hash (or hash reference) of parameters to the convert() method.  The
possible parameters are:

=over 8

=item document

This can be either a path to a file, or a scalar reference to a document in memory.
This is required.

=item content_type

The MIME type of the document.  This is only required when passing in a scalar
reference to a document. The content type string is what the filters use to
match a document type.

When passing in a file name and C<content_type> is not set, then the content type will
be determined from the file's extension by using the MIME::Types Perl module (available on CPAN).

=item name

Optional name to pass in to filters that will be used in error and warning messages.

=item user_data

Optional data structure that all filters may access.
This can be fetched in a filter by:

    my $user_data = $doc_object->user_data;

And used in the filter as:

    if ( ref $user_data && $user_data->{pdf2html}{title} ) {
       ...
    }

It's up to the filter author to use a unique first-level hash key for a given filter.

=item meta_data

Optional data structure intended for meta name/content pairs for HTML
or XML output. See SWISH::Filter::Document for discussion of this data.

=back

Example of using the convert() method:

    $doc_object = $filter->convert(
        document     => $doc_ref,
        content-type => 'application/pdf',
    );

=cut

sub convert {
    my $self = shift;
    my %attr = ref $_[0] ? %{ $_[0] } : @_ if @_;

    # Any filters?
    return unless $self->filter_list;

    my $doc = delete $attr{document}
        || die
        "Failed to supply document attribute 'document' when calling filter()\n";

    my $content_type = delete $attr{content_type};

    if ( ref $content_type ) {
        my $type = $self->decode_content_type($$content_type);

        unless ($type) {
            warn
                "Failed to set content type for file reference '$$content_type'\n";
            return;
        }
        $content_type = $type;
    }

    if ( ref $doc ) {
        die
            "Must supply a content type when passing in a reference to a document\n"
            unless $content_type;
    }
    else {
        $content_type ||= $self->decode_content_type($doc);
        unless ($content_type) {
            warn "Failed to set content type for document '$doc'\n";
            return;
        }

        $attr{name} ||= $doc;    # Set default name of document
    }

    $self->mywarn(
        "\n>> Starting to process new document: $attr{name} -> $content_type"
    );

    ## Create a new document object

    my $doc_object = $self->doc_class->new( $doc, $content_type );
    return unless $doc_object;    # fails on empty doc or doc not readable

    $self->_set_extra_methods( $doc_object, {%attr} );

    # Now run through the filters
    for my $filter ( $self->filter_list ) {

        $self->mywarn(" ++Checking filter [$filter] for $content_type");

        # can this filter handle this content type?
        next unless $filter->can_filter_mimetype( $doc_object->content_type );

        my $start_content_type = $doc_object->content_type;
        my ( $filtered_doc, $metadata );

        # run the filter
        eval {
            local $SIG{__DIE__};
            ( $filtered_doc, $metadata ) = $filter->filter($doc_object);
        };

        if ($@) {
            $self->mywarn(
                "Problems with filter '$filter'.  Filter disabled:\n -> $@");
            $self->filter_list(
                [ grep { $_ != $filter } $self->filter_list ] );
            next;
        }

        $self->mywarn( " ++ $content_type "
                . ( $filtered_doc ? '*WAS*' : 'was not' )
                . " filtered by $filter\n" );

        # save the working filters in this list

        if ($filtered_doc) {    # either a file name or a reference to the doc

            # Track chain of filters

            push @{ $doc_object->{filters_used} },
                {
                name               => $filter,
                start_content_type => $start_content_type,
                end_content_type   => $doc_object->content_type,
                };

            # and save it (filename or reference)
            $doc_object->cur_doc($filtered_doc);

        # set meta_data explicitly since %attr only has what we originally had
            $doc_object->set_meta_data($metadata);
            delete $attr{'meta_data'};

            # All done?
            last unless $doc_object->continue(0);

            $self->_set_extra_methods( $doc_object, {%attr} );

            $content_type = $doc_object->content_type();
        }
    }

    $doc_object->dump_filters_used if $ENV{FILTER_DEBUG};

    return $doc_object;

}

sub _set_extra_methods {
    my ( $self, $doc_object, $attr ) = @_;

    local $SIG{__DIE__};
    local $SIG{__WARN__};

    # Look for left over config settings that we do not know about

    for my $setting ( keys %extra_methods ) {
        next unless $attr->{$setting};
        my $method = "set_" . $setting;
        $doc_object->$method( delete $attr->{$setting} );

        # if given a document name then use that in error messages

        if ( $setting eq 'name' ) {
            $SIG{__DIE__}
                = sub { die "$$ Error- ", $doc_object->name, ": ", @_ };
            $SIG{__WARN__}
                = sub { warn "$$ Warning - ", $doc_object->name, ": ", @_ };
        }
    }

    warn "Unknown filter config setting '$_'\n" for keys %$attr;

}

=head2 mywarn

Internal method used for writing warning messages to STDERR if
$ENV{FILTER_DEBUG} is set.  Set the environment variable FILTER_DEBUG before
running to see extra messages while processing.

=cut

sub mywarn {
    my $self = shift;

    print STDERR @_, "\n" if $ENV{FILTER_DEBUG};
}

=head2 filter_list

Returns a list of filter objects installed.

=cut

sub filter_list {
    my ( $self, $filter_ref ) = @_;

    unless ($filter_ref) {
        return ref $self->{filters} ? @{ $self->{filters} } : ();
    }

    $self->{filters} = $filter_ref;
}

# Creates the list of filters
sub create_filter_list {
    my $self = shift;
    my %attr = @_;

    my @filters = grep {defined} $self->filters_found(%attr);

    unless (@filters) {
        warn "No SWISH filters found\n";
        return;
    }

    # Now sort the filters in order.
    @filters = sort { $a->type <=> $b->type || $a->priority <=> $b->priority }
        @filters;
    $self->filter_list( \@filters );
}

=head2 can_filter( I<content_type> )

This is useful for testing to see if a mimetype might be handled by SWISH::Filter
wihtout having to pass in a document.  Helpful if doing HEAD requests.

Returns an array of filters that can handle this type of document

=cut

my %can_filter = ();    # memoize

sub can_filter {
    my ( $self, $content_type ) = @_;

    unless ($content_type) {
        carp "Failed to pass in a content type to can_filter() method";
        return;
    }

    if ( exists $can_filter{$content_type} ) {
        return @{ $can_filter{$content_type} };
    }
    else {
        $can_filter{$content_type} = [];
    }

    for my $filter ( $self->filter_list ) {
        if ( $filter->can_filter_mimetype($content_type) ) {
            push @{ $can_filter{$content_type} }, $filter;
        }
    }

    return @{ $can_filter{$content_type} };
}

=head2 decode_content_type( I<filename> )

Returns MIME type for I<filename> if known.

=cut

sub decode_content_type {
    my ( $self, $file ) = @_;

    return unless $file;

    return $self->{mimetypes}->get_mime_type($file);
}

=head1 WRITING FILTERS

Filters are standard perl modules that are installed into the C<SWISH::Filters> name space.
Filters are not complicated -- see the core SWISH::Filters::* modules for examples.

Each filter defines the content-types (or mimetypes) that it can handle.  These
are specified as a list of regular expressions to match against the document's
content-type.  If one of the mimetypes of a filter match the incoming
document's content-type the filter is called.  The filter can then either
filter the content or return undefined indicating that it decided not to
filter the document for some reason.  If the document is converted the filter
returns either a reference to a scalar of the content or a file name where the
content is stored.  The filter also must change the content-type of the document
to reflect the new document.

Filters typically use external programs or modules to do that actual work of
converting a document from one type to another.  For example, programs in the
Xpdf packages are used for converting PDF files.  The filter can (and should)
test for those programs in its new() method.

Filters also can define a type and priority.  These attributes are used
to set the order filters are tested for a content-type match.  This allows
you to have more than one filter that can work on the same content-type. A lower
priority value is given preference over a higher priority value.

If a filter calls die() then the filter is removed from the chain and will not be
called again I<during the same run>.  Calling die when running with -S http or
-S fs has no effect since the program is run once per document.

Once a filter returns something other than undef no more filters will be
called.  If the filter calls $filter-E<gt>set_continue then processing will
continue as if the file was not filtered.  For example, a filter can uncompress
data and then set $filter-E<gt>set_continue and let other filters process the
document.


A filter may define the following methods (required methods are indicated):

=over 4

=item new() B<required>

This method returns either an object which provides access to the filter, or undefined
if the filter is not to be used.

The new() method is a good place to check for required modules or helper programs.
Returning undefined prevents the filter from being included in the filter chain.

The new method must return a blessed hash reference.  The only required attribute
is B<mimetypes>.  This attribute must contain a reference to an array of regular
expressions used for matching the content-type of the document passed in.

Example:

    sub new {
        my ( $class ) = @_;

        # List of regular expressions
        my @mimetypes = (
            qr[application/(x-)?msword],
            qr[application/worddoc],
        );

        my %settings = (
            mimetypes   => \@mimetypes,

            # Optional settings
            priority    => 20,
            type        => 2,
        );

        return bless \%settings, $class;
    }

The attribute "mimetypes" returns an array reference to a list of regular
expressions.  Those patterns are matched against each document's content type.

=item filter() B<required>

This is the function that does the work of converting a document from one content type
to another.  The function is passed the document object.  See document object methods
listed below for what methods may be called on a document.

The function can return undefined (or any false value) to indicate that the
filter did not want to process the document.  Other filters will then be tested for
a content type match.

If the document is filtered then the filter must set the new document's content
type (if it changed) and return either a file name where the document can be found or
a reference to a scalar containing the document.

The filter() method may also return a second value for storing metadata. The value
is typically a hash ref of name/value pairs. This value can then
be accessed via the meta_data() method in the SWISH::Filter::Document class.

=item type()

Returns a number. Filters are sorted (for processing in a specific order)
and this number is simply the primary key used in sorting.  If not specified
the filter's type used for sorting is 2.

This is an optional method.  You can also set the type in your new() constructor
as shown above.


=item priority()

Returns a number.  Filters are sorted (for processing in a specific order)
and this number is simply the secondary key used in sorting.  If not specified
the filter's priority is 50.

This is an optional method.  You can also set the priority in your new() constructor
as shown above.


=back

Again, the point of the type() and priority() methods is to allow setting the sort order
of the filters.  Useful if you have two filters for filtering the same content-type,
but prefer to use one over the other.  Neither are required.


=head1 EXAMPLE FILTER

Here's a module to convert MS Word documents using the program "catdoc":

    package SWISH::Filters::Doc2txt;
    use vars qw/ $VERSION /;

    $VERSION = '0.191';


    sub new {
        my ( $class ) = @_;

        my $self = bless {
            mimetypes   => [ qr!application/(x-)?msword! ],
            priority    => 50,
        }, $class;


        # check for helpers
        return $self->set_programs( 'catdoc' );

    }


    sub filter {
        my ( $self, $doc ) = @_;

        my $content = $self->run_catdoc( $doc->fetch_filename ) || return;

        # update the document's content type
        $filter->set_content_type( 'text/plain' );

        # return the document
        return \$content;
    }
    1;

The new() constructor creates a blessed hash which contains an array reference
of mimetypes patterns that this filter accepts.  The priority sets this
filter to run after any other filters that might handle the same type of content.
The F<set_programs()> function says that we need to call a program called "catdoc".
The function either returns $self or undefined if catdoc could not be found.
The F<set_programs()> function creates a new method for running catdoc.

The filter function runs catdoc passing in the name of the file (if the file is in memory
a temporary file is created).  That F<run_catdoc()> function was created by the
F<set_programs()> call above.


=cut

1;
__END__


=head1 TESTING

Filters can be tested with the F<swish-filter-test> program in the C<example/>
directory. Run:

   swish-filter-test -man

for documentation.

=head1 TODO

The C<File::Extract> package on CPAN does much of the same work as SWISH::Filter,
but used more native Perl. It might be worth investigating if there is anything
to be gained by using it in any of the core filters.

=head1 SUPPORT

Please contact the Swish-e discussion list.  http://swish-e.org


=head1 AUTHOR

Bill Moseley

Currently maintained by Peter Karman C<perl@peknet.com>

=head1 COPYRIGHT

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=cut
