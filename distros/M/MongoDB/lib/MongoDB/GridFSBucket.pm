#  Copyright 2015 - present MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use warnings;
package MongoDB::GridFSBucket;

# ABSTRACT: A file storage abstraction

use version;
our $VERSION = 'v2.2.2';

use Moo;
use MongoDB::GridFSBucket::DownloadStream;
use MongoDB::GridFSBucket::UploadStream;
use MongoDB::_Types qw(
  Boolish
  ReadPreference
  WriteConcern
  ReadConcern
  BSONCodec
  NonNegNum
);
use Scalar::Util qw/reftype/;
use Types::Standard qw(
  Str
  InstanceOf
);
use namespace::clean -except => 'meta';

#pod =attr database
#pod
#pod The L<MongoDB::Database> containing the GridFS bucket collections.
#pod
#pod =cut

has database => (
    is       => 'ro',
    isa      => InstanceOf ['MongoDB::Database'],
    required => 1,
);

#pod =attr bucket_name
#pod
#pod The name of the GridFS bucket.  Defaults to 'fs'.  The underlying
#pod collections that are used to implement a GridFS bucket get this string as a
#pod prefix (e.g "fs.chunks").
#pod
#pod =cut

has bucket_name => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'fs' },
);

#pod =attr chunk_size_bytes
#pod
#pod The number of bytes per chunk.  Defaults to 261120 (255kb).
#pod
#pod =cut

has chunk_size_bytes => (
    is      => 'ro',
    isa     => NonNegNum,
    default => sub { 255 * 1024 },
);

#pod =attr write_concern
#pod
#pod A L<MongoDB::WriteConcern> object.  It may be initialized with a hash
#pod reference that will be coerced into a new MongoDB::WriteConcern object.
#pod By default it will be inherited from a L<MongoDB::Database> object.
#pod
#pod =cut

has write_concern => (
    is       => 'ro',
    isa      => WriteConcern,
    required => 1,
    coerce   => WriteConcern->coercion,
);

#pod =attr read_concern
#pod
#pod A L<MongoDB::ReadConcern> object.  May be initialized with a hash
#pod reference or a string that will be coerced into the level of read
#pod concern.
#pod
#pod By default it will be inherited from a L<MongoDB::Database> object.
#pod
#pod =cut

has read_concern => (
    is       => 'ro',
    isa      => ReadConcern,
    required => 1,
    coerce   => ReadConcern->coercion,
);

#pod =attr read_preference
#pod
#pod A L<MongoDB::ReadPreference> object.  It may be initialized with a string
#pod corresponding to one of the valid read preference modes or a hash reference
#pod that will be coerced into a new MongoDB::ReadPreference object.
#pod By default it will be inherited from a L<MongoDB::Database> object.
#pod
#pod B<Note:> Because many GridFS operations require multiple independent reads from
#pod separate collections, use with secondaries is B<strongly discouraged> because
#pod reads could go to different secondaries, resulting in inconsistent data
#pod if all file and chunk documents have not replicated to all secondaries.
#pod
#pod =cut

has read_preference => (
    is       => 'ro',
    isa      => ReadPreference,
    required => 1,
    coerce   => ReadPreference->coercion,
);

#pod =attr bson_codec
#pod
#pod An object that provides the C<encode_one> and C<decode_one> methods, such
#pod as from L<BSON>.  It may be initialized with a hash reference that
#pod will be coerced into a new BSON object.  By default it will be
#pod inherited from a L<MongoDB::Database> object.
#pod
#pod =cut

has bson_codec => (
    is       => 'ro',
    isa      => BSONCodec,
    coerce   => BSONCodec->coercion,
    required => 1,
);

#pod =attr max_time_ms
#pod
#pod Specifies the maximum amount of time in milliseconds that the server should
#pod use for working on a query.  By default it will be inherited from a
#pod L<MongoDB::Database> object.
#pod
#pod B<Note>: this will only be used for server versions 2.6 or greater, as that
#pod was when the C<$maxTimeMS> meta-operator was introduced.
#pod
#pod =cut

