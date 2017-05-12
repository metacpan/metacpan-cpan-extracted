package Repository::Simple::Engine::FileSystem;

use strict;
use warnings;

our $VERSION = '0.06';

use Carp;
use Repository::Simple;
use Repository::Simple::Engine qw( $NODE_EXISTS $PROPERTY_EXISTS $NOT_EXISTS );
use Repository::Simple::Permission;
use Repository::Simple::Type::Node;
use Repository::Simple::Type::Property;
use Repository::Simple::Util qw( dirname basename );
use File::Spec;
use IO::Scalar;
use Scalar::Util qw( weaken );
use Symbol;


use base 'Repository::Simple::Engine';

=head1 NAME

Repository::Simple::Engine::FileSystem - Native file system repository storage

=head1 SYNOPSIS

  use Repository::Simple;
  my $fs = Repository::Simple->attach('FileSystem', root => '/usr/local');

=head1 DESCRIPTION

This repository maps directly into the native file system. The goal is to make this mapping as direct as possible with very few deviations from native features and functionality.

As of this documentation, the storage engine is capable of handling only files and directories. Symlinks, devices, FIFOs, or any other kind of file type is partially handled, but the specifics functionality provided by these certainly isn't address completely.

=head1 OPTIONS

This file system module accepts only a single option, C<root>. If not given, the current working directory is assumed for the value C<root>. All files returned by the file system will be rooted at the given (or assumed) point. No file outside of that point is accessible.

=head1 NODE TYPES

There are three node types used by this engine:

=over

=item fs:object

This represents any non-file/non-directory file system object. The fs:file and fs:directory objects inherit from this. The stat properties are associated with this object.

=item fs:file

This represents a file object, i.e., anything that would pass the C<-f> test. This object has the stat properties plus the fs:content property associated with it.

=item fs:directory

This represents a directory object, i.e., anything that would pass the C<-d> test. This object has the stat properties associated with it. It may also have child nodes associated with it. The names and types of child nodes is not restricted.

=back

=head1 NODE PROPERTIES

All file system nodes have stat properties associated with them. These properties are populated by the return of the C<stat()> built-in subroutine. The stat properties are:

=over

=item fs:dev

device number of file system

=item fs:ino

inode number

=item fs:mode

file mode (type and permissions)

=item fs:nlink

number of (hard) links to the file

=item fs:uid

numeric user ID of file's owner

=item fs:gid

numeric group ID of file's owner

=item fs:rdev

the device identifier (special files only)

=item fs:size

total size of file, in bytes

=item fs:atime

last access time in seconds since the epoch

=item fs:mtime

last modify time in seconds since the epoch

=item fs:ctime

last change time in seconds since the epoch

=item fs:blksize

preferred block size for file system I/O

=item fs:blocks

actual number of blocks allocated

=back

The definitions were taken from the documentation in L<perlfunc>. Each of these will be an integer number. Once modification is implemented, the fs:mode, fs:uid, fs:gid, fs:atime, fs:mtime, and fs:ctime fields will be updatable. All other fields are not updatable. All of these fields are auto_created and all or not removable.

In addition to these properties, fs:file nodes also have an fs:content property, which will contain the file contents. You may wish to grab this data via the C<get_handle()> method rather than C<get_scalar()>.

=cut

my %namespaces = (
    fs => 'http://contentment.org/Repository/Simple/Engine/FileSystem',
);

