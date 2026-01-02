package PAGI::Request::Upload;
use strict;
use warnings;

use File::Basename qw(fileparse);
use File::Copy qw(move);
use File::Spec;
use Carp qw(croak);


# Constructor
sub new {
    my ($class, %args) = @_;
    my $self = bless {
        field_name   => $args{field_name}   // croak("field_name is required"),
        filename     => $args{filename}     // '',
        content_type => $args{content_type} // 'application/octet-stream',
        data         => $args{data},        # in-memory content
        temp_path    => $args{temp_path},   # on-disk path
        size         => $args{size},
        _cleaned_up  => 0,
    }, $class;

    # Calculate size if not provided
    if (!defined $self->{size}) {
        if (defined $self->{data}) {
            $self->{size} = length($self->{data});
        } elsif (defined $self->{temp_path} && -f $self->{temp_path}) {
            $self->{size} = -s $self->{temp_path};
        } else {
            $self->{size} = 0;
        }
    }

    return $self;
}

# Accessors
sub field_name   { my ($self) = @_; $self->{field_name} }
sub filename     { my ($self) = @_; $self->{filename} }
sub content_type { my ($self) = @_; $self->{content_type} }
sub size         { my ($self) = @_; $self->{size} }
sub temp_path    { my ($self) = @_; $self->{temp_path} }

# Basename - strips Windows and Unix paths
sub basename {
    my ($self) = @_;
    my $filename = $self->{filename};
    return '' unless $filename;

    # Strip Windows paths (C:\Users\... or \\server\share\...)
    $filename =~ s/.*[\\\/]//;

    return $filename;
}

# Predicates
sub is_empty {
    my ($self) = @_;
    return $self->{size} == 0;
}

sub is_in_memory {
    my ($self) = @_;
    return defined($self->{data});
}

sub is_on_disk {
    my ($self) = @_;
    return defined($self->{temp_path});
}

# Content access - slurp
sub slurp {
    my ($self) = @_;
    if ($self->is_in_memory) {
        return $self->{data};
    } elsif ($self->is_on_disk) {
        open my $fh, '<:raw', $self->{temp_path}
            or croak("Cannot read $self->{temp_path}: $!");
        my $content = do { local $/; <$fh> };
        close $fh;
        return $content;
    }
    return '';
}

# Content access - filehandle
sub fh {
    my ($self) = @_;
    if ($self->is_in_memory) {
        open my $fh, '<', \$self->{data}
            or croak("Cannot create filehandle from memory: $!");
        return $fh;
    } elsif ($self->is_on_disk) {
        open my $fh, '<:raw', $self->{temp_path}
            or croak("Cannot open $self->{temp_path}: $!");
        return $fh;
    }
    croak("No content available");
}

# Move upload to destination (BLOCKING - performs synchronous file I/O)
sub move_to {
    my ($self, $destination) = @_;

    # Ensure destination directory exists
    my ($name, $dir) = fileparse($destination);
    if ($dir && !-d $dir) {
        require File::Path;
        File::Path::make_path($dir);
    }

    if ($self->is_in_memory) {
        # Write data to destination (blocking I/O)
        open my $fh, '>:raw', $destination
            or croak("Cannot open $destination for writing: $!");
        print $fh $self->{data};
        close $fh;

        # Mark as cleaned up so destructor doesn't touch the saved file
        delete $self->{data};
        $self->{_cleaned_up} = 1;

        return $self;
    } elsif ($self->is_on_disk) {
        # Use File::Copy::move (typically a rename, very fast)
        move($self->{temp_path}, $destination)
            or croak("Cannot move to $destination: $!");

        # Mark as cleaned up so destructor doesn't touch the saved file
        delete $self->{temp_path};
        $self->{_cleaned_up} = 1;

        return $self;
    }

    croak("No content to move");
}

# Discard the upload
sub discard {
    my ($self) = @_;
    return if $self->{_cleaned_up};

    if ($self->is_on_disk && -f $self->{temp_path}) {
        unlink $self->{temp_path};
    }

    delete $self->{data};
    delete $self->{temp_path};
    $self->{_cleaned_up} = 1;
}

# Destructor - cleanup temp files
sub DESTROY {
    my ($self) = @_;
    $self->discard;
}

1;

__END__

=head1 NAME

PAGI::Request::Upload - Uploaded file representation

=head1 SYNOPSIS

    my $upload = await $req->upload('avatar');

    if ($upload && !$upload->is_empty) {
        my $filename = $upload->filename;
        my $size = $upload->size;
        my $content = $upload->slurp;

        $upload->move_to('/path/to/save');
    }

=head1 DESCRIPTION

PAGI::Request::Upload represents an uploaded file from a multipart form.
Files may be stored in memory (small files) or spooled to a temporary
file (large files).

=head1 CONSTRUCTOR

=head2 new

    my $upload = PAGI::Request::Upload->new(
        field_name   => 'avatar',
        filename     => 'photo.jpg',
        content_type => 'image/jpeg',
        data         => $bytes,        # OR
        temp_path    => '/tmp/abc123', # for spooled files
        size         => 12345,
    );

=head1 PROPERTIES

=head2 field_name

Form field name.

=head2 filename

Original filename from the upload.

=head2 basename

Filename without path components (safe for filesystem use).

=head2 content_type

MIME type of the uploaded file.

=head2 size

File size in bytes.

=head2 temp_path

Path to temporary file (if spooled to disk).

=head1 PREDICATES

=head2 is_empty

True if no data was uploaded.

=head2 is_in_memory

True if file data is stored in memory.

=head2 is_on_disk

True if file data is spooled to a temp file.

=head1 CONTENT METHODS

=head2 slurp

    my $bytes = $upload->slurp;

Read entire file content into memory.

=head2 fh

    my $fh = $upload->fh;

Get a filehandle for reading the upload.

=head1 FILE METHODS

=head2 move_to

    $upload->move_to('/path/to/destination');

Move the uploaded file to a destination path. Returns the upload object
for chaining.

B<Note:> This is a B<blocking> operation that performs synchronous file I/O.
For most uploads this completes quickly:

=over 4

=item * On-disk uploads use C<File::Copy::move()> (typically a fast rename)

=item * In-memory uploads write data directly to the destination file

=back

For very large files where blocking is a concern, use C<slurp()> or C<fh()>
to access the data and handle file I/O yourself with your preferred async
file library:

    # Non-blocking alternative (bring your own async file library)
    my $data = $upload->slurp;
    await $my_async_file_writer->write($destination, $data);

    # Or stream via filehandle
    my $fh = $upload->fh;
    while (my $chunk = read($fh, my $buf, 65536)) {
        await $my_async_writer->write($buf);
    }

=head1 CLEANUP

Temporary files are automatically deleted when the Upload object is
destroyed. If you want to keep the file, use C<move_to>.

=head1 SEE ALSO

L<PAGI::Request>

=cut
