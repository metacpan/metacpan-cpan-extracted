# $Id: Attributes.pm,v 1.5 2001/05/16 01:38:01 btrott Exp $

package Net::SFTP::Attributes;
use strict;

use Net::SFTP::Constants qw( :att );
use Net::SFTP::Buffer;

use vars qw( @FIELDS );
@FIELDS = qw( flags size uid gid perm atime mtime );

for my $f (@FIELDS) {
    no strict 'refs';
    *$f = sub {
        my $a = shift;
        $a->{$f} = shift if @_;
        $a->{$f};
    };
}

sub new {
    my $class = shift;
    my $a = bless { }, $class;
    $a->init(@_);
}

sub init {
    my $a = shift;
    my %param = @_;
    for my $f (@FIELDS) {
        $a->{$f} = 0;
    }
    if (my $stat = $param{Stat}) {
        $a->{flags} |= SSH2_FILEXFER_ATTR_SIZE;
        $a->{size} = $stat->[7];
        $a->{flags} |= SSH2_FILEXFER_ATTR_UIDGID;
        $a->{uid} = $stat->[4];
        $a->{gid} = $stat->[5];
        $a->{flags} |= SSH2_FILEXFER_ATTR_PERMISSIONS;
        $a->{perm} = $stat->[2];
        $a->{flags} |= SSH2_FILEXFER_ATTR_ACMODTIME;
        $a->{atime} = $stat->[8];
        $a->{mtime} = $stat->[9];
    }
    elsif (my $buf = $param{Buffer}) {
        $a->{flags} = $buf->get_int32;
        if ($a->{flags} & SSH2_FILEXFER_ATTR_SIZE) {
            $a->{size} = $buf->get_int64;
        }
        if ($a->{flags} & SSH2_FILEXFER_ATTR_UIDGID) {
            $a->{uid} = $buf->get_int32;
            $a->{gid} = $buf->get_int32;
        }
        if ($a->{flags} & SSH2_FILEXFER_ATTR_PERMISSIONS) {
            $a->{perm} = $buf->get_int32;
        }
        if ($a->{flags} & SSH2_FILEXFER_ATTR_ACMODTIME) {
            $a->{atime} = $buf->get_int32;
            $a->{mtime} = $buf->get_int32;
        }
        if ($a->{flags} & SSH2_FILEXFER_ATTR_EXTENDED) {
            my $extended_count = $buf->get_int32;
            for (1..$extended_count) {
                my $name = $buf->get_str;
                my $value = $buf->get_str;
                $a->{$name} = $value;
            }
        }
    }
    $a;
}

sub as_buffer {
    my $a = shift;
    my $buf = Net::SFTP::Buffer->new;
    $buf->put_int32($a->{flags});
    if ($a->{flags} & SSH2_FILEXFER_ATTR_SIZE) {
        $buf->put_int64(int $a->{size});
    }
    if ($a->{flags} & SSH2_FILEXFER_ATTR_UIDGID) {
        $buf->put_int32($a->{uid});
        $buf->put_int32($a->{gid});
    }
    if ($a->{flags} & SSH2_FILEXFER_ATTR_PERMISSIONS) {
        $buf->put_int32($a->{perm});
    }
    if ($a->{flags} & SSH2_FILEXFER_ATTR_ACMODTIME) {
        $buf->put_int32($a->{atime});
        $buf->put_int32($a->{mtime});
    }
    $buf;
}

1;
__END__

=head1 NAME

Net::SFTP::Attributes - File/directory attribute container

=head1 SYNOPSIS

    use Net::SFTP::Attributes;
    my $attrs = Net::SFTP::Attributes->new(Stat => [ stat "foo" ]);
    my $size = $attrs->size;

=head1 DESCRIPTION

I<Net::SFTP::Attributes> encapsulates file/directory attributes
for I<Net::SFTP>. It also provides serialization and
deserialization methods to encode/decode attributes into
I<Net::SFTP::Buffer> objects.

=head1 USAGE

=head2 Net::SFTP::Attributes->new( [ %args ] )

Constructs a new I<Net::SFTP::Attributes> object and returns
that object.

I<%args> is optional; if not provided the object will be
initialized with the default values. If provided, I<%args>
can contain:

=over 4

=item * Stat

A reference to the return value of the built-in I<stat>
function. The values in the I<Net::SFTP::Attributes> object
will be initialized from the values in the I<stat> array,
and the flags will be set appropriately.

=item * Buffer

A I<Net::SFTP::Buffer> object containing a serialized
attribute object. The I<Net::SFTP::Attributes> object will
be initialized from the values in the serialized string,
and flags will be set appropriately.

=back

=head2 $attrs->as_buffer

Serializes the I<Attributes> object I<$attrs> into string
form, using the flags in the object to determine what fields
get placed in the buffer. Returns a I<Net::SFTP::Buffer>
object.

=head2 $attrs->flags( [ $value ] )

Get/set the value of the flags in I<$attrs>.

=head2 $attrs->size( [ $value ] )

Get/set the value of the file size (in bytes) in I<$attrs>.

=head2 $attrs->uid( [ $value ] )

Get/set the value of the UID in I<$attrs>.

=head2 $attrs->gid( [ $value ] )

Get/set the value of the GID in I<$attrs>.

=head2 $attrs->perm( [ $value ] )

Get/set the value of the permissions in I<$attrs>.

=head2 $attrs->atime( [ $value ] )

Get/set the value of the last access time (atime) in I<$attrs>.

=head2 $attrs->mtime( [ $value ] )

Get/set the value of the last modified time (mtime) in I<$attrs>.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SFTP manpage for author, copyright, and
license information.

=cut
