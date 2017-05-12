package Net::SFTP::Server::Buffer;

use strict;
use warnings;
use Carp;

use Encode;
use Net::SFTP::Server::Constants qw(:filexfer);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw( buf_shift_uint32
                  buf_shift_uint64
		  buf_shift_uint8
		  buf_shift_str
		  buf_shift_utf8
		  buf_shift_attrs

		  buf_push_uint32
                  buf_push_uint64
		  buf_push_uint8
		  buf_push_str
		  buf_push_utf8
		  buf_push_attrs
                  buf_push_name
		  buf_push_raw );

use constant HAS_QUADS => do {
    local $@;
    local $SIG{__DIE__};
    no warnings;
    eval q{
        pack(Q => 0x1122334455667788) eq "\x11\x22\x33\x44\x55\x66\x77\x88"
    }
};


sub buf_shift_uint8 { unpack C => substr($_[0], 0, 1, '') }

sub buf_shift_uint32 { unpack N => substr($_[0], 0, 4, '') }

sub buf_shift_uint64_quads { unpack Q => substr(${$_[0]}, 0, 8, '') }

sub buf_shift_uint64_no_quads {
    length $_[0] >= 8 or return;
    my ($big, $small) = unpack(NN => substr($_[0], 0, 8, ''));
    if ($big) {
	# too big for an integer, try to handle it as a float:
	my $high = $big * 4294967296;
	my $result = $high + $small;
	unless ($result - $high == $small) {
	    # too big event for a float, use a BigInt;
	    require Math::BigInt;
	    $result = Math::BigInt->new($big);
	    $result <<= 32;
	    $result += $small;
	}
	return $result;
    }
    return $small;
}

BEGIN {
    *buf_shift_uint64 = (HAS_QUADS
			 ? \&buf_shift_uint64_quads
			 : \&buf_shift_uint64_no_quads);
}

sub buf_shift_str {
    if (my ($len) = unpack N => substr($_[0], 0, 4, '')) {
	return substr($_[0], 0, $len, '')
	    if (length $_[0] >= $len);
    }
    ()
}

sub buf_shift_utf8 {
    if (my ($len) = unpack N => substr($_[0], 0, 4, '')) {
	return Encode::decode(utf8 => substr($_[0], 0, $len, ''))
	    if (length $_[0] >= $len);
    }
    ()
}

sub buf_shift_attrs {
    my %attrs;
    my ($flags) = buf_shift_uint32($_[0]) or return;
    if ($flags & SSH_FILEXFER_ATTR_SIZE) {
	($attrs{size}) = buf_shift_uint64($_[0]) or return;
    }
    if ($flags & SSH_FILEXFER_ATTR_UIDGID) {
	($attrs{uid}) = buf_shift_uint32($_[0]) or return;
	($attrs{gid}) = buf_shift_uint32($_[0]) or return;
    }
    if ($flags & SSH_FILEXFER_ATTR_PERMISSIONS) {
	($attrs{permissions}) = buf_shift_uint32($_[0]) or return;
    }
    if ($flags & SSH_FILEXFER_ATTR_ACMODTIME) {
	($attrs{atime}) = buf_shift_uint32($_[0]) or return;
	($attrs{mtime}) = buf_shift_uint32($_[0]) or return;
    }
    if ($flags & SSH_FILEXFER_ATTR_EXTENDED) {
	my ($count) = buf_shift_uint32($_[0]) or return;
	my @ext;
	for (1..(2*$count)) {
	    my ($str) = buf_shift_str($_[0]) or return;
	    push @ext, $str;
	}
	$attrs{extended} = \@ext;
    }
    \%attrs;
}

sub buf_push_uint8 { $_[0] .= pack(C => int $_[1]) }

sub buf_push_uint32 { $_[0] .= pack(N => int $_[1]) }

sub buf_push_uint64_quads { $_[0] .= pack(Q => int $_[1]) }

sub buf_push_uint64_no_quads {
    my $high = int ( $_[1] / 4294967296);
    $_[0] .= pack(NN => $high, int ($_[1] - $high * 4294967296));
}

BEGIN {
    *buf_push_uint64 = (HAS_QUADS
			? \&buf_push_uint64_quads
			: \&buf_push_uint64_no_quads);
}

sub buf_push_str  {
    utf8::downgrade($_[1]) or croak "unable to pack UTF8 data";
    $_[0] .= pack(N => length $_[1]);
    $_[0] .= $_[1];
}

sub buf_push_utf8 {
    my $octets = Encode::encode(utf8 => $_[1]);
    $_[0] .= pack(N => length $octets);
    $_[0] .= $octets;

}

sub buf_push_attrs {
    my $attrs = $_[1];
    my $b = '';
    my $flags;
    ref $attrs eq 'HASH' or croak "Internal error";
    if (%$attrs) {
	if (defined $attrs->{size}) {
	    $flags |= SSH_FILEXFER_ATTR_SIZE;
	    buf_push_uint64($b, $attrs->{size});
	}
	
	if (defined $attrs->{uid} and defined $attrs->{gid}) {
	    $flags |= SSH_FILEXFER_ATTR_UIDGID;
	    buf_push_uint32($b, $attrs->{uid});
	    buf_push_uint32($b, $attrs->{gid});
	}
	elsif (defined $attrs->{uid} or defined $attrs->{gid}) {
	    croak "Internal error: invalid attributes specification, uid and gid go together";
	}

	if (defined $attrs->{permissions}) {
	    $flags |= SSH_FILEXFER_ATTR_PERMISSIONS;
	    buf_push_uint32($b, $attrs->{permissions});
	}

	if (defined $attrs->{atime} and defined $attrs->{mtime}) {
	    $flags |= SSH_FILEXFER_ATTR_ACMODTIME;
	    buf_push_uint32($b, $attrs->{atime});
	    buf_push_uint32($b, $attrs->{mtime});
	}
	elsif (defined $attrs->{atime} or defined $attrs->{mtime}) {
	    croak "Internal error: invalid attributes specification, atime and mtime go together";
	}

	my $extended = $attrs->{extended};
	$flags |= SSH_FILEXFER_ATTR_EXTENDED if defined $extended;

	buf_push_uint32 $_[0], $flags;
	$_[0] .= $b;
	if (defined $extended) {
	    if (ref $extended eq 'HASH') {
		$extended = [%$extended];
	    }
	    if (ref $extended eq 'ARRAY') {
		@$extended & 1 and croak "Internal error: odd number of extension fields";
		buf_push_uint32($_[0], @$extended / 2);
		buf_push_str($_[0], $_) for @$extended;
	    }
	    else {
		croak "Internal error: extended field is not an ARRAY reference";
	    }
	}
    }
    else {
	# optimization for the common send-nothing
	buf_push_uint32($_[0], 0);
    }
}

sub buf_push_name {
    my $name = $_[1];
    ref $name eq 'HASH' or croak "Internal error: name is not a HASH ref";
    buf_push_str($_[0], $name->{filename} // '');
    buf_push_str($_[0], $name->{longname} // '');
    my $attrs = $name->{attrs};
    ($attrs and %$attrs) ? buf_push_attrs($_[0], $attrs) :  buf_push_uint32($_[0], 0);
}

sub buf_push_raw {
    utf8::downgrade($_[1]);
    $_[0] .= $_[1];
}



1;
