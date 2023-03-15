package Mojo::Tar::File;
use Mojo::Base -base, -signatures;

use Carp         qw(croak);
use Exporter     qw(import);
use Mojo::File   ();
use Scalar::Util qw(blessed);

use constant DEBUG => !!$ENV{MOJO_TAR_DEBUG};

our $GID = $( =~ /(\d+)/ && int($1) || 0;
our ($PACK_FORMAT, @EXPORT);

BEGIN {
  $PACK_FORMAT = q(
    a100 # pos=0   name=name      desc=file name (chars)
    a8   # pos=100 name=mode      desc=file mode (octal)
    a8   # pos=108 name=uid       desc=uid (octal)
    a8   # pos=116 name=gid       desc=gid (octal)
    a12  # pos=124 name=size      desc=size (octal)
    a12  # pos=136 name=mtime     desc=mtime (octal)
    a8   # pos=148 name=checksum  desc=checksum (octal)
    a1   # pos=156 name=type      desc=type
    a100 # pos=157 name=symlink   desc=file symlink destination (chars)
    A6   # pos=257 name=ustar     desc=ustar
    a2   # pos=263 name=ustar_ver desc=ustar version (00)
    a32  # pos=265 name=owner     desc=owner user name (chars)
    a32  # pos=297 name=group     desc=owner group name (chars)
    a8   # pos=329 name=dev_major desc=device major number
    a8   # pos=337 name=dev_minor desc=device minor number
    a155 # pos=345 name=prefix    desc=file name prefix
    a12  # pos=500 name=padding   desc=padding (\0)
  );

  # Generate constants:
  # TAR_USTAR_NAME_LEN       TAR_USTAR_NAME_POS
  # TAR_USTAR_MODE_LEN       TAR_USTAR_MODE_POS
  # TAR_USTAR_UID_LEN        TAR_USTAR_UID_POS
  # TAR_USTAR_GID_LEN        TAR_USTAR_GID_POS
  # TAR_USTAR_SIZE_LEN       TAR_USTAR_SIZE_POS
  # TAR_USTAR_MTIME_LEN      TAR_USTAR_MTIME_POS
  # TAR_USTAR_CHECKSUM_LEN   TAR_USTAR_CHECKSUM_POS
  # TAR_USTAR_TYPE_LEN       TAR_USTAR_TYPE_POS
  # TAR_USTAR_SYMLINK_LEN    TAR_USTAR_SYMLINK_POS
  # TAR_USTAR_USTAR_LEN      TAR_USTAR_USTAR_POS
  # TAR_USTAR_USTAR_VER_LEN  TAR_USTAR_USTAR_VER_POS
  # TAR_USTAR_OWNER_LEN      TAR_USTAR_OWNER_POS
  # TAR_USTAR_GROUP_LEN      TAR_USTAR_GROUP_POS
  # TAR_USTAR_DEV_MAJOR_LEN  TAR_USTAR_DEV_MAJOR_POS
  # TAR_USTAR_DEV_MINOR_LEN  TAR_USTAR_DEV_MINOR_POS
  # TAR_USTAR_PREFIX_LEN     TAR_USTAR_PREFIX_POS
  # TAR_USTAR_PADDING_LEN    TAR_USTAR_PADDING_POS
  for my $line (split /\n/, $PACK_FORMAT) {
    my ($len, $pos, $name) = $line =~ /(\d+)\W+pos=(\d+)\W+name=(\w+)/ or next;

    my $const = uc "TAR_USTAR_${name}_LEN";
    constant->import($const => $len);
    push @EXPORT, $const;

    $const = uc "TAR_USTAR_${name}_POS";
    constant->import($const => $pos);
    push @EXPORT, $const;
  }
}

has asset => sub ($self) {Mojo::File::tempfile};
has checksum =>
  sub ($self) { substr $self->to_header, TAR_USTAR_CHECKSUM_POS, TAR_USTAR_CHECKSUM_LEN };
has dev_major   => '';
has dev_minor   => '';
has gid         => sub ($self) { $self->_stat('gid')  || $GID };
has group       => sub ($self) { getgrgid($self->gid) || '' };
has is_complete => sub ($self) { $self->_stat('size') == $self->size ? 1 : 0 };
has mode        => sub ($self) { ($self->_stat('mode') || 0) & 0777 };
has mtime       => sub ($self) { $self->_stat('mtime')   || time };
has owner       => sub ($self) { getpwuid($self->uid)    || '' };
has path        => sub ($self) { $self->asset->to_string || '' };
has size        => sub ($self) { $self->_stat('size')    || 0 };
has symlink     => '';
has type        => sub ($self) { $self->_build_type };
has uid         => sub ($self) { $self->_stat('uid') || $( };

sub add_block ($self, $block) {
  return $self unless $self->type eq 0;

  $self->{bytes_added} //= 0;
  my $chunk = substr $block, 0, $self->size - $self->{bytes_added};
  $self->{bytes_added} += length $chunk;
  croak 'File size is out of range' if $self->{bytes_added} > $self->size;

  my $handle = $self->{add_block_handle} //= $self->asset->open('>');
  ($handle->syswrite($chunk) // -1) == length $chunk or croak "Can't write to asset: $!";
  $self->is_complete(1)->_cleanup if $self->{bytes_added} == $self->size;

  warn sprintf "[tar:add_block] chunk=%s/%s size=%s/%s is_complete=%s path=%s\n", length($chunk),
    length($block), $self->{bytes_added}, $self->size, $self->is_complete, $self->path
    if DEBUG;

  return $self;
}

sub from_header ($self, $header) {
  my @fields   = unpack $PACK_FORMAT, $header;
  my $checksum = $self->_checksum($header);

  my ($prefix, $path) = map { _trim_nul($fields[$_]) } 15, 0;
  $path = Mojo::File->new($prefix, $path)->to_string if length $prefix;

  $self->path($path);
  $self->mode(_from_oct($fields[1]));
  $self->uid(_from_oct($fields[2]));
  $self->gid(_from_oct($fields[3]));
  $self->size(_from_oct($fields[4]));
  $self->mtime(_from_oct($fields[5]));
  $self->checksum($checksum eq $fields[6] =~ s/\0\s$//r ? $checksum : '');
  $self->type($fields[7] eq "\0"                        ? '0'       : $fields[7]);
  $self->symlink(_trim_nul($fields[8]));
  $self->owner(_trim_nul($fields[11]));
  $self->group(_trim_nul($fields[12]));
  $self->dev_major($fields[13]);
  $self->dev_minor($fields[14]);

  warn sprintf
    "[tar:from_header] path=%s mode=%s uid=%s gid=%s size=%s mtime=%s checksum=%s type=%s symlink=%s owner=%s group=%s\n",
    map { $self->$_ } qw(path mode uid gid size mtime checksum type symlink owner group)
    if DEBUG;

  return $self;
}

sub to_header ($self) {
  my ($name, $prefix) = (Mojo::File->new($self->path), '');
  ($name, $prefix) = ($name->basename, $name->dirname->to_string) if length($name) > 100;
  croak qq(path "@{[$self->path]}" is too long) if length($name) > 100 or length($prefix) > 155;

  my $header = pack $PACK_FORMAT, $name,    # 0
    sprintf('%06o ',  $self->mode),         # 1
    sprintf('%06o ',  $self->uid),          # 2
    sprintf('%06o ',  $self->gid),          # 3
    sprintf('%011o ', $self->size),         # 4
    sprintf('%011o ', $self->mtime),        # 5
    '',                                     # 6 - checksum
    $self->type,                            # 7
    $self->symlink,                         # 8
    "ustar\0",                              # 9 - ustar
    '00',                                   # 10 - ustar version
    $self->owner,                           # 11
    $self->group,                           # 12
    sprintf('%07s', $self->dev_major),      # 13
    sprintf('%07s', $self->dev_minor),      # 14
    $prefix,                                # 15
    '';                                     # 16 - padding

  # Inject checksum
  substr $header, TAR_USTAR_CHECKSUM_POS, TAR_USTAR_CHECKSUM_LEN, $self->_checksum($header) . "\0 ";

  return $header;
}

sub _build_type ($self) {
  return '0' unless my $asset = $self->{asset};
  return '0' if -f $asset;                  # plain file
  return '1' if -l _;                       # symlink
  return '3' if -c _;                       # char dev
  return '4' if -b _;                       # block dev
  return '5' if -d _;                       # directory
  return '6' if -p _;                       # pipe
  return '8' if -s _;                       # socket
  return '2' if $asset->stat->nlink > 1;    # hard link
  return '9';                               # unknown
}

sub _checksum ($self, $header) {
  return sprintf '%06o', int unpack '%16C*', join '        ',
    substr($header, 0, TAR_USTAR_CHECKSUM_POS), substr($header, TAR_USTAR_TYPE_POS);
}

sub _cleanup ($self) {
  my $handle = delete $self->{add_block_handle};
  $handle->close if $handle;
}

sub _from_oct ($str) {
  $str =~ s/^0+//;
  $str =~ s/[\s\0]+$//;
  return length($str) ? oct $str : 0;
}

sub _stat ($self, $field) {
  return undef unless my $stat = $self->{stat} //= $self->{asset} && $self->{asset}->stat || 0;
  return $stat->$field;
}

sub _trim_nul ($str) {
  my $idx = index $str, "\0";
  return $idx == -1 ? $str : substr $str, 0, $idx;
}

sub DESTROY ($self) { $self->_cleanup }

1;

=encoding utf8

=head1 NAME

Mojo::Tar::File - A Mojo::Tar file

=head1 SYNOPSIS

  my $file = Mojo::Tar->new(path => 'some/file.txt');

  # This can be dangerous! Make sure path() does not contain ".."
  # or other dangerous path parts.
  $file->asset->move_to($file->path);

=head1 DESCRIPTION

L<Mojo::Asset::File> represents a tar file.

=head1 ATTRIBUTES

=head2 asset

  $file = $file->asset(Mojo::File->new);
  $asset = $file->asset;

Returns a L<Mojo::File> object. Defaults to L<Mojo::File/tempfile>.

This attribute is currently EXPERIMENTAL, but unlikely to change.

=head2 checksum

  $str = $file->checksum;

Holds the checksum read by L</from_header> or contains empty string if
the checksum does not match. This attribute can also be built from all the
attributes if L</from_header> was not called.

=head2 dev_major

This attribute is not supported yet. Pull request welcome!

=head2 dev_minor

This attribute is not supported yet. Pull request welcome!

=head2 gid

  $file = $file->gid(1001);
  $int = $file->gid;

The numeric representation of L</group>.

=head2 group

  $file = $file->group('users')
  $str = $file->group;

The string representation of L</gid>.

=head2 is_complete

  $bool = $file->is_complete;

Returns true if L</add_block> has added enough blocks to match L</size>.

=head2 mode

  $file = $file->mode(0644); # 0644 == 420
  $int = $file->mode;

The file mode. Note that this is 10-base, meaning C<$int> will be something
like "420" and not "644".

=head2 mtime

  $file = $file->mtime(time);
  $epoch = $file->mtime;

Epoch timestamp for this file.

=head2 owner

  $file = $file->owner('jhthorsen')
  $str = $file->owner;

The string representation of L</uid>.

=head2 path

  $file = $file->path('some/file/or/directory');
  $str = $file->path;

The path from the tar file. This is constructed with both the filename and
prefix (if any) in the ustar tar format.

=head2 size

  $file = $file->size(42);
  $int = $file->size;

The size of the file in bytes.

=head2 symlink

  $file = $file->symlink('path/for/symlink');
  $str = $file->symlink;

This attribute is not fully supported yet. Pull request welcome!

=head2 type

  $file = $file->type(5);
  $str = $file->type;

The tar file type.

This attribute is currently EXPERIMENTAL and might change from raw
representation to something more readable.

=head2 uid

  $file = $file->uid(1001);
  $int = $file->uid;

The numeric representation of L</owner>.

=head1 METHODS

=head2 add_block

  $file = $file->add_block($bytes);

Used to add a block from of bytes from the tar file to the L</asset>.

=head2 from_header

  $file = $file->from_header($bytes);

Will parse the header chunk from the tar file and set the L</ATTRIBUTES>.

=head2 to_header

  $bytes = $file->to_header;

Will construct a header chunk from the L</ATTRIBUTES>.

=head1 SEE ALSO

L<Mojo::Tar>.

=cut
