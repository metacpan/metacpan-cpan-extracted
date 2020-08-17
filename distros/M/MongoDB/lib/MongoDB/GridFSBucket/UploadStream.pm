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
package MongoDB::GridFSBucket::UploadStream;

# ABSTRACT: File handle abstraction for uploading

use version;
our $VERSION = 'v2.2.2';

use Moo;
use BSON::Bytes;
use BSON::OID;
use BSON::Time;
use Encode;
use MongoDB::Error;
use Time::HiRes qw/time/;
use Types::Standard qw(
  Str
  Maybe
  HashRef
  ArrayRef
  InstanceOf
);
use MongoDB::_Types qw(
  Boolish
  NonNegNum
);
use MongoDB::_Constants;
use Digest::MD5;
use bytes;
use namespace::clean -except => 'meta';

#pod =attr chunk_size_bytes
#pod
#pod The number of bytes per chunk.  Defaults to the C<chunk_size_bytes> of the
#pod originating bucket object.
#pod
#pod This will be stored in the C<chunkSize> field of the file document on
#pod a successful upload.
#pod
#pod =cut

has chunk_size_bytes => (
    is      => 'ro',
    isa     => NonNegNum,
    default => 255 * 1024,
);

#pod =attr filename
#pod
#pod The filename to store the file under. Note that filenames are NOT necessarily unique.
#pod
#pod This will be stored in the C<filename> field of the file document on
#pod a successful upload.
#pod
#pod =cut

has filename => (
    is  => 'ro',
    isa => Str,
);

#pod =attr metadata
#pod
#pod An optional hashref for storing arbitrary metadata about the file.
#pod
#pod If defined, this will be stored in the C<metadata> field of the file
#pod document on a successful upload.
#pod
#pod =cut

has metadata => (
    is  => 'ro',
    isa => Maybe [HashRef],
);

#pod =attr content_type (DEPRECATED)
#pod
#pod An optional MIME type. This field should only be used for backwards
#pod compatibility with older GridFS implementations. New applications should
#pod store the content type in the metadata hash if needed.
#pod
#pod If defined, this will be stored in the C<contentType> field of the file
#pod document on a successful upload.
#pod
#pod =cut

has content_type => (
    is  => 'ro',
    isa => Str,
);

#pod =attr aliases (DEPRECATED)
#pod
#pod An optional array of aliases. This field should only be used for backwards
#pod compatibility with older GridFS implementations. New applications should
#pod store aliases in the metadata hash if needed.
#pod
#pod If defined, this will be stored in the C<aliases> field of the file
#pod document on a successful upload.
#pod
#pod =cut

has aliases => (
    is  => 'ro',
    isa => ArrayRef [Str],
);

has _bucket => (
    is       => 'ro',
    isa      => InstanceOf ['MongoDB::GridFSBucket'],
    required => 1,
);

#pod =method id
#pod
#pod     $id = $stream->id;
#pod
#pod The id of the file created by the stream.  It will be stored in the C<_id>
#pod field of the file document on a successful upload.  Some upload methods
#pod require specifying an id at upload time.  Defaults to a newly-generated
#pod L<BSON::OID> or BSON codec specific equivalent.
#pod
#pod =cut

has id => (
    is  => 'lazy',
);

sub _build_id {
    my $self = shift;
    my $creator = $self->_bucket->bson_codec->can("create_oid");
    return $creator ? $creator->() : BSON::OID->new();
}

has _closed => (
    is      => 'rwp',
    isa     => Boolish,
    default => 0,
);

has _buffer => (
    is      => 'rwp',
    isa     => Str,
    default => '',
);

has _length => (
    is      => 'rwp',
    isa     => NonNegNum,
    default => 0,
);

has _md5 => (
    is  => 'lazy',
    isa => InstanceOf ['Digest::MD5'],
);

sub _build__md5 {
    return Digest::MD5->new;
}

has _chunk_buffer_length => (
    is  => 'lazy',
    isa => NonNegNum,
);

