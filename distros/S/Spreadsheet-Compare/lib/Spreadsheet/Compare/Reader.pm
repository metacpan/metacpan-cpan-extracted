package Spreadsheet::Compare::Reader;

use Mojo::Base -base, -signatures;
use Spreadsheet::Compare::Common;

#<<<
use Spreadsheet::Compare::Config {
    identity   => sub { [] },
    skip       => sub { {} },
    chunk      => undef,
    has_header => undef,
}, make_attributes => 1;

has can_chunk => 0,          ro => 1;
has exhausted => undef,      ro => 1;
has chunker   => sub {},     ro => 1;
has skipper   => sub {},     ro => 1;
has header    => undef,      ro => 1;
has result    => sub { [] }, ro => 1;
has side      => sub { $_[0]->index ? 'right' : 'left' },   ro => 1;
has side_name => sub { $_[0]->index ? 'right' : 'left' },   ro => 1;
has index     => sub { croak 'Parameter "index" not set' }, ro => 1;
#>>>

has h2i => sub {
    my $hd = $_[0]->header;
    return { map { $hd->[$_] => $_ } 0 .. $#$hd };
};


sub init ($self) {
    $self->{__ro__skipper} = _make_skipper( $self->skip ) if $self->skip;
    WARN 'chunking not supported by ', ref($self), "\n"
        if defined( $self->chunk ) && !$self->can_chunk;
    $self->{__ro__chunker} = _make_chunker( $self->chunk )
        if defined( $self->chunk ) && $self->can_chunk;
    return $self;
}


sub setup () { croak 'Method "setup" not implemented by subclass' }

sub fetch () { croak 'Method "fetch" not implemented by subclass' }


# Returns reference to a subroutine that checks a given record
# for being subject to a "skip record" according to the test definition.
# Returns true, when the record should be skipped.
#<<<
sub _make_skipper ($skip) {
    my %skip_info = pairmap {
        my( $negate, $regex ) = $b =~ /^(!?)(.+)$/;
        $a => {
            negate => $negate ? 1 : 0,
            regex  => qr/$regex/
        };
    } %$skip;
    return sub ($rec) {
        return any { $_ } pairgrep { $rec->val($a) =~ /$b->{regex}/ ^ $b->{negate} } %skip_info;
    };
}
#>>>


# Returns reference to a subroutine that generates a chunk name for a given record
# with the settings under 'chunk' in the test definition.
sub _make_chunker ( $chunk ) {
    DEBUG "returning chunker";
    return sub ($rec) {
        my $chunk_name;
        if ( ref($chunk) ) {
            my $key   = $chunk->{column};
            my $regex = qr/$chunk->{regex}/;
            ($chunk_name) = $rec->val($key) =~ /$regex/;
            $chunk_name //= '';
        }
        else {
            $chunk_name = $rec->val($chunk);
        }

        DEBUG "Chunk name: $chunk_name";

        return $chunk_name;
    };
}


1;

=head1 NAME

Spreadsheet::Compare::Reader - Abstract Reader Base Class

=head1 SYNOPSIS

    package Spreadsheet::Compare::MyReader;
    use Mojo::Base 'Spreadsheet::Compare::Reader';

    sub setup  {...}
    sub fetch {...}

=head1 DESCRIPTION

Spreadsheet::Compare::Reader is an abstract base class for spreadsheet reader backends.
Available reader classes in this distribution are

=over 4

=item * L<Spreadsheet::Compare::Reader::CSV> for CSV files

=item * L<Spreadsheet::Compare::Reader::DB> for Databases

=item * L<Spreadsheet::Compare::Reader::FIX> for fixed size column files

=item * L<Spreadsheet::Compare::Reader::WB> for various spreadsheet formats like XLSX, ODS, ...

=back

This module defines the methods and attributes that are used by a Spreadsheet::Compare::Reader
subclass. The methods setup and fetch have to be overridden by the derived class and will
croak otherwise.

When subclassing consider using L<Spreadsheet::Compare::Common> for convenience.

=head1 ATTRIBUTES

If not stated otherwise, read write attributes can be set as options from the config file
passed to L<Spreadsheet::Compare> or L<spreadcomp>.

=head2 can_chunk

(B<readonly>) Will be set to a true value by the Reader module if the Reader supports
chunking.

=head2 chunk

    possible values: <column>
                     or
                     { column => <column>, regex => <regex> },
    default: undef

Process the input in batches defined by the content of a column. When the
regex form is used it has to have a capturing expression. The result will
be used as identifier for the chunk. For example:

    chunk:
        column: RECORD_NBR
        regex: '(\d{2})$'

will take the last two digits of the numbers in column RECORD_NBR, resulting
in up to 100 batches. This is useful for very large files that do not fit
entirely into memory (see L<Spreadsheet::Compare/LIMITING MEMORY USAGE>).
Reading for each batch will be handled sequentially to save memory.

All records will be read twice, first for creating the lookup info for the chunks
and second for the actual data. This will significantly increase execution time.

=head2 chunker

(B<readonly>) A reference to a generated subroutine that returns the chunk name
for a record based on the settings from L</chunk>. This will be called from the
Reader sublasses.

=head2 exhausted

(B<readonly>) Will be true if the reader has no more records to read.

=head2 has_header

  possible values: bool
  default: undefined

Specify whether the file contains a header line.

=head2 header

(B<readonly>) A reference to an array with the header names or (in case there is  no
named header) the zero based indexes.

=head2 identity

  possible values: <array of column numbers or names>
  default: []

Defines the identity to indentify and match a single record. If L</has_header> is
true, the header names can be used. If not, the column numbers (zero based) will
be used as header names.

  examples for config file entries:

    identity: [rec_nbr, rec_type]

    identity:
      - rec_nbr
      - rec_type

    identity: [3, 4, 17]

=head2 index

(B<readonly>) 0 for the reader on the left and 1 for the reader on the right side of the comparison.

=head2 result

(B<readonly>) A reference to an array with the currently read data after a call to fetch

=head2 side

(B<readonly>) 'left' for the reader on the left and 'right' for the reader on the right side of the comparison.

=head2 side_name

    possible values: <string>
    default: ''

The name for the side of the comparison used for reporting.

=head2 skip

    possible values: <key value pairs>
    default: undef

Skip lines by column content. Keys must be column names (when the input has column
headers, see L</has_header>) or numbers, the
values are interpreted as regular expressions. A leading '!' negates the regex.

Example:

    skip:
      Name: ^XYZ-
      Price: !\d

=head2 skipper

(B<readonly>) A reference to a generated subroutine that returns true or false
depending on whether the record should be skipped according to the value of L</skip>.
This will be called from the Reader sublasses.

=head1 METHODS

The methods L</setup> and L</fetch> have to be overridden by derived classes.

=head2 fetch($size)

Fetch $size records from the source.

=head2 setup()

Will be called by L<Spreadsheet::Compare::Single> at the start of a comparison.
This is for setup tasks before handling the first fetch (eg. opening a file,
reading the header, ...)

=cut
