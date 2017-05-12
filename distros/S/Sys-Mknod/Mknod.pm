=head1 NAME

Sys::Mknod - make special files

=head1 SYNOPSIS

  use Sys::Mknod;

  mknod ("/dev/filename", type, $major, $minor, $mode);
  mkfifo ("filename", $mode);

=head1 DESCRIPTION

mknod - creates special files.  Why use system() when you can use
syscall()?

$mode is the resultant file mode, and defaults to 0666.  It does not
override your umask.

=head1 SPECIAL FILE TYPES

$type must be one of:

=over 4

=item m/^c/i

Creates a "Character Special" device.

=item m/^b/i

Creates a "Block Special" device"

=back

=cut

package Sys::Mknod;

use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

# OK, so the overhead of interpreting these files pretty much
# obliviates the beneifit of avoiding a system().  See if I care.
{
local $^W = 0;
require "sys/sysmacros.ph";
require "sys/types.ph";
require "sys/syscall.ph";
}
use Fcntl qw(S_IFCHR S_IFIFO S_IFBLK);

# I'm exporting all these functions for DWIM's sake.
our @EXPORT = qw(mknod mkfifo);

our $VERSION = '0.02';

# Preloaded methods go here.

sub mknod($$$$;$) {
    my ($filename, $type, $major, $minor, $mode) = (@_);

    $mode = 0666 unless defined $mode;

    if ($type =~ m/^b/i) {
	$mode |= S_IFBLK;
    } elsif ($type =~ m/^c/i) {
	$mode |= S_IFCHR;
    } elsif ($type =~ m/^f/i) {
	$mode |= S_IFIFO;
    } else {
	croak ("Invalid special file type `$type'");
    }

    my $return = syscall( &SYS_mknod, $filename, $mode,
			  ( defined $major
			    ? makedev($major, $minor)
			    : 0 ) );
    if ($return < 0) {
	die $!;
    } else {
	return 1;
    }
}

sub mkfifo($;$) {
    my ($filename, $mode) = (@_);

    mknod($filename, "fifo", undef, undef, $mode);

}

sub make_dev($$) {
    my ($major, $minor) = (@_);
    return makedev($major, $minor);
}

1;
__END__

=head1 AUTHOR

Sam Vilain, E<lt>sam@vilain.netE<gt>

=head1 SEE ALSO

L<perlfunc>, L<mknod(2)>, L<mknod(1)>, L<mkfifo(1)>

=cut
