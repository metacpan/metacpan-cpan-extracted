package TPath::Forester::File::Node;
{
  $TPath::Forester::File::Node::VERSION = '0.003';
}

# ABSTRACT: represents file and its metadata


use v5.10;
use Moose;
require Fcntl;
use File::Spec;
use File::stat qw(stat_cando);
require Cwd;
require Encode;

use overload '""' => sub { shift->stringification };
use overload '<=>' => \&compare, 'cmp' => \&compare;


has real => ( is => 'ro', isa => 'Bool', required => 1, writer => '_real' );


has broken => ( is => 'ro', isa => 'Bool', default => 0, writer => '_broken' );


has name => ( is => 'ro', isa => 'Str', required => 1 );


has parent => (
    is       => 'ro',
    isa      => 'Maybe[TPath::Forester::File::Node]',
    weak_ref => 1,
    required => 1
);

has volume => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return $self->parent->volume;
    },
);

has children => (
    is      => 'ro',
    isa     => 'ArrayRef[TPath::Forester::File::Node]',
    lazy    => 1,
    builder => '_children'
);

has is_file => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return Fcntl::S_ISREG( $self->mode );
    },
);
has is_directory => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return Fcntl::S_ISDIR( $self->mode );
    },
);
has is_link => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return -l $self;
    },
);
has is_binary => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return -B $self;
    },
);
has is_text => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return -T $self;
    },
);
has is_empty => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return $self->size == 0;
    }
);
has not_empty => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return !$self->is_empty;
    }
);


has user => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_user' );

# memoized uid -> user converter
sub _user {
    my $self = shift;
    state %map;
    my $uid = $self->uid;
    my $user = $map{$uid} //= getpwuid($uid);
    return $user;
}


has group => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_group' );

# memoized gid -> group converter
sub _group {
    my $self = shift;
    state %map;
    my $gid = $self->gid;
    my $group = $map{$gid} //= getgrgid($gid);
    return $group;
}


has is_root => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return unless $self->real;
        return !defined $self->parent;
    }
);

has can_read => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { stat_cando( shift->stats, Fcntl::S_IRUSR, 1 ) }
);

has can_truly_read => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_can_truly_read',
);

sub _can_truly_read {
    my $self = shift;
    use filetest 'access';
    return -r $self;
}

has can_write => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { stat_cando( shift->stats, Fcntl::S_IWUSR, 1 ) }
);

has can_truly_write => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_can_truly_write'
);

sub _can_truly_write {
    my $self = shift;
    use filetest 'access';
    return -w $self;
}

has can_execute => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { stat_cando( shift->stats, Fcntl::S_IXUSR, 1 ) }
);

has can_truly_execute => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_can_truly_execute'
);

sub _can_truly_execute {
    my $self = shift;
    use filetest 'access';
    return -x $self;
}


has encoding =>
  ( is => 'ro', isa => 'Maybe[Str]', lazy => 1, builder => '_encoding' );

has encoding_detector => ( is => 'ro', isa => 'CodeRef', required => 1 );

sub _encoding {
    my $self = shift;
    return undef unless $self->is_file && $self->can_read && $self->is_text;
    eval { return $self->encoding_detector->detect($self) };
    return '';    # return empty string in case of an error
}

# build stat properties
{
    my $i = 0;
    for my $prop (
        qw(
        dev
        ino
        mode
        nlink
        uid
        gid
        rdev
        size
        atime
        mtime
        ctime
        blksize
        blocks
        )
      )
    {
        my $index = $i++;
        has $prop => (
            is      => 'ro',
            isa     => 'Int',
            lazy    => 1,
            default => sub {
                my $self = shift;
                return -1 unless $self->real;
                my $stats = $self->stats;
                return -1 unless $stats;
                return $stats->[$index];
            }
        );
    }
}


sub text {
    my $self = shift;
    unless ( $self->is_file ) {
        $@ = "$self not file";
        return;
    }
    unless ( $self->can_read ) {
        $@ = "$self not readable";
        return;
    }
    my $encoding = $self->encoding;
    if ($encoding) {
        my $data = $self->octets;
        return if $@;    # could not read
        eval { return Encode::decode( $encoding, $data ) };
        return if $@;
    }
    else {
        local $/;
        open my $fh, '<', "$self" or return;
        return <$fh>;
    }
}