my %node_type_defs = (
    'fs:object' => {
        name     => 'fs:object',
        property_types => {
            'fs:dev'     => 'fs:scalar-static',
            'fs:ino'     => 'fs:scalar-static',
            'fs:mode'    => 'fs:scalar',
            'fs:nlink'   => 'fs:scalar-static',
            'fs:uid'     => 'fs:scalar',
            'fs:gid'     => 'fs:scalar',
            'fs:rdev'    => 'fs:scalar-static',
            'fs:size'    => 'fs:scalar-static',
            'fs:atime'   => 'fs:scalar',
            'fs:mtime'   => 'fs:scalar',
            'fs:ctime'   => 'fs:scalar-static',
            'fs:blksize' => 'fs:scalar-static',
            'fs:blocks'  => 'fs:scalar-static',
        },
        updatable => 1,
        removable => 1,
    },

    'fs:file' => {
        name        => 'fs:file',
        super_types => [ qw( fs:object ) ],
        property_types => {
            'fs:content' => 'fs:handle',
        },
        updatable => 1,
        removable => 1,
    },

    'fs:directory' => {
        name        => 'fs:directory',
        super_types => [ qw( fs:object ) ],
        node_types => {
            '*' => [ 'fs:object' ],
        },
        updatable => 1,
        removable => 1,
    },
);

my %property_type_defs = (
    'fs:scalar' => {
        name         => 'fs:scalar',
        auto_created => 1,
        updatable    => 1,
        removable    => 0,
    },

    'fs:scalar-static' => {
        name         => 'fs:scalar-static',
        auto_created => 1,
        updatable    => 0,
        removable    => 0,
    },
    
    'fs:handle' => {
        name         => 'fs:handle',
        auto_created => 1,
        updatable    => 1,
        removable    => 0,
    },
);

my %stat_names = (
    'fs:dev'     => 0,
    'fs:ino'     => 1,
    'fs:mode'    => 2,
    'fs:nlink'   => 3,
    'fs:uid'     => 4,
    'fs:gid'     => 5,
    'fs:rdev'    => 6,
    'fs:size'    => 7,
    'fs:atime'   => 8,
    'fs:mtime'   => 9,
    'fs:ctime'   => 10,
    'fs:blksize' => 11,
    'fs:blocks'  => 12,
);

sub new {
	my $class = shift;
	my %args  = @_;

	$args{root} ||= '.';
	$args{root} = File::Spec->rel2abs($args{root});
	my $root = File::Spec->canonpath($args{root});

	-e $root or croak "Sorry, root $root does not exist!";
	-d $root or croak "Sorry, root $root is not a directory!";

	my $self = bless {
		fs_root  => $root,
	}, $class;

    while (my ($name, $node_def) = each %node_type_defs) {
        $self->{node_types}{$name}
            = Repository::Simple::Type::Node->new(
                engine => $self,
                %$node_def,
            );
    }

    while (my ($name, $prop_def) = each %property_type_defs) {
        $self->{property_types}{$name}
            = Repository::Simple::Type::Property->new(
                engine => $self,
                %$prop_def,
            );
    }

    return $self;
}

sub node_type_named {
    my ($self, $type_name) = @_;
    return $self->{node_types}{ $type_name };
}

sub property_type_named {
    my ($self, $type_name) = @_;
    return $self->{property_types}{ $type_name };
}

sub nodes_in {
    my ($self, $path) = @_;

    my $real_path = $self->real_path($path);
    
    $self->check_real_path($real_path, $path);

    if (!-d $real_path) {
        return ();
    }

    my $handle = gensym;
    opendir $handle, $real_path 
        or croak qq(failed to readdir for path "$path");
    my @dirs = grep { $_ !~ /^\.\.?$/ } readdir $handle;
    closedir $handle;

    return @dirs;
}

sub properties_in {
    my ($self, $path) = @_;

    my $real_path = $self->real_path($path);

    $self->check_real_path($real_path, $path);

    my @properties = keys %stat_names;

    if (-f $real_path) {
        push @properties, 'fs:content';
    }

    return @properties;
}

sub node_type_of {
    my ($self, $path) = @_;

    my $real_path = $self->real_path($path);

    $self->check_real_path($real_path, $path);

    if (-d $real_path) {
        return $self->{node_types}{'fs:directory'};
    }

    elsif (-f $real_path) {
        return $self->{node_types}{'fs:file'};
    }

    else {
        return $self->{node_types}{'fs:object'};
    }
}