has max_time_ms => (
    is       => 'ro',
    isa      => NonNegNum,
    required => 1,
);

#pod =attr disable_md5
#pod
#pod When true, files will not include the deprecated C<md5> field in the
#pod file document.  Defaults to false.
#pod
#pod =cut

has disable_md5 => (
    is       => 'ro',
    isa      => Boolish,
);

# determines whether or not to attempt index creation
has _tried_indexing => (
    is => 'rwp',
    isa => Boolish,
);

has _files => (
    is       => 'lazy',
    isa      => InstanceOf ['MongoDB::Collection'],
    init_arg => undef,
);

sub _build__files {
    my $self = shift;
    my $coll = $self->database->get_collection(
        $self->bucket_name . '.files',
        {
            read_preference => $self->read_preference,
            write_concern   => $self->write_concern,
            read_concern    => $self->read_concern,
            max_time_ms     => $self->max_time_ms,
            bson_codec      => $self->bson_codec,
        }
    );
    return $coll;
}

has _chunks => (
    is       => 'lazy',
    isa      => InstanceOf ['MongoDB::Collection'],
    init_arg => undef,
);

sub _build__chunks {
    my $self = shift;
    my $coll = $self->database->get_collection(
        $self->bucket_name . '.chunks',
        {
            read_preference => $self->read_preference,
            write_concern   => $self->write_concern,
            read_concern    => $self->read_concern,
            max_time_ms     => $self->max_time_ms,
            # XXX: Generate a new bson codec here to
            # prevent users from changing it?
            bson_codec => $self->bson_codec,
        }
    );
    return $coll;
}

# index operations need primary server, regardless of bucket read prefs
sub _create_indexes {
    my ($self) = @_;
    $self->_set__tried_indexing(1);

    my $pf = $self->_files->clone( read_preference => 'primary' );

    return if $pf->count_documents({}) > 0;

    my $pfi = $pf->indexes;
    my $pci = $self->_chunks->clone( read_preference => 'primary' )->indexes;

    if ( !grep { $_->{name} eq 'filename_1_uploadDate_1' } $pfi->list->all ) {
        $pfi->create_one( [ filename => 1, uploadDate => 1 ], { unique => 1 } );
    }

    if ( !grep { $_->{name} eq 'files_id_1_n_1' } $pci->list->all ) {
        $pci->create_one( [ files_id => 1, n => 1 ], { unique => 1 } );
    }

    return;
}

#pod =method find
#pod
#pod     $result = $bucket->find($filter);
#pod     $result = $bucket->find($filter, $options);
#pod
#pod     $file_doc = $result->next;
#pod
#pod Executes a query on the file documents collection with a
#pod L<filter expression|MongoDB::Collection/Filter expression> and
#pod returns a L<MongoDB::QueryResult> object.  It takes an optional hashref
#pod of options identical to L<MongoDB::Collection/find>.
#pod
#pod =cut

sub find {
    my ( $self, $filter, $options ) = @_;
    return $self->_files->find( $filter, $options )->result;
}

#pod =method find_one
#pod
#pod     $file_doc = $bucket->find_one($filter, $projection);
#pod     $file_doc = $bucket->find_one($filter, $projection, $options);
#pod
#pod Executes a query on the file documents collection with a
#pod L<filter expression|MongoDB::Collection/Filter expression> and
#pod returns the first document found, or C<undef> if no document is found.
#pod
#pod See L<MongoDB::Collection/find_one> for details about the
#pod C<$projection> and optional C<$options> fields.
#pod
#pod =cut

sub find_one {
    my ( $self, $filter, $projection, $options ) = @_;
    return $self->_files->find_one( $filter, $projection, $options );
}

