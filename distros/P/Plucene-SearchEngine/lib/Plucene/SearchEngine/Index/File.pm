package Plucene::SearchEngine::Index::File;
use strict;
use base "Plucene::SearchEngine::Index::Base";
use Carp;
use File::MMagic;
use File::Spec::Functions qw(rel2abs);
use File::Basename;
use Time::Piece;
use File::stat;
my $magic = File::MMagic->new();

=head1 NAME

Plucene::SearchEngine::Index::File - File reader for filesystem files

=head1 DESCRIPTION

This frontend module takes a filesystem file, extracts its metadata and
passes the file onto a backend. The frontend registers the following
Plucene fields:

=over 3

=item mimetype

The MIME type of the file.

=item filename

The basename of the file's filename.

=item id

The URL of the file (C<file://...>)

=item modified

A Plucene date field representing the last modified date of the file

=back

=head2 METHODS

    Plucene::SearchEngine::Index::File->examine($filename [, $encoding])

This examines a file on the filesystem for the above metadata, before
handling it to a backend. If an encoding is given, the text will be
flagged as originally being that encoding, and then converted to UTF-8.

=cut

sub examine {
    my ($class, $filename, $encoding) = @_;
    return unless -r $filename;
    my $mime = $magic->checktype_filename($filename);
    my $self = $class->handler_for($filename, $mime)->new();
    $self->add_data("mimetype", "Text", $mime);
    $self->add_data("filename", "Text", basename($filename));
    $self->add_data("id", "Keyword", "file://".rel2abs($filename));
    $self->add_data("modified", "Date", Time::Piece->new(stat($filename)->mtime));
    if ($encoding) { $self->add_data("encoding", "Text", $encoding); }
    my @docs = $self->gather_data_from_file($filename);
    if (wantarray) { if (@docs > 1) { return @docs } else { return $self } }
    else {
        carp "Using ->examine in scalar context is deprecated";
        return $self;
    }
}

1;