sub property_type_of {
    my ($self, $path) = @_;

    my $basename = basename($path);
    my $dirname  = dirname($path);

    my $node_type = $self->node_type_of($dirname);
    my %property_types = $node_type->property_types;

    if (!defined $property_types{$basename}) {
        croak qq(no property named "$basename" for node "$dirname");
    }

    return $self->property_type_named($property_types{$basename});
}

sub path_exists {
	my ($self, $path) = @_;

    my $dirname  = dirname($path);
    my $basename = basename($path);

    my $real_path = $self->real_path($path);

    # If it is a node path, just find if it exists
    return $NODE_EXISTS if -e $real_path;

    # Next, check to see if it's a property
    my $property = $basename =~ m[
        fs:
            (?: dev     | ino     | mode  | nlink 
              | uid     | gid     | rdev  | size
              | atime   | mtime   | ctime | blksize 
              | blocks  | content )
    ]x;

    if ($property) {
        $real_path = $self->real_path($dirname);

        # fs:content exists only if the path is a file, the other properties
        # exist for both files or directories
        if ($basename eq 'fs:content') {
            return -f $real_path ? $PROPERTY_EXISTS : $NOT_EXISTS;
        }

        else {
            return -e $real_path ? $PROPERTY_EXISTS : $NOT_EXISTS;
        }
    }

    # Doesn't exist
    return $NOT_EXISTS;
}

sub _get_scalar {
    my ($self, $file, $property) = @_;

    return (stat $file)[ $stat_names{ $property } ];
}

sub _get_handle {
    my ($self, $dirname, $file, $mode) = @_;

    my $handle = gensym;
    open $handle, $mode, $file
        or croak qq(failed to open "fs:content" property of node ),
                 qq("$dirname" with mode "$mode");

    $self->{handles}{$dirname} = $handle;
    #weaken $self->{handles}{$dirname};

    return $handle;
}

sub get_scalar {
    my ($self, $path) = @_;

    my $basename = basename($path);
    my $dirname  = dirname($path);

    my $real_path = $self->real_path($dirname);

    $self->check_real_path($real_path, $dirname);

    if ($basename eq 'fs:content') {
        unless (-f $real_path) {
            croak qq(no "fs:content" property associated with node at ),
                  qq("$dirname");
        }

        my $handle = $self->_get_handle($dirname, $real_path, '<');
        my $scalar = join '', <$handle>;
        close $handle;

        return $scalar;
    }

    elsif (defined $stat_names{ $basename }) {
        return $self->_get_scalar($real_path, $basename);
    }

    else {
        croak qq(no "$basename" property associated with node at "$dirname");
    }
}

sub get_handle {
    my ($self, $path, $mode) = @_;

    $mode ||= '<';

#    if ($mode ne '<') {
#        croak qq(invalid mode "$mode" given);
#    }

    my $basename = basename($path);
    my $dirname  = dirname($path);

    my $real_path = $self->real_path($dirname);

    $self->check_real_path($real_path, $dirname);

    if ($basename eq 'fs:content') {
        if (!-f $real_path) {
            croak qq(no "fs:content" property associated with node at ),
                  qq("$dirname");
        }

        return $self->_get_handle($dirname, $real_path, $mode);
    }

    elsif (defined $stat_names{ $basename }) {
        my $scalar = $self->_get_scalar($real_path, $basename);
        return IO::Scalar->new(\$scalar);
    }

    else {
        croak qq(no "$basename" property associated with node at "$dirname");
    }
}

sub real_path {
    my ($self, $fs_path) = @_;

    return File::Spec->catfile($self->{fs_root}, $fs_path);
}

sub check_real_path {
    my ($self, $real_path, $path) = @_;

    if (!-e $real_path) {
        croak qq(no file found at path "$path");
    }
}