#pod =method find_id
#pod
#pod     $file_doc = $bucket->find_id( $id );
#pod     $file_doc = $bucket->find_id( $id, $projection );
#pod     $file_doc = $bucket->find_id( $id, $projection, $options );
#pod
#pod Executes a query with a L<filter expression|/Filter expression> of
#pod C<< { _id => $id } >> and returns a single document or C<undef> if no document
#pod is found.
#pod
#pod See L<MongoDB::Collection/find_one> for details about the
#pod C<$projection> and optional C<$options> fields.
#pod
#pod =cut

sub find_id {
    my ( $self, $id, $projection, $options ) = @_;
    return $self->_files->find_id( $id, $projection, $options );
}

#pod =method open_download_stream
#pod
#pod     $stream = $bucket->open_download_stream($id);
#pod     $line = $stream->readline;
#pod
#pod Returns a new L<MongoDB::GridFSBucket::DownloadStream> that can be used to
#pod download the file with the file document C<_id> matching C<$id>.  This
#pod throws a L<MongoDB::GridFSError> if no such file exists.
#pod
#pod =cut

sub open_download_stream {
    my ( $self, $id ) = @_;
    MongoDB::UsageError->throw('No id provided to open_download_stream') unless $id;
    my $file_doc = $self->_files->find_id($id);
    MongoDB::GridFSError->throw("FileNotFound: no file found for id '$id'")
      unless $file_doc;
    my $result =
        $file_doc->{'length'} > 0
      ? $self->_chunks->find( { files_id => $id }, { sort => { n => 1 } } )->result
      : undef;
    return MongoDB::GridFSBucket::DownloadStream->new(
        {
            id       => $id,
            file_doc => $file_doc,
            _result  => $result,
        }
    );
}

#pod =method open_upload_stream
#pod
#pod     $stream = $bucket->open_upload_stream($filename);
#pod     $stream = $bucket->open_upload_stream($filename, $options);
#pod
#pod     $stream->print('data');
#pod     $stream->close;
#pod     $file_id = $stream->id
#pod
#pod Returns a new L<MongoDB::GridFSBucket::UploadStream> that can be used
#pod to upload a new file to a GridFS bucket.
#pod
#pod This method requires a filename to store in the C<filename> field of the
#pod file document.  B<Note>: the filename is an arbitrary string; the method
#pod does not read from this filename locally.
#pod
#pod You can provide an optional hash reference of options that are passed to the
#pod L<MongoDB::GridFSBucket::UploadStream> constructor:
#pod
#pod =for :list
#pod * C<chunk_size_bytes> – the number of bytes per chunk.  Defaults to the
#pod   C<chunk_size_bytes> of the bucket object.
#pod * C<metadata> – a hash reference for storing arbitrary metadata about the
#pod   file.
#pod
#pod =cut

sub open_upload_stream {
    my ( $self, $filename, $options ) = @_;
    MongoDB::UsageError->throw('No filename provided to open_upload_stream')
      unless defined $filename && length $filename;

    $self->_create_indexes unless $self->_tried_indexing;

    return MongoDB::GridFSBucket::UploadStream->new(
        {
            chunk_size_bytes => $self->chunk_size_bytes,
            ( $options ? %$options : () ),
            _bucket  => $self,
            filename => "$filename", # stringify path objects
        }
    );
}

#pod =method open_upload_stream_with_id
#pod
#pod     $stream = $bucket->open_upload_stream_with_id($id, $filename);
#pod     $stream = $bucket->open_upload_stream_with_id($id, $filename, $options);
#pod
#pod     $stream->print('data');
#pod     $stream->close;
#pod
#pod Returns a new L<MongoDB::GridFSBucket::UploadStream> that can be used to
#pod upload a new file to a GridFS bucket.
#pod
#pod This method uses C<$id> as the _id of the file being created, which must be
#pod unique.
#pod
#pod This method requires a filename to store in the C<filename> field of the
#pod file document.  B<Note>: the filename is an arbitrary string; the method
#pod does not read from this filename locally.
#pod
#pod You can provide an optional hash reference of options, just like
#pod L</open_upload_stream>.
#pod
#pod =cut