sub _build__chunk_buffer_length {
    my ($self) = @_;
    my $docsize = $self->chunk_size_bytes + 36;
    return MAX_GRIDFS_BATCH_SIZE - $docsize;
}

has _current_chunk_n => (
    is      => 'rwp',
    isa     => NonNegNum,
    default => 0,
);

#pod =method fh
#pod
#pod     my $fh = $stream->fh;
#pod     print $fh, 'test data...';
#pod     close $fh
#pod
#pod Returns a new file handle tied to this instance of UploadStream that can be
#pod operated on with the built-in functions C<print>, C<printf>, C<syswrite>,
#pod C<fileno> and C<close>.
#pod
#pod B<Important notes>:
#pod
#pod Allowing one of these tied filehandles to fall out of scope will NOT cause
#pod close to be called. This is due to the way tied file handles are
#pod implemented in Perl.  For close to be called implicitly, all tied
#pod filehandles and the original object must go out of scope.
#pod
#pod Each file handle retrieved this way is tied back to the same object, so
#pod calling close on multiple tied file handles and/or the original object will
#pod have the same effect as calling close on the original object multiple
#pod times.
#pod
#pod =cut

sub fh {
    my ($self) = @_;
    my $fh = IO::Handle->new();
    tie *$fh, 'MongoDB::GridFSBucket::UploadStream', $self;
    return $fh;
}

sub _flush_chunks {
    my ( $self, $all ) = @_;
    my @chunks = ();
    my $data;
    while ( length $self->{_buffer} >= $self->chunk_size_bytes
        || ( $all && length $self->{_buffer} > 0 ) )
    {
        $data = substr $self->{_buffer}, 0, $self->chunk_size_bytes, '';

        push @chunks,
          {
            files_id => $self->id,
            n        => int( $self->_current_chunk_n ),
            data     => BSON::Bytes->new( data => $data ),
          };
        $self->{_current_chunk_n} += 1;
    }
    if ( scalar(@chunks) ) {
        eval { $self->_bucket->_chunks->insert_many( \@chunks ) };
        if ($@) {
            MongoDB::GridFSError->throw("Error inserting chunks: $@");
        }
    }
}

sub _write_data {
    my ( $self, $data ) = @_;
    Encode::_utf8_off($data); # force it to bytes for transmission
    $self->{_buffer} .= $data;
    $self->{_length} += length $data;
    $self->_md5->add($data) unless $self->_bucket->disable_md5;
    $self->_flush_chunks if length $self->{_buffer} >= $self->_chunk_buffer_length;
}

#pod =method abort
#pod
#pod     $stream->abort;
#pod
#pod Aborts the upload by deleting any chunks already uploaded to the database
#pod and closing the stream.
#pod
#pod =cut

sub abort {
    my ($self) = @_;
    if ( $self->_closed ) {
        warn 'Attempted to abort an already closed UploadStream';
        return;
    }

    $self->_bucket->_chunks->delete_many( { files_id => $self->id } );
    $self->_set__closed(1);
}

#pod =method close
#pod
#pod     $file_doc = $stream->close;
#pod
#pod Closes the stream and flushes any remaining data to the database. Once this is
#pod done a file document is created in the GridFS bucket, making the uploaded file
#pod visible in subsequent queries or downloads.
#pod
#pod On success, the file document hash reference is returned as a convenience.
#pod
#pod B<Important notes:>
#pod
#pod =for :list
#pod * Calling close will also cause any tied file handles created for the
#pod   stream to also close.
#pod * C<close> will be automatically called when a stream object is destroyed.
#pod   When called this way, any errors thrown will not halt execution.
#pod * Calling C<close> repeatedly will warn.
#pod
#pod =cut

