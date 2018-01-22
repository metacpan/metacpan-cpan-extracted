#
#  Copyright 2009-2013 MongoDB, Inc.
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
#

use strict;
use warnings;
package MongoDB::GridFS::File;


# ABSTRACT: A Mongo GridFS file (DEPRECATED)

use version;
our $VERSION = 'v1.8.1';

use MongoDB::Error;
use IO::File;
use Moo;
use Types::Standard qw(
    HashRef
    InstanceOf
);
use namespace::clean -except => 'meta';

has _grid => (
    is       => 'ro',
    isa      => InstanceOf['MongoDB::GridFS'],
    required => 1,
);

#pod =attr info
#pod
#pod A hash reference of metadata saved with this file.
#pod
#pod =cut

has info => (
    is => 'ro',
    isa => HashRef,
    required => 1,
);


#pod =method print
#pod
#pod     $written = $file->print($fh);
#pod     $written = $file->print($fh, $length);
#pod     $written = $file->print($fh, $length, $offset)
#pod
#pod Writes the number of bytes specified from the offset specified 
#pod to the given file handle.  If no C<$length> or C<$offset> are
#pod given, the entire file is written to C<$fh>.  Returns the number
#pod of bytes written.
#pod
#pod =cut

sub print {
    my ($self, $fh, $length, $offset) = @_;
    $offset ||= 0;
    $length ||= 0;
    my ($written, $pos) = (0, 0);
    my $start_pos = $fh->getpos();

    $self->_grid->chunks->indexes->create_one(Tie::IxHash->new(files_id => 1, n => 1), { unique => 1 });

    my $cursor = $self->_grid->chunks->query({"files_id" => $self->info->{"_id"}})->sort({"n" => 1});

    if ( $self->info->{length} && !$cursor->has_next ) {
        MongoDB::GridFSError->throw(
            sprintf( "GridFS file corrupt: no chunks found for file ID '%s'",
                $self->info->{_id} )
        );
    }

    while ((my $chunk = $cursor->next) && (!$length || $written < $length)) {
        my $len = length $chunk->{'data'};

        # if we are cleanly beyond the offset
        if (!$offset || $pos >= $offset) {
            if (!$length || $written + $len < $length) {
                $fh->print($chunk->{"data"});
                $written += $len;
                $pos += $len;
            }
            else {
                $fh->print(substr($chunk->{'data'}, 0, $length-$written));
                $written += $length-$written;
                $pos += $length-$written;
            }
            next;
        }
        # if the offset goes to the middle of this chunk
        elsif ($pos + $len > $offset) {
            # if the length of this chunk is smaller than the desired length
            if (!$length || $len <= $length-$written) {
                $fh->print(substr($chunk->{'data'}, $offset-$pos, $len-($offset-$pos)));
                $written += $len-($offset-$pos);
                $pos += $len-($offset-$pos);
            }
            else {
                no warnings 'substr';
                $fh->print(substr($chunk->{'data'}, $offset-$pos, $length));
                $written += $length;
                $pos += $length;
            }
            next;
        }
        # if the offset is larger than this chunk
        $pos += $len;
    }
    $fh->setpos($start_pos);
    return $written;
}

#pod =method slurp
#pod
#pod     $all   = $file->slurp
#pod     $bytes = $file->slurp($length);
#pod     $bytes = $file->slurp($length, $offset);
#pod
#pod Return the number of bytes specified from the offset specified.  If no
#pod C<$length> or C<$offset> are given, the entire file is returned.
#pod
#pod =cut

sub slurp {
    my ($self,$length,$offset) = @_;
    my $bytes = '';
    my $fh = new IO::File \$bytes,'+>';
    my $written = $self->print($fh,$length,$offset);

    # some machines don't set $bytes
    if ($written and !length($bytes)) {
       my $retval;
       read $fh, $retval, $written;
       return $retval;
    }

    return $bytes;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::GridFS::File - A Mongo GridFS file (DEPRECATED)

=head1 VERSION

version v1.8.1

=head1 SYNOPSIS

    use MongoDB::GridFS::File;

    $outfile = IO::File->new("outfile", "w");
    $file = $grid->find_one;
    $file->print($outfile);

=head1 USAGE

=head2 Error handling

Unless otherwise explicitly documented, all methods throw exceptions if
an error occurs.  The error types are documented in L<MongoDB::Error>.

To catch and handle errors, the L<Try::Tiny> and L<Safe::Isa> modules
are recommended:

    use Try::Tiny;
    use Safe::Isa; # provides $_isa

    $bytes = try {
        $file->slurp;
    }
    catch {
        if ( $_->$_isa("MongoDB::TimeoutError" ) {
            ...
        }
        else {
            ...
        }
    };

To retry failures automatically, consider using L<Try::Tiny::Retry>.

=head1 ATTRIBUTES

=head2 info

A hash reference of metadata saved with this file.

=head1 METHODS

=head2 print

    $written = $file->print($fh);
    $written = $file->print($fh, $length);
    $written = $file->print($fh, $length, $offset)

Writes the number of bytes specified from the offset specified 
to the given file handle.  If no C<$length> or C<$offset> are
given, the entire file is written to C<$fh>.  Returns the number
of bytes written.

=head2 slurp

    $all   = $file->slurp
    $bytes = $file->slurp($length);
    $bytes = $file->slurp($length, $offset);

Return the number of bytes specified from the offset specified.  If no
C<$length> or C<$offset> are given, the entire file is returned.

=head1 DEPRECATION

B<Note>: This class has been deprecated in favor of
L<MongoDB::GridFSBucket> and its related upload and download classes.  This
class will be removed in a future release and you are encouraged to migrate
your applications to L<MongoDB::GridFSBucket>.

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

This software is Copyright (c) 2018 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