sub open_upload_stream_with_id {
    my ( $self, $id, $filename, $options ) = @_;
    my $id_copy = $id;
    MongoDB::UsageError->throw('No id provided to open_upload_stream_with_id')
      unless defined $id_copy && length $id_copy;
    MongoDB::UsageError->throw('No filename provided to open_upload_stream_with_id')
      unless defined $filename && length $filename;

    $self->_create_indexes unless $self->_tried_indexing;

    return MongoDB::GridFSBucket::UploadStream->new(
        {
            chunk_size_bytes => $self->chunk_size_bytes,
            ( $options ? %$options : () ),
            _bucket  => $self,
            filename => "$filename", # stringify path objects
            id => $id,
        }
    );
}

#pod =method download_to_stream
#pod
#pod     $bucket->download_to_stream($id, $out_fh);
#pod
#pod Downloads the file matching C<$id> and writes it to the file handle C<$out_fh>.
#pod This throws a L<MongoDB::GridFSError> if no such file exists.
#pod
#pod =cut

sub download_to_stream {
    my ( $self, $id, $target_fh ) = @_;
    MongoDB::UsageError->throw('No id provided to download_to_stream')
      unless defined $id;
    MongoDB::UsageError->throw('No handle provided to download_to_stream')
      unless defined $target_fh;
    MongoDB::UsageError->throw(
        'Invalid handle $target_fh provided to download_to_stream')
      unless reftype $target_fh eq 'GLOB';

    my $download_stream = $self->open_download_stream($id);
    my $csb             = $download_stream->file_doc->{chunkSize};
    my $buffer;
    while ( $download_stream->read( $buffer, $csb ) ) {
        print {$target_fh} $buffer;
    }
    $download_stream->close;
    return;
}

#pod =method upload_from_stream
#pod
#pod     $file_id = $bucket->upload_from_stream($filename, $in_fh);
#pod     $file_id = $bucket->upload_from_stream($filename, $in_fh, $options);
#pod
#pod Reads from a filehandle and uploads its contents to GridFS.  It returns the
#pod C<_id> field stored in the file document.
#pod
#pod This method requires a filename to store in the C<filename> field of the
#pod file document.  B<Note>: the filename is an arbitrary string; the method
#pod does not read from this filename locally.
#pod
#pod You can provide an optional hash reference of options, just like
#pod L</open_upload_stream>.
#pod
#pod =cut

sub upload_from_stream {
    my ( $self, $filename, $source_fh, $options ) = @_;
    MongoDB::UsageError->throw('No filename provided to upload_from_stream')
      unless defined $filename && length $filename;
    MongoDB::UsageError->throw('No handle provided to upload_from_stream')
      unless defined $source_fh;
    MongoDB::UsageError->throw(
        'Invalid handle $source_fh provided to upload_from_stream')
      unless reftype $source_fh eq 'GLOB';

    my $upload_stream = $self->open_upload_stream( $filename, $options );
    my $csb = $upload_stream->chunk_size_bytes;
    my $buffer;
    while ( read $source_fh, $buffer, $csb ) {
        $upload_stream->print($buffer);
    }
    $upload_stream->close;
    return $upload_stream->id;
}

#pod =method upload_from_stream_with_id
#pod
#pod     $bucket->upload_from_stream_with_id($id, $filename, $in_fh);
#pod     $bucket->upload_from_stream_with_id($id, $filename, $in_fh, $options);
#pod
#pod Reads from a filehandle and uploads its contents to GridFS.
#pod
#pod This method uses C<$id> as the _id of the file being created, which must be
#pod unique.
#pod
#pod This method requires a filename to store in the C<filename> field of the
#pod file document.  B<Note>: the filename is an arbitrary string; the method
#pod does not read from this filename locally.
#pod
#pod You can provide an optional hash reference of options, just like
#pod L</open_upload_stream>.
#pod
#pod Unlike L</open_upload_stream>, this method returns nothing.
#pod
#pod =cut