sub close {
    my ($self) = @_;
    if ( $self->_closed ) {
        warn 'Attempted to close an already closed MongoDB::GridFSBucket::UploadStream';
        return;
    }
    $self->_flush_chunks(1);
    my $filedoc = {
        _id        => $self->id,
        length     => $self->_length,
        chunkSize  => $self->chunk_size_bytes,
        uploadDate => BSON::Time->new(),
        filename   => $self->filename,
        ( $self->_bucket->disable_md5 ? () : (md5 => $self->_md5->hexdigest) ),
    };
    $filedoc->{'contentType'} = $self->content_type if $self->content_type;
    $filedoc->{'metadata'}    = $self->metadata     if $self->metadata;
    $filedoc->{'aliases'}     = $self->aliases      if $self->aliases;
    eval { $self->_bucket->_files->insert_one($filedoc) };
    if ($@) {
        MongoDB::GridFSError->throw("Error inserting file document: $@");
    }
    $self->_set__closed(1);
    return $filedoc;
}

#pod =method fileno
#pod
#pod     if ( $stream->fileno ) { ... }
#pod
#pod Works like the builtin C<fileno>, but it returns -1 if the stream is open
#pod and undef if closed.
#pod
#pod =cut

sub fileno {
    my ($self) = @_;
    return if $self->_closed;
    return -1;
}

#pod =method print
#pod
#pod     $stream->print(@data);
#pod
#pod Works like the builtin C<print>.
#pod
#pod =cut

sub print {
    my $self = shift;
    return if $self->_closed;
    my $fsep = defined($,) ? $, : '';
    my $osep = defined($\) ? $\ : '';
    my $output = join( $fsep, @_ ) . $osep;
    $self->_write_data($output);
    return 1;
}

#pod =method printf
#pod
#pod     $stream->printf($format, @data);
#pod
#pod Works like the builtin C<printf>.
#pod
#pod =cut

sub printf {
    my $self   = shift;
    my $format = shift;
    local $\;
    $self->print( sprintf( $format, @_ ) );
}

#pod =method syswrite
#pod
#pod     $stream->syswrite($buffer);
#pod     $stream->syswrite($buffer, $length);
#pod     $stream->syswrite($buffer, $length, $offset);
#pod
#pod Works like the builtin C<syswrite>.
#pod
#pod =cut

sub syswrite {
    my ( $self, $buff, $len, $offset ) = @_;
    my $bufflen = length $buff;

    $len = $bufflen unless defined $len;
    if ( $len < 0 ) {
        MongoDB::UsageError->throw(
            'Negative length passed to MongoDB::GridFSBucket::DownloadStream->read');
    }

    $offset ||= 0;

    local $\;
    $self->print( substr( $buff, $offset, $len ) );
}

sub DEMOLISH {
    my ($self) = @_;
    $self->close unless $self->_closed;
}

sub TIEHANDLE {
    my ( $class, $self ) = @_;
    return $self;
}

sub BINMODE {
    my ( $self, $mode ) = @_;
    if ( !$mode || $mode eq ':raw' ) {
        return 1;
    }
    $! = "binmode for " . __PACKAGE__ . " only supports :raw mode.";
    return
}

{
    no warnings 'once';
    *PRINT  = \&print;
    *PRINTF = \&printf;
    *WRITE  = \&syswrite;
    *CLOSE  = \&close;
    *FILENO = \&fileno;
}

my @unimplemented = qw(
  EOF
  GETC
  READ
  READLINE
  SEEK
  TELL
);

