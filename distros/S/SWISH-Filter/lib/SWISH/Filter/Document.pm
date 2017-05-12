package SWISH::Filter::Document;
use strict;
use Carp;
use File::Temp;
use Symbol;

use vars qw/ $VERSION $AUTOLOAD /;

$VERSION = '0.191';

# Map content types to swish-e parsers.

my %swish_parser_types = (
    'text/html'       => 'HTML*',
    'text/xml'        => 'XML*',
    'application/xml' => 'XML*',
    'text/plain'      => 'TXT*',
);

=pod

=head1 NAME

SWISH::Filter::Document - object model for result of SWISH::Filter

=head1 DESCRIPTION

A SWISH::Filter::Document object is returned by the SWISH::Filter convert()
method. This class is intended to be used privately, but you might subclass it
in order to extend or modify its behaviour.

=head1 METHODS

These methods are available to Filter authors, and also provide access to the
document after calling the convert() method to end-users of SWISH::Filter.

End users of SWISH::Filter will use a subset of these methods. See L<User Methods>.

Filter authors will also be interested in the L<Author Methods> secion.
The filter() method in each
Filter module is passed a SWISH::Filter::Document object.  Method calls may be made on this
object to check the document's current content type, or to fetch the document as either a
file name or a reference to a scalar containing the document content.

=cut

# Returns a new SWISH::Filter::document object
# or null if just can't process the document

sub new {
    my ( $class, $doc, $content_type ) = @_;

    return unless $doc && $content_type;

    my $self = bless {}, $class;

    if ( ref $doc ) {
        unless ( length $$doc ) {
            warn "Empty document passed to filter\n";
            return;
        }

        croak
            "Must supply a content type when passing in a reference to a document\n"
            unless $content_type;

    }
    else {

        unless ( -r $doc ) {
            warn "Filter unable to read doc '$doc': $!\n";
            return;
        }
    }

    $self->set_content_type($content_type);

    $self->{cur_doc} = $doc;

    return $self;
}

# Clean up any temporary files

sub DESTROY {
    my $self = shift;
    $self->remove_temp_file;
}

sub cur_doc {
    my ( $self, $doc_ref ) = @_;
    $self->{cur_doc} = $doc_ref if $doc_ref;
    return $self->{cur_doc};
}

sub remove_temp_file {
    my $self = shift;

    unless ( $ENV{FILTER_DEBUG} ) {
        unlink delete $self->{temp_file} if $self->{temp_file};
    }
}

# Used for tracking what filter(s) were used in processing

sub filters_used {
    my $self = shift;
    return $self->{filters_used} || undef;
}

sub dump_filters_used {
    my $self = shift;
    my $used = $self->filters_used;

    local $SIG{__WARN__};
    warn "\nFinal Content type for ", $self->name, " is ",
        $self->content_type,
        "\n";

    unless ($used) {
        warn "  *No filters were used\n";
        return;
    }

    warn
        "  >Filter $_->{name} converted from [$_->{start_content_type}] to [$_->{end_content_type}]\n"
        for @$used;
}

=head1 User Methods

These methods are intended primarily for those folks using SWISH::Filter. If you are
writing a filter, see also L<Author Methods>.

=head2 fetch_doc_reference

Returns a scalar reference to the document.  This can be used when the filter
can operate on the document in memory (or if an external program expects the input
to be from standard input).

If the file is currently on disk then it will be read into memory.  If the file was stored
in a temporary file on disk the file will be deleted once read into memory.
The file will be read in binmode if $doc-E<gt>is_binary is true.

Note that fetch_doc() is an alias.

=cut

sub fetch_doc_reference {
    my ($self) = @_;

    return ref $self->{cur_doc}    # just $self->read_file should work
        ? $self->{cur_doc}
        : $self->read_file;
}

# here's an alias for fetching a document reference.

*fetch_doc = *fetch_doc_reference;

=head2 was_filtered

Returns true if some filter processed the document

=cut

sub was_filtered {
    my $self = shift;
    return $self->filters_used ? 1 : 0;
}

=head2 content_type

Fetches the current content type for the document.

Example:

    return unless $filter->content_type =~ m!application/pdf!;


=cut

sub content_type {
    return $_[0]->{content_type} || '';
}

=head2 swish_parser_type

Returns a parser type based on the content type. Returns undef
if no parser type is mapped.

=cut

sub swish_parser_type {
    my $self = shift;

    my $content_type = $self->content_type || return;

    for ( keys %swish_parser_types ) {
        return $swish_parser_types{$_}
            if $content_type =~ /^\Q$_/;
    }

    return;
}

=head2 is_binary

Returns true if the document's content-type does not match "text/".

=cut

sub is_binary {
    my $self = shift;
    return $self->content_type !~ m[^text|xml$];
}

=head1 Author Methods

These methods are intended for those folks writing filters.

=head2 fetch_filename

Returns a path to the document as stored on disk.
This name can be passed to external programs (e.g. C<catdoc>) that expect input
as a file name.