sub upload_from_stream_with_id {
    my ( $self, $id, $filename, $source_fh, $options ) = @_;
    my $id_copy = $id; # preserve number/string form
    MongoDB::UsageError->throw('No id provided to upload_from_stream_with_id')
      unless defined $id_copy && length $id_copy;
    MongoDB::UsageError->throw('No filename provided to upload_from_stream_with_id')
      unless defined $filename && length $filename;
    MongoDB::UsageError->throw('No handle provided to upload_from_stream_with_id')
      unless defined $source_fh;
    MongoDB::UsageError->throw(
        'Invalid handle $source_fh provided to upload_from_stream_with_id')
      unless reftype $source_fh eq 'GLOB';

    my $upload_stream = $self->open_upload_stream_with_id( $id, $filename, $options );
    my $csb = $upload_stream->chunk_size_bytes;
    my $buffer;
    while ( read $source_fh, $buffer, $csb ) {
        $upload_stream->print($buffer);
    }
    $upload_stream->close;
    return;
}

#pod =method delete
#pod
#pod     $bucket->delete($id);
#pod
#pod Deletes the file matching C<$id> from the bucket.
#pod This throws a L<MongoDB::GridFSError> if no such file exists.
#pod
#pod =cut

sub delete {
    my ( $self, $id ) = @_;

    $self->_create_indexes unless $self->_tried_indexing;

    my $delete_result = $self->_files->delete_one( { _id => $id } );
    # This should only ever be 0 or 1, checking for exactly 1 to be thorough
    unless ( $delete_result->deleted_count == 1 ) {
        MongoDB::GridFSError->throw("FileNotFound: no file found for id $id");
    }
    $self->_chunks->delete_many( { files_id => $id } );
    return;
}

#pod =method drop
#pod
#pod     $bucket->drop;
#pod
#pod Drops the underlying files documents and chunks collections for this bucket.
#pod
#pod =cut