sub octets {
    my $self = shift;
    unless ( $self->is_file ) {
        $@ = "$self is not a file";
        return;
    }
    unless ( $self->can_read ) {
        $@ = "$self is not readable";
        return;
    }
    local $/;
    open my $fh, '<', "$self" or $@ = "could not read from $self" && return;
    binmode $fh;
    my $data = <$fh>;
    return $data;
}


sub lines {
    my $self = shift;
    my $text = $self->text;
    return () unless $text;
    my @lines = $text =~ /^.*$/mg;
    return @lines;
}

has stats => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[Int]]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return undef unless $self->real;
        my $s;
        $s = [ stat $self->stringification ];
        undef $s unless @$s;
        $self->_real(0), $self->_broken(1) unless $s;
        return $s;
    }
);

has stringification =>
  ( is => 'ro', isa => 'Str', lazy => 1, builder => 'to_string' );

sub to_string {
    my $self = shift;
    return '"' . $self->name . '"' unless $self->real;
    my $p = $self->parent;
    return File::Spec->catfile( $p, $self->name ) if $p;
    return File::Spec->catfile( $self->volume, $self->name, '' );
}

sub _children {
    my $self = shift;
    return [] unless $self->real;
    return [] if $self->is_link || $self->broken;
    return [] unless $self->is_directory;
    if ( opendir my $dh, $self->stringification ) {
        my @children = File::Spec->no_upwards( readdir $dh );
        return [
            map {
                TPath::Forester::File::Node->new(
                    name              => $_,
                    parent            => $self,
                    real              => 1,
                    encoding_detector => $self->encoding_detector,
                  )
            } @children
        ];
    }
    $self->_broken(1);
    return [];
}

# linear search for a child of the same name
sub _find_child {
    my ( $self, $name ) = @_;
    for my $c ( @{ $self->children } ) {
        return $c if $c->name eq $name;
    }
    return undef;
}


sub compare {
    my ( $self, $other, $swapped ) = @_;
    return ( $swapped ? 1 : -1 )
      unless blessed $other && $other->isa('TPath::Forester::File::Node');
    return "$self" cmp "$other";
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

TPath::Forester::File::Node - represents file and its metadata

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use feature 'say';
  use TPath::Forester::File qw(tff);
  
  my $file = tff->wrap('some_file.txt');     # use wrap, not new
  my $text = $file->text;
  say $file->is_binary ? 'yes' : 'no';       # no  
  my @lines = $file->lines;

=head1 DESCRIPTION

L<TPath::Forester::File::Node> represents files as objects that know their place
in the directory tree. The class caches most file attributes -- not file contents.

=head1 ATTRIBUTES

=head2 real

Whether such a file exists in the file system. 

=head2 broken

True if C<stat> called on the file returns the empty list.

=head2 name

The file or directory's name.

=head2 parent

The file's basedir. This is also a L<TPath::Forester::File::Node>.

=head2 user

The user name corresonding to the file owner's uid.

=head2 group

The group name corresonding to the file's gid.

=head2 is_root

Whether this file represents the file system's root directory.

=head2 encoding

Character encoding lazily set using the node's C<encoding_detector>.

=head1 METHODS

=head2 text

Retrieves the file's text. Note: this is not an accessor; the file's text is not
stored but retrieved anew every time C<text> is invoked. If it is possible to
determine the file's encoding using L<Encode::Detect::Detector>, this character
set will be used for decoding.

If the file cannot be opened for reading, the method quietly returns, setting C<$@>
with an appropriate error message.

=head2 octets

Retrieve's the file's bytes. Note: this is not an accessor. Every time this method is
invoked the bytes are read anew from the file system.

If the file cannot be opened for reading, the method quietly returns, setting C<$@>
with an appropriate error message.

=head2 lines

Returns the files text, if it is a text file, as a list of lines minus endline characters.

=head2 compare($other, [$swapped])

Object comparison method. This method requires that the other be an object of type
L<TPath::Forester::File::Node>, sorting such objects before all else. Otherwise it
uses <cmp> on the stringification of the two objects.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