sub namespaces { return \%namespaces; }

my %ustat_props = (
    'fs:mode'  => 1,
    'fs:uid'   => 1,
    'fs:gid'   => 1,
    'fs:atime' => 1,
    'fs:mtime' => 1,
    'fs:ctime' => 1,
);

# TODO I think I've got this matching POSIX, but I'm surely wrong since I did
# this when I was half asleep and when I can't really remember the official
# POSIX standard on this anymore. I need to verify this is correct and then
# correct the heinous mistakes I've made.
sub has_permission {
    my ($self, $path, $action) = @_;

    my $pname = basename($path);
    my $real_path = $self->real_path($path);
    my $par_path = $self->real_path(dirname($path));
    my $dir_path = $self->real_path(dirname(dirname($path)));

    if ($action eq $ADD_NODE && -d $par_path && -w $par_path) {
        return 1;
    }

    if ($action eq $SET_PROPERTY && $ustat_props{$pname} && -w $dir_path) {
        return 1;
    }

    if ($action eq $SET_PROPERTY && $pname eq 'fs:content' && -w $par_path) {
        return 1;
    }

    if ($action eq $REMOVE && -e $real_path && -w $par_path) {
        return 1;
    }

    if ($action eq $READ && $pname eq 'fs:content' && -r $par_path) {
        return 1;
    }

    if ($action eq $READ && -d $real_path && -r $real_path && -x $real_path) {
        return 1;
    }

    if ($action eq $READ && -e $real_path && -r $real_path) {
        return 1;
    }

    if ($action eq $READ && defined $stat_names{$pname} && -r $dir_path) {
        return 1;
    }

    return 0;
}

sub set_scalar {
    my ($self, $path, $value) = @_;

    my $basename = basename($path);
    my $dirname  = dirname($path);

    my $real_path = $self->real_path($dirname);

    $self->check_real_path($real_path, $dirname);

    if ($basename eq 'fs:content') {
        unless (-f $real_path) {
            croak qq(no "fs:content" property associated with node at ),
                  qq("$dirname");
        }

        my $handle = $self->_get_handle($dirname, $real_path, '>');
        print $handle $value;
        close $handle;
    }

    elsif ($basename eq 'fs:mode') {
        chmod $value, $real_path
            or croak qq(Failed to change "$path" to "$value": $!);
    }

    elsif ($basename eq 'fs:uid') {
        my $gid = $self->_get_scalar($real_path, 'fs:gid');
        chown $value, $gid, $real_path
            or croak qq(Failed to change "$path" to "$value": $!);
    }

    elsif ($basename eq 'fs:gid') {
        my $uid = $self->_get_scalar($real_path, 'fs:uid');
        chown $uid, $value, $real_path
            or croak qq(Failed to change "$path" to "$value": $!);
    }

    elsif ($basename eq 'fs:atime') {
        my $mtime = $self->_get_scalar($real_path, 'fs:mtime');
        utime $value, $mtime, $real_path
            or croak qq(Failed to change "$path" to "$value": $!);
    }

    elsif ($basename eq 'fs:mtime') {
        my $atime = $self->_get_scalar($real_path, 'fs:atime');
        utime $atime, $value, $real_path
            or croak qq(Failed to change "$path" to "$value": $!);
    }

    else {
        croak qq(property "$basename" is static or does not exist for ),
              qq("$dirname" );
    }
}

sub set_handle {
    my ($self, $path, $handle) = @_;

    # TODO This is cheating and should be done better
    my $value = join '', readline($handle);
    $self->set_scalar($path, $value);
}

sub save_property {
    my ($self, $path) = @_;

    my $dirname = dirname($path);

    # Check for a file handle at the given path; close it if found
    if (defined $self->{handles}{$dirname}) {
        my $handle = delete $self->{handles}{$dirname};
        close $handle;
    }
}

=head1 SEE ALSO

L<Repository::Simple>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