sub drop {
    my ($self) = @_;
    $self->_files->drop;
    $self->_chunks->drop;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::GridFSBucket - A file storage abstraction

=head1 VERSION

version v2.2.2

=head1 SYNOPSIS

    $bucket = $database->gfs;

    # upload a file
    $stream  = $bucket->open_upload_stream("foo.txt");
    $stream->print( $data );
    $stream->close;

    # find and download a file
    $result  = $bucket->find({filename => "foo.txt"});
    $file_id = $result->next->{_id};
    $stream  = $bucket->open_download_stream($file_id)
    $data    = do { local $/; $stream->readline() };

=head1 DESCRIPTION

This class models a GridFS file store in a MongoDB database and provides an
API for interacting with it.

Generally, you never construct one of these directly with C<new>.  Instead,
you call C<gfs> (short for C<get_gridfsbucket>) on a L<MongoDB::Database>
object.

=head1 USAGE

=head2 Data model

A GridFS file is represented in MongoDB as a "file document" with
information like the file's name, length, and any user-supplied
metadata.  The actual contents are stored as a number of "chunks" of binary
data.  (Think of the file document as a directory entry and the chunks like
blocks on disk.)

Valid file documents typically include the following fields:

=over 4

=item *

_id – a unique ID for this document, typically a BSON ObjectId.

=item *

length – the length of this stored file, in bytes

=item *

chunkSize – the size, in bytes, of each full data chunk of this file. This value is configurable per file.

=item *

uploadDate – the date and time this file was added to GridFS, stored as a BSON datetime value.

=item *

filename – the name of this stored file; the combination of filename and uploadDate (millisecond resolution) must be unique

=item *

metadata – any additional application data the user wishes to store (optional)

=item *

md5 – DEPRECATED a hash of the contents of the stored file (store this in C<metadata> if you need it) (optional)

=item *

contentType – DEPRECATED (store this in C<metadata> if you need it) (optional)

=item *

aliases – DEPRECATED (store this in C<metadata> if you need it) (optional)

=back

The C<find> method searches file documents using these fields.  Given the
C<_id> from a document, a file can be downloaded using the download
methods.

=head2 API Overview

In addition to general methods like C<find>, C<delete> and C<drop>, there
are two ways to go about uploading and downloading:

=over 4

=item *

filehandle-like: you get an object that you can read/write from similar to a filehandle.  You can even get a tied filehandle that you can hand off to other code that requires an actual Perl handle.

=item *

streaming: you provide a file handle to read from (upload) or print to (download) and data is streamed to (upload) or from (download) GridFS until EOF.

=back

=head2 Error handling

Unless otherwise explicitly documented, all methods throw exceptions if
an error occurs.  The error types are documented in L<MongoDB::Error>.

=head1 ATTRIBUTES

=head2 database

The L<MongoDB::Database> containing the GridFS bucket collections.

=head2 bucket_name

The name of the GridFS bucket.  Defaults to 'fs'.  The underlying
collections that are used to implement a GridFS bucket get this string as a
prefix (e.g "fs.chunks").

=head2 chunk_size_bytes

The number of bytes per chunk.  Defaults to 261120 (255kb).

=head2 write_concern

A L<MongoDB::WriteConcern> object.  It may be initialized with a hash
reference that will be coerced into a new MongoDB::WriteConcern object.
By default it will be inherited from a L<MongoDB::Database> object.

=head2 read_concern

A L<MongoDB::ReadConcern> object.  May be initialized with a hash
reference or a string that will be coerced into the level of read
concern.

By default it will be inherited from a L<MongoDB::Database> object.

=head2 read_preference

A L<MongoDB::ReadPreference> object.  It may be initialized with a string
corresponding to one of the valid read preference modes or a hash reference
that will be coerced into a new MongoDB::ReadPreference object.
By default it will be inherited from a L<MongoDB::Database> object.

B<Note:> Because many GridFS operations require multiple independent reads from
separate collections, use with secondaries is B<strongly discouraged> because
reads could go to different secondaries, resulting in inconsistent data
if all file and chunk documents have not replicated to all secondaries.

=head2 bson_codec

An object that provides the C<encode_one> and C<decode_one> methods, such
as from L<BSON>.  It may be initialized with a hash reference that
will be coerced into a new BSON object.  By default it will be
inherited from a L<MongoDB::Database> object.

=head2 max_time_ms

Specifies the maximum amount of time in milliseconds that the server should
use for working on a query.  By default it will be inherited from a
L<MongoDB::Database> object.

B<Note>: this will only be used for server versions 2.6 or greater, as that
was when the C<$maxTimeMS> meta-operator was introduced.

=head2 disable_md5

When true, files will not include the deprecated C<md5> field in the
file document.  Defaults to false.

=head1 METHODS

=head2 find

    $result = $bucket->find($filter);
    $result = $bucket->find($filter, $options);

    $file_doc = $result->next;

Executes a query on the file documents collection with a
L<filter expression|MongoDB::Collection/Filter expression> and
returns a L<MongoDB::QueryResult> object.  It takes an optional hashref
of options identical to L<MongoDB::Collection/find>.

=head2 find_one

    $file_doc = $bucket->find_one($filter, $projection);
    $file_doc = $bucket->find_one($filter, $projection, $options);

Executes a query on the file documents collection with a
L<filter expression|MongoDB::Collection/Filter expression> and
returns the first document found, or C<undef> if no document is found.

See L<MongoDB::Collection/find_one> for details about the
C<$projection> and optional C<$options> fields.

=head2 find_id

    $file_doc = $bucket->find_id( $id );
    $file_doc = $bucket->find_id( $id, $projection );
    $file_doc = $bucket->find_id( $id, $projection, $options );

Executes a query with a L<filter expression|/Filter expression> of
C<< { _id => $id } >> and returns a single document or C<undef> if no document
is found.

See L<MongoDB::Collection/find_one> for details about the
C<$projection> and optional C<$options> fields.

=head2 open_download_stream

    $stream = $bucket->open_download_stream($id);
    $line = $stream->readline;

Returns a new L<MongoDB::GridFSBucket::DownloadStream> that can be used to
download the file with the file document C<_id> matching C<$id>.  This
throws a L<MongoDB::GridFSError> if no such file exists.

=head2 open_upload_stream

    $stream = $bucket->open_upload_stream($filename);
    $stream = $bucket->open_upload_stream($filename, $options);

    $stream->print('data');
    $stream->close;
    $file_id = $stream->id

Returns a new L<MongoDB::GridFSBucket::UploadStream> that can be used
to upload a new file to a GridFS bucket.

This method requires a filename to store in the C<filename> field of the
file document.  B<Note>: the filename is an arbitrary string; the method
does not read from this filename locally.

You can provide an optional hash reference of options that are passed to the
L<MongoDB::GridFSBucket::UploadStream> constructor:

=over 4

=item *

C<chunk_size_bytes> – the number of bytes per chunk.  Defaults to the C<chunk_size_bytes> of the bucket object.

=item *

C<metadata> – a hash reference for storing arbitrary metadata about the file.

=back

=head2 open_upload_stream_with_id

    $stream = $bucket->open_upload_stream_with_id($id, $filename);
    $stream = $bucket->open_upload_stream_with_id($id, $filename, $options);

    $stream->print('data');
    $stream->close;

Returns a new L<MongoDB::GridFSBucket::UploadStream> that can be used to
upload a new file to a GridFS bucket.

This method uses C<$id> as the _id of the file being created, which must be
unique.

This method requires a filename to store in the C<filename> field of the
file document.  B<Note>: the filename is an arbitrary string; the method
does not read from this filename locally.

You can provide an optional hash reference of options, just like
L</open_upload_stream>.

=head2 download_to_stream

    $bucket->download_to_stream($id, $out_fh);

Downloads the file matching C<$id> and writes it to the file handle C<$out_fh>.
This throws a L<MongoDB::GridFSError> if no such file exists.

=head2 upload_from_stream

    $file_id = $bucket->upload_from_stream($filename, $in_fh);
    $file_id = $bucket->upload_from_stream($filename, $in_fh, $options);

Reads from a filehandle and uploads its contents to GridFS.  It returns the
C<_id> field stored in the file document.

This method requires a filename to store in the C<filename> field of the
file document.  B<Note>: the filename is an arbitrary string; the method
does not read from this filename locally.

You can provide an optional hash reference of options, just like
L</open_upload_stream>.

=head2 upload_from_stream_with_id

    $bucket->upload_from_stream_with_id($id, $filename, $in_fh);
    $bucket->upload_from_stream_with_id($id, $filename, $in_fh, $options);

Reads from a filehandle and uploads its contents to GridFS.

This method uses C<$id> as the _id of the file being created, which must be
unique.

This method requires a filename to store in the C<filename> field of the
file document.  B<Note>: the filename is an arbitrary string; the method
does not read from this filename locally.

You can provide an optional hash reference of options, just like
L</open_upload_stream>.

Unlike L</open_upload_stream>, this method returns nothing.

=head2 delete

    $bucket->delete($id);

Deletes the file matching C<$id> from the bucket.
This throws a L<MongoDB::GridFSError> if no such file exists.

=head2 drop

    $bucket->drop;

Drops the underlying files documents and chunks collections for this bucket.

=head1 SEE ALSO

Core documentation on GridFS: L<http://dochub.mongodb.org/core/gridfs>.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Rassi <rassi@mongodb.com>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Kristina Chodorow <k.chodorow@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