for my $u (@unimplemented) {
    no strict 'refs';
    my $l = lc($u);
    *{$u} = sub {
        MongoDB::UsageError->throw( "$l() not available on " . __PACKAGE__ );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::GridFSBucket::UploadStream - File handle abstraction for uploading

=head1 VERSION

version v2.2.2

=head1 SYNOPSIS

    # OO API
    $stream  = $bucket->open_upload_stream("foo.txt");
    $stream->print( $data );
    $stream->close;
    $id = $stream->id;

    # Tied handle API
    $fh = $stream->fh
    print {$fh} $data;
    close $fh;

=head1 DESCRIPTION

This class provides a file abstraction for uploading.  You can stream data
to an object of this class via methods or via a tied-handle interface.

Writes are buffered and sent in chunk-size units.  When C<close> is called,
all data will be flushed to the GridFS Bucket and the newly created file
will be visible.

=head1 ATTRIBUTES

=head2 chunk_size_bytes

The number of bytes per chunk.  Defaults to the C<chunk_size_bytes> of the
originating bucket object.

This will be stored in the C<chunkSize> field of the file document on
a successful upload.

=head2 filename

The filename to store the file under. Note that filenames are NOT necessarily unique.

This will be stored in the C<filename> field of the file document on
a successful upload.

=head2 metadata

An optional hashref for storing arbitrary metadata about the file.

If defined, this will be stored in the C<metadata> field of the file
document on a successful upload.

=head2 content_type (DEPRECATED)

An optional MIME type. This field should only be used for backwards
compatibility with older GridFS implementations. New applications should
store the content type in the metadata hash if needed.

If defined, this will be stored in the C<contentType> field of the file
document on a successful upload.

=head2 aliases (DEPRECATED)

An optional array of aliases. This field should only be used for backwards
compatibility with older GridFS implementations. New applications should
store aliases in the metadata hash if needed.

If defined, this will be stored in the C<aliases> field of the file
document on a successful upload.

=head1 METHODS

=head2 id

    $id = $stream->id;

The id of the file created by the stream.  It will be stored in the C<_id>
field of the file document on a successful upload.  Some upload methods
require specifying an id at upload time.  Defaults to a newly-generated
L<BSON::OID> or BSON codec specific equivalent.

=head2 fh

    my $fh = $stream->fh;
    print $fh, 'test data...';
    close $fh

Returns a new file handle tied to this instance of UploadStream that can be
operated on with the built-in functions C<print>, C<printf>, C<syswrite>,
C<fileno> and C<close>.

B<Important notes>:

Allowing one of these tied filehandles to fall out of scope will NOT cause
close to be called. This is due to the way tied file handles are
implemented in Perl.  For close to be called implicitly, all tied
filehandles and the original object must go out of scope.

Each file handle retrieved this way is tied back to the same object, so
calling close on multiple tied file handles and/or the original object will
have the same effect as calling close on the original object multiple
times.

=head2 abort

    $stream->abort;

Aborts the upload by deleting any chunks already uploaded to the database
and closing the stream.

=head2 close

    $file_doc = $stream->close;

Closes the stream and flushes any remaining data to the database. Once this is
done a file document is created in the GridFS bucket, making the uploaded file
visible in subsequent queries or downloads.

On success, the file document hash reference is returned as a convenience.

B<Important notes:>

=over 4

=item *

Calling close will also cause any tied file handles created for the stream to also close.

=item *

C<close> will be automatically called when a stream object is destroyed. When called this way, any errors thrown will not halt execution.

=item *

Calling C<close> repeatedly will warn.

=back

=head2 fileno

    if ( $stream->fileno ) { ... }

Works like the builtin C<fileno>, but it returns -1 if the stream is open
and undef if closed.

=head2 print

    $stream->print(@data);

Works like the builtin C<print>.

=head2 printf

    $stream->printf($format, @data);

Works like the builtin C<printf>.

=head2 syswrite

    $stream->syswrite($buffer);
    $stream->syswrite($buffer, $length);
    $stream->syswrite($buffer, $length, $offset);

Works like the builtin C<syswrite>.

=head1 CAVEATS

=head2 Character encodings

All the writer methods (e.g. C<print>, C<printf>, etc.) send a binary
representation of the string input provided (or generated in the case of
C<printf>).  Unless you explicitly encode it to bytes, this will be the
B<internal> representation of the string in the Perl interpreter.  If you
have ASCII characters, it will already be bytes.  If you have any
characters above C<0xff>, it will be UTF-8 encoded codepoints.  If you have
characters between C<0x80> and C<0xff> and not higher, you might have
either bytes or UTF-8 internally.

B<You are strongly encouraged to do your own character encoding with
the L<Encode> module or equivalent and upload only bytes to GridFS>.

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