If the document is currently in memory then a temporary file will be created.  Do not expect
the file name passed to be the real path of the document.

The file will be written in binmode if is_binary() returns true.

This method is not normally used by end-users of SWISH::Filter.

=cut

# This will create a temporary file if file is in memory

sub fetch_filename {
    my ($self) = @_;

    return ref $self->{cur_doc}
        ? $self->create_temp_file
        : $self->{cur_doc};
}

=head2 set_continue

Processing will continue to the next filter if this is set to a true value.
This should be set for filters that change encodings or uncompress documents.

=cut

sub set_continue {
    my ($self) = @_;
    return $self->continue(1);
}

sub continue {
    my ( $self, $continue ) = @_;
    my $old = $self->{continue} || 0;
    $self->{continue}++ if $continue;
    return $old;
}

=head2 set_content_type( I<type> );

Sets the content type for a document.

=cut

sub set_content_type {
    my ( $self, $type ) = @_;
    croak "Failed to pass in new content type\n" unless $type;
    $self->{content_type} = $type;
}

sub read_file {
    my $self = shift;
    my $doc  = $self->{cur_doc};
    return $doc if ref $doc;

    my $sym = gensym();
    open( $sym, "<$doc" ) or croak "Failed to open file '$doc': $!";
    binmode $sym if $self->is_binary;
    local $/ = undef;
    my $content = <$sym>;
    close $sym;
    $self->{cur_doc} = \$content;

    # Remove the temporary file, if one was created.
    $self->remove_temp_file;

    return $self->{cur_doc};
}

# write file out to a temporary file

sub create_temp_file {
    my $self = shift;
    my $doc  = $self->{cur_doc};

    return $doc unless ref $doc;

    my ( $fh, $file_name ) = File::Temp::tempfile();

    # assume binmode if we need to filter...
    binmode $fh if $self->is_binary;

    print $fh $$doc or croak "Failed to write to '$file_name': $!";
    close $fh or croak "Failed to close '$file_name' $!";

    $self->{cur_doc}   = $file_name;
    $self->{temp_file} = $file_name;

    return $file_name;
}

=head2 name

Fetches the name of the current file.  This is useful for printing out the
name of the file in an error message.
This is the name passed in to the SWISH::Filter convert() method.
It is optional and thus may not always be set.

    my $name = $doc_object->name || 'Unknown name';
    warn "File '$name': failed to convert -- file may be corrupt\n";


=head2 user_data

Fetches the the user_data passed in to the filter.
This can be any data or data structure passed into SWISH::Filter new().

This is an easy way to pass special parameters into your filters.

Example:

    my $data = $doc_object->user_data;
    # see if a choice for the <title> was passed in
    if ( ref $data eq 'HASH' && $data->{pdf2html}{title_field}  {
       ...
       ...
    }

=cut

=head2 meta_data

Similar to user_data() but specifically intended for name/value pairs
in the C<meta> tags in HTML or XML documents.

If set, either via new() or explicitly via the meta_data() method,
the value of meta_data() can be used in a filter to set meta headers.

The value of meta_data() should be a hash ref so that it is easy to pass
to SWISH::Filters::Base->format_meta_headers().

After a document is filtered, the meta_data() method can be used to retrieve
the values that the filter inserted into the filtered document. This value is
(again) a hash ref, and is set by the SWISH::Filter module if the filter()
method returns a second value.  Because the filter module might also extract
meta data from the document itself, and might insert some of its own, it is up
to the individual filter to determine how and what it handles meta data.
See SWISH::Filters::Pdf2HTML for an example.

See the filter() method description in SWISH::Filter, the section on WRITING FILTERS.

Example:

 my $doc = $filter->convert( meta_data => {foo => 'bar'} );
 my $meta = $doc->meta_data;
 # $meta *probably* is {foo => 'bar'} but that's up to how the filter handled
 # the value passed in convert(). Could also be { foo => 'bar', title => 'some title' }
 # for example.

=cut

sub AUTOLOAD {
    my ( $self, $newval ) = @_;
    no strict 'refs';

    if ( $AUTOLOAD =~ /.*::set_(\w+)/ && $SWISH::Filter::extra_methods{$1} ) {
        my $attr_name = $1;
        *{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
        return $self->{$attr_name} = $newval;
    }

    elsif ( $AUTOLOAD =~ /.*::(\w+)/ && $SWISH::Filter::extra_methods{$1} ) {
        my $attr_name = $1;
        *{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
        return $self->{$attr_name};
    }

    croak "No such method: $AUTOLOAD\n";
}

1;

__END__

=head1 TESTING

Filters can be tested with the F<swish-filter-test> program in the C<example/>
directory. Run:

   swish-filter-test -man

for documentation.

=head1 SUPPORT

Please contact the Swish-e discussion list.  http://swish-e.org


=head1 AUTHOR

Bill Moseley

Currently maintained by Peter Karman C<perl@peknet.com>

=head1 COPYRIGHT

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=cut
