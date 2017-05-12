use MooseX::Declare;
use Fuse;

{ package MooseX::Runnable::Fuse; # For PAUSE
  our $VERSION = 0.02;
}

role Filesystem::Fuse::Readable {
    use MooseX::Types::Moose qw(HashRef ArrayRef Defined Int);
    use MooseX::Types::Path::Class qw(File Dir);
    use POSIX qw(ENOENT EISDIR);

    require MooseX::Getopt;

    has 'open_files' => (
        traits    => ['NoGetopt'],
        is        => 'ro',
        isa       => HashRef[HashRef[Defined]],
        default   => sub { {} },
        required  => 1,
    );

    requires 'getattr';
    requires 'readlink';
    requires 'getdir';
    requires 'read';
    requires 'statfs';
    requires 'file_exists';

    method open(File $file does coerce, Int $flags){
	return -ENOENT() unless $self->file_exists($file);
	return -EISDIR() if [$self->getattr($file)]->[3] & 0040;
        $self->open_files->{$file->stringify}{$flags} = 1;
        return 0;
    }

    method flush(File $file does coerce) {
        return 0;
    }

    method release(File $file does coerce, Int $flags){
        delete $self->open_files->{$file->stringify}{$flags};
        delete $self->open_files->{$file->stringify} if
          keys %{$self->open_files->{$file->stringify}} < 1;
        return 0;
    }
}

role Filesystem::Fuse::Writable with Filesystem::Fuse::Readable {
    requires 'mknod';
    requires 'mkdir';
    requires 'unlink';
    requires 'rmdir';
    requires 'symlink';
    requires 'rename';
    requires 'link';
    requires 'chmod';
    requires 'chown';
    requires 'truncate';
    requires 'utime';
    requires 'write';
    requires 'fsync';
}

role Filesystem::Fuse::Attributes::Readable {
    requires 'getxattr';
    requires 'listxattr';
}

role Filesystem::Fuse::Attributes::Writable
  with Filesystem::Fuse::Attributes::Readable {
    requires 'setxattr';
    requires 'removexattr';
}

role MooseX::Runnable::Fuse with MooseX::Getopt with MooseX::Runnable {

    use MooseX::Types::Moose qw(Bool Str);
    use MooseX::Types::Path::Class qw(Dir);

    has 'mountpoint' => (
        is       => 'ro',
        isa      => Dir,
        required => 1,
        coerce   => 1,
    );

    has 'mountopts' => (
        is       => 'ro',
        isa      => Str,
        default  => sub { "" },
        required => 0,
    );

    has 'debug' => (
        init_arg => 'debug',
        reader   => 'is_debug',
        isa      => Bool,
        default  => sub { 0 },
        required => 1,
    );

    method run {
        my $class = $self->meta;
        my @method_map;

        my $subify = sub {
            my $method = shift;
            return sub { $self->$method(@_) };
        };

        if($class->does_role('Filesystem::Fuse::Readable')){
            push @method_map, map { $_ => $subify->($_) } qw{
                getattr readlink getdir open read
                release statfs flush
            };
        }

        if($class->does_role('Filesystem::Fuse::Writable')){
            push @method_map, map { $_ => $subify->($_) } qw{
                mknod mkdir unlink rmdir symlink rename link
                chmod chown truncate utime write fsync
            };
        }

        if($class->does_role('Filesystem::Fuse::Attributes::Readable')){
            push @method_map, map { $_ => $subify->($_) } qw{
                getxattr listxattr
            };
        }

        if($class->does_role('Filesystem::Fuse::Attributes::Writable')){
            push @method_map, map { $_ => $subify->($_) } qw{
                setxattr removexattr
            };
        }

        return Fuse::main( # no idea what the return value actually means
            debug      => $self->is_debug ? 1 : 0,
            mountpoint => $self->mountpoint->stringify,
            mountopts  => $self->mountopts,
            @method_map,
        ) || 0;

    }
}

1;

__END__

=head1 NAME

MooseX::Runnable::Fuse - implement a FUSE filesystem as a Moose class

=head1 SYNOPSIS

    use MooseX::Declare;

    class Filesystem with MooseX::Runnable::Fuse
                     with Filesystem::Fuse::Readable {
        use MooseX::Types::Path::Class qw(File);

        method getattr(File $file does coerce){
            ...
            return (0, 0, ...);
        }

        ...
    }

From the command-line:

    mx-run Filesystem --mountpoint /mnt/filesystem --debug # or omit --debug

=head1 DESCRIPTION

This role allows you to make a class into a runnable (via
L<MooseX::Runnable|MooseX::Runnable> Fuse filesystem.  You also get
four other roles to help this module determine how to run your
filesystem; C<Filesystem::Fuse::Readable>,
C<Filesystem::Fuse::Writable>,
C<Filesystem::Fuse::Attributes::Readable>, and
C<Filesystem::Fuse::Attributes::Writable>.  Composing these roles into
your class will ensure that you implement the correct methods to get
the functionality you desire.

=head1 METHODS

=head2 run

Start a process implementing the filesystem, mount the filesystem.

=head1 SEE ALSO

L<Fuse>

L<MooseX::Runnable> (for details on the C<MooseX::Runnable> framework)

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

This module is free software, you may redistribute it under the same
terms as Perl itself.
