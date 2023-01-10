package PerlIO::via::xz;

use 5.012000;
use warnings;

use PerlIO;
use IO::Compress::Xz     qw( $XzError   );
use IO::Uncompress::UnXz qw( $UnXzError );
#use Data::Peek;
use Carp;

our $VERSION = "0.05";

sub import {
    my ($class, %args) = @_;

#DDumper { import => \@_ };
    } # import

# $class->PUSHED ([$mode, [$fh]])
#   Should return an object or the class, or -1 on failure.  (Compare
#   TIEHANDLE.)  The arguments are an optional mode string ("r", "w",
#   "w+", ...) and a filehandle for the PerlIO layer below.  Mandatory.
#
#   When the layer is pushed as part of an "open" call, "PUSHED" will be
#   called before the actual open occurs, whether that be via "OPEN",
#   "SYSOPEN", "FDOPEN" or by letting a lower layer do the open.
sub PUSHED {
    my ($class, $mode, $fh) = @_;

#DDumper { PUSHED => \@_ };
    $mode =~ m/^[wr]$/ or return 1;
    my $self = {
	mode  => $mode,		# "r" or "w"
	fh    => undef,
	level => 9,		# Not yet settable
	bsz   => 4096,		# Not yet settable
	xz    => undef,
	};
    return bless $self => $class;
    } # PUSHED

sub FILENO {
    my ($self, $fh) = @_;
#DDumper { FILENO => \@_ };
    unless (defined $self->{xz}) {
	$self->{fh}     = $fh;
	$self->{fileno} = fileno $fh;
	if ($self->{mode} eq "r") {
	    my $in  = $fh;
	    $self->{xz} = IO::Uncompress::UnXz->new ($in,
		BlockSize => $self->{bsz},
		) or croak "Something went wrong in new (): $UnXzError";
	    }
	else {
	    my $out = $fh;
	    $self->{xz} = IO::Compress::Xz->new ($out,
		AutoClose => 1,
		Preset    => $self->{level},
		) or croak "Something went wrong in new (): $XzError";
	    $self->{xz}->autoflush (1);
	    }
	}
#DDumper $self;
    $self->{fileno};
    } # FILENO

# $obj->POPPED ([$fh])
#   Optional - called when the layer is about to be removed.
#
# $obj->UTF8 ($belowFlag, [$fh])
#   Optional - if present it will be called immediately after PUSHED
#   has returned. It should return a true value if the layer expects
#   data to be UTF-8 encoded. If it returns true, the result is as if
#   the caller had done
#
#        ":via(YourClass):utf8"
#
#   If not present or if it returns false, then the stream is left with
#   the UTF-8 flag clear.  The $belowFlag argument will be true if
#   there is a layer below and that layer was expecting UTF-8.
#
# $obj->OPEN ($path, $mode, [$fh])
#   Optional - if not present a lower layer does the open.  If present,
#   called for normal opens after the layer is pushed.  This function
#   is subject to change as there is no easy way to get a lower layer
#   to do the open and then regain control.
#
# $obj->BINMODE ([$fh])
#   Optional - if not present the layer is popped on binmode ($fh) or
#   when ":raw" is pushed. If present it should return 0 on success, -1
#   on error, or undef to pop the layer.
#
# $obj->FDOPEN ($fd, [$fh])
#   Optional - if not present a lower layer does the open.  If present,
#   called after the layer is pushed for opens which pass a numeric
#   file descriptor.  This function is subject to change as there is no
#   easy way to get a lower layer to do the open and then regain control.
#
# $obj->SYSOPEN ($path, $imode, $perm, [$fh])
#   Optional - if not present a lower layer does the open.  If present,
#   called after the layer is pushed for sysopen style opens which pass
#   a numeric mode and permissions.  This function is subject to change
#   as there is no easy way to get a lower layer to do the open and
#   then regain control.
#
# $obj->FILENO ($fh)
#   Returns a numeric value for a Unix-like file descriptor. Returns -1
#   if there isn't one.  Optional.  Default is fileno ($fh).
#
# $obj->READ ($buffer, $len, $fh)
#   Returns the number of octets placed in $buffer (must be less than
#   or equal to $len).  Optional.  Default is to use FILL instead.
#
# $obj->WRITE ($buffer, $fh)
#   Returns the number of octets from $buffer that have been
#   successfully written.
sub WRITE {
    my ($self, $buf, $fh) = @_;

#DDumper { WRITE => \@_ };
    return $self->{xz}->write ($buf);
    } # WRITE

# $obj->FILL ($fh)
#   Should return a string to be placed in the buffer.  Optional. If
#   not provided, must provide READ or reject handles open for reading
#   in PUSHED.
sub FILL {
    my ($self, $fh) = @_;

#DDumper { FILL => \@_ };
    my $data = $self->{xz}->getline;
#DDumper { data => $data };
    return $data;
    } # FILL

# $obj->CLOSE ($fh)
#   Should return 0 on success, -1 on error.  Optional.
sub CLOSE {
    my ($self, $fh) = @_;
#DDumper { CLOSE => \@_ };

    ref $self && $self->{xz} or return -1;
    $self->{xz}->flush;
    $self->{xz}->close;
    return ($fh ? $fh->close : 0);
    } # CLOSE

# $obj->SEEK ($posn,$whence,$fh)
#   Should return 0 on success, -1 on error.  Optional.  Default is to
#   fail, but that is likely to be changed in future.
#
# $obj->TELL ($fh)
#   Returns file position.  Optional.  Default to be determined.
#
# $obj->UNREAD ($buffer, $fh)
#   Returns the number of octets from $buffer that have been
#   successfully saved to be returned on future FILL/READ calls.
#   Optional.  Default is to push data into a temporary layer above
#   this one.
#
# $obj->FLUSH ($fh)
#   Flush any buffered write data.  May possibly be called on readable
#   handles too.  Should return 0 on success, -1 on error.
sub FLUSH {
    my ($self, $fh) = @_;
#DDumper { FLUSH => \@_ };

    ref $self && $self->{xz} or return 0;
    $self->{xz}->flush;
    $self->{mode} eq "w" and $self->{xz}->close;
    return 0;
    } # FLUSH

# $obj->SETLINEBUF ($fh)
#   Optional. No return.
#
# $obj->CLEARERR ($fh)
#   Optional. No return.
#
# $obj->ERROR ($fh)
#   Optional. Returns error state. Default is no error until a
#   mechanism to signal error (die?) is worked out.
#
# $obj->EOF ($fh)
#   Optional. Returns end-of-file state. Default is a function of the
#   return value of FILL or READ.

1;
__END__

=head1 NAME

PerlIO::via::xz - PerlIO layer for XZ (de)compression

=head1 SYNOPSIS

    use PerlIO::via::XZ;

    # Read a xz compressed file from disk.
    open my $fh, "<:via(xz)", "compressed_file";
    my $uncompressed_data = <$fh>;

    # Compress data on-the-fly to a xz compressed file on disk.
    open my $fh, ">:via(xz)", "compressed_file";
    print { $fh } $uncompressed_data;

=head1 DESCRIPTION

This module implements a PerlIO layer which will let you handle
xz compressed files transparently.

=head1 BUGS

Using C<binmode> on an opened file for compression will pop (remove)
the layer.

=head1 PREREQUISITES

This module requires IO::Compress::Xz and IO::Uncompress::UnXz.

=head1 SEE ALSO

PerlIO::via, IO::Compress::Xz, IO::Uncompress::UnXz.

=head1 AUTHOR

H.Merijn Brand E<lt>hmbrand@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020-2023 by H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
