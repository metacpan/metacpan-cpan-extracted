package Sweet::File;
use latest;
use Moose;

use Sweet::Types;

use Carp;
use File::Basename;
use File::Copy;
use File::Remove 'remove';
use File::Spec;
use Moose::Util::TypeConstraints;
use MooseX::AttributeShortcuts;
use MooseX::Types::Path::Class;
use Storable qw(dclone);
use Try::Tiny;

use namespace::autoclean;

sub BUILDARGS {
    my ($class, %attribute) = @_;

    my $lines_arrayref = $attribute{lines};

    # Needed 'cause init_arg does not work with Array trait.
    if (defined $lines_arrayref) {
        # Avoid use an external reference to store an attribute.
        $attribute{_lines} = dclone($lines_arrayref);

        delete $attribute{lines};
    }

    return \%attribute;
}

my $output = sub {
    my ($mode, $layer, $path, $lines_arrayref) = @_;

    open my $fh, $mode.$layer, $path or croak "Couldn't open $path: $!";
    $fh->autoflush(1);
    say $fh $_ for @{$lines_arrayref};
    close $fh or croak "Couldn't close $path: $!";
};

my $input = sub {
    my ($layer, $path) = @_;

    open my $fh, "<:$layer", $path or croak "Couldn't open $path: $!";
    my @lines =<$fh>;
    close $fh or croak "Couldn't close $path: $!";

    chomp @lines;

    return \@lines;
};

# TODO lines should not be in generic Sweet::File, but a C<content> attribute
has _lines => (
    builder => '_build_lines',
    handles => {
        add_lines => 'push',
        lines     => 'elements',
        line      => 'get',
        num_lines => 'count',
    },
    is     => 'lazy',
    isa    => 'ArrayRef[Str]',
    traits => ['Array'],
);

sub _build_lines {
    my $self = shift;

    my $encoding = $self->encoding;
    my $path     = $self->path;

    my $lines = $input->($encoding, $path);

    return $lines;
}

has dir => (
    coerce    => 1,
    is        => 'lazy',
    isa       => 'Sweet::Dir',
);

sub _build_dir {
    my $self = shift;

    my $path = $self->path;

    my $dirname = dirname($path);

    my $dir = Sweet::Dir->new(path => $dirname);

    return $dir;
}

# TODO see Encode::Supported
my @encodings = qw(utf8);

has encoding => (
    default  => sub { 'utf8' },
    is       => 'ro',
    isa      => enum(\@encodings),
    required => 1,
);

has name => (
    is      => 'lazy',
    isa     => 'Str',
);

sub _build_name {
    my $self = shift;

    my $path = $self->path;

    my $name = basename($path);

    return $name;
}

has name_without_extension => (
    default  => sub { ( fileparse( shift->path, qr/\.[^.]*$/ ) )[0] },
    init_arg => undef,
    is       => 'lazy',
    isa      => 'Str',
);

has extension => (
    is      => 'lazy',
    isa     => 'Str',
);

sub _build_extension {
    my $path = shift->path;

    my ($filename, $dirname, $suffix) = fileparse($path, qr/[^.]*$/);

    return $suffix;
}

has path => (
    coerce  => 1,
    is      => 'lazy',
    isa     => 'Path::Class::File',
);

sub _build_path {
    my $self = shift;

    my $name = $self->name;
    my $dir  = $self->dir;

    my $dir_path = $dir->path;

    my $path = File::Spec->catfile($dir_path, $name);

    return $path;
}

sub append {
    my ($self, $lines_arrayref) = @_;

    my @lines = @$lines_arrayref;

    $self->add_lines(@lines);

    my $encoding = $self->encoding;
    my $path     = $self->path;

    $output->('>>', $encoding, $path, $lines_arrayref);
}

sub move_to_dir {
    my ($self, $dir) = @_;

    $self->copy_to_dir($dir) && $self->erase;
}

sub copy_to_dir {
    my ($self, $dir) = @_;

    my $name = $self->name;

    my $class = $self->meta->name;

    my $file_copied = try {
        $class->new(dir => $dir, name => $name);
    }
    catch {
        croak $_;
    };

    my $source_path = $self->path;
    my $target_path = $file_copied->path;
    $dir = $file_copied->dir;

    try {
        $dir->is_a_directory or $dir->create;
    }
    catch {
        croak $_;
    };

    try {
        copy($source_path, $target_path);
    }
    catch {
        croak $_;
    };

    return $file_copied;
}

