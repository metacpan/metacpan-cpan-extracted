package Mmap;

=head1 NAME

Mmap - uses mmap to map in a file as a perl variable

=head1 SYNOPSIS

    use Mmap;

    mmap($foo, 0, PROT_READ, MAP_SHARED, FILEHANDLE) or die "mmap: $!";
    @tags = $foo =~ /<(.*?)>/g;
    munmap($foo) or die "munmap: $!";
    
    mmap($bar, 8192, PROT_READ|PROT_WRITE, MAP_SHARED, FILEHANDLE);
    substr($bar, 1024, 11) = "Hello world";

=head1 DESCRIPTION

The Mmap module lets you use mmap to map in a file as a perl variable
rather than reading the file into dynamically allocated memory. It
depends on your operating system supporting UNIX or POSIX.1b mmap, of
course. You need to be careful how you use such a variable. Some
programming constructs may create copies of a string which, while
unimportant for smallish strings, are far less welcome if you're
mapping in a file which is a few gigabytes big. If you use PROT_WRITE
and attempt to write to the file via the variable you need to be even
more careful. One of the few ways in which you can safely write to
the string in-place is by using substr as an lvalue and ensuring that
the part of the string that you replace is exactly the same length.

=over 4

=item mmap(VARIABLE, LENGTH, PROTECTION, FLAGS, FILEHANDLE, OFFSET)

Maps LENGTH bytes of (the underlying contents of) FILEHANDLE into your
address space, starting at offset OFFSET and makes VARIABLE refer to
that memory. The OFFSET argument can be omitted in which case it defaults
to zero. The LENGTH argument can be zero in which case a stat is done on
FILEHANDLE and the size of the underlying file is used instead.

The PROTECTION argument should be some ORed combination of the
constants PROT_READ, PROT_WRITE and PROT_EXEC or else PROT_NONE. The
constants PROT_EXEC and PROT_NONE are unlikely to be useful here but are
included for completeness.

The FLAGS argument must include either
MAP_SHARED or MAP_PRIVATE (the latter is unlikely to be useful here).
If your platform supports it, you may also use MAP_ANON or MAP_ANONYMOUS.
If your platform supplies MAP_FILE as a non-zero constant (necessarily
non-POSIX) then you should also include that in FLAGS. POSIX.1b does not
specify MAP_FILE as a FLAG argument and most if not all versions of Unix
have MAP_FILE as zero.

mmap returns 1 on success and undef on failure.

=item munmap(VARIABLE)

Unmaps the part of your address space which was previously mapped in
with a call to C<mmap(VARIABLE, ...)> and makes VARIABLE become undefined.

munmap returns 1 on success and undef on failure.

=item Constants

The Mmap module exports the following constants into your namespace
    MAP_SHARED MAP_PRIVATE MAP_ANON MAP_ANONYMOUS MAP_FILE
    PROT_EXEC PROT_NONE PROT_READ PROT_WRITE

Of the constants beginning MAP_, only MAP_SHARED and MAP_PRIVATE are
defined in POSIX.1b and only MAP_SHARED is likely to be useful.

=back

=head1 AUTHOR

Malcolm Beattie, 21 June 1996.

=cut

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);
require DynaLoader;
require Exporter;
@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(mmap munmap
	     MAP_ANON MAP_ANONYMOUS MAP_FILE MAP_PRIVATE MAP_SHARED
	     PROT_EXEC PROT_NONE PROT_READ PROT_WRITE);

$VERSION = '0.10';


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Mmap macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Mmap $VERSION;

1;