sub does_not_exists { !-e shift->path }

sub erase { remove(shift->path) }

sub has_zero_size { -z shift->path }

sub is_a_plain_file { -f shift->path }

sub is_executable { -x shift->path }

sub is_writable { -w shift->path }

sub split_line {
    my $self = shift;

    return sub {
        my $pattern = shift;

        # If pattern is a pipe, escape it.
        $pattern = '\|' if ($pattern eq '|');

        return sub {
            my $num_line = shift;

            my $line = $self->line($num_line);

            return split $pattern, $line;
          }
      }
}

sub write {
    my $self = shift;

    my $encoding = $self->encoding;
    my $lines_arrayref = $self->_lines;
    my $path     = $self->path;

    $output->('>', $encoding, $path, $lines_arrayref);
}

use overload q("") => sub { shift->path }, bool => sub { 1 }, fallback => 1;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Sweet::File

=head1 SYNOPSIS

    use Sweet::File;

    my $file1 = Sweet::File->new(
        dir => '/path/to/dir',
        name => 'foo',
    );

    my $file2 = Sweet::File->new(path => '/path/to/file');

=head1 ATTRIBUTES

=head2 dir

Instance of L<Sweet::Dir>. If not provided, depends on L</path>.

=head2 encoding

Defaults to C<utf8>.

=head2 extension

=head2 name

A string containing the file name. If not provided, depends on L</path>.

=head2 name_without_extension

=head2 path

Instance of L<Path::Class::File>. If not provided, depends on L</dir> and L</name>.

=head1 PRIVATE ATTRIBUTES

=head2 _lines

=head1 METHODS

=head2 append

Append lines to a file.

    my @lines = ('first appended line', 'second appended line');

    $file->append(\@lines);

=head2 copy_to_dir

Copy file to a directory.

    $file->copy_to_dir($dir);

Coerces path to L<Sweet::Dir>.

    $file->copy_to_dir('/path/to/dir');

Coerces C<ArrayRef> to L<Sweet::Dir>.

    $file->copy_to_dir(['/path/to', 'dir']);

=head2 does_not_exists

The negation of the C<-e> flag in natural language.

=head2 erase

Removes file, using L<File::Remove>.

    $file->erase

=head2 has_zero_size

The C<-z> flag in natural language.

    $file->has_zero_size

=head2 is_a_plain_file

The C<-f> flag in natural language.

    $file->is_a_plain_file

=head2 is_executable

The C<-x> flag in natural language.

    $file->is_executable

=head2 is_writable

The C<-w> flag in natural language.

    $file->is_writable

=head2 line

Returns the nth line.

    my $line1 = $file->line(0);
    my $line2 = $file->line(1);
    my $line3 = $file->line(2);

=head2 lines

    for my $line ( $file->lines ) {
        $line =~ s/foo/bar/;
        say $line;
    }

=head2 move_to_dir

Move file to a directory.

    $file->move_to_dir($dir);

It is just a shortcut to

    $file->copy_to_dir($dir) && $file->erase;

=head2 num_lines

    say $file->num_lines if $file->is_a_plain_file;

=head2 split_line

Get first line splitted on pipe.

    my @parts = $file->split_line->('|')->(0);

Split lines on comma.

    my $splitted_line = $file->split_line->(',');
    my @parts0 = $splitted_line->(0);
    my @parts1 = $splitted_line->(1);

=head2 write

Write lines to a brand new file.

    my @lines = ('first line', 'second line');

    my $file = Sweet::File->new(
        name => 'brand_new_file.txt',
        dir => $dir,
        lines => \@lines,
    );

    $file->write;

=head1 PRIVATE METHODS

=head2 _build_lines

The L</lines> builder. To be overridden in subclasses, if needed.
It opens a filehandle, put it in an array, L<chomp> it and returns the array reference.

=head2 _build_dir

The L</dir> builder. To be overridden in subclasses, if needed.

=head2 _build_name

The L</name> builder. To be overridden in subclasses, if needed.

=head2 _build_extension

The L</extension> builder. To be overridden in subclasses, if needed.

=head2 _build_path

The L</path> builder. To be overridden in subclasses, if needed.

=cut

