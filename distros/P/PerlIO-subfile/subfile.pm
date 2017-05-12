package PerlIO::subfile;

use 5.008;
use strict;
use warnings;
use vars '$VERSION';

require XSLoader;

$VERSION = '0.08';

XSLoader::load ("PerlIO::subfile", $VERSION);

1;
__END__

=head1 NAME

PerlIO::subfile - Perl extension to provide a PerlIO layer to pretend a
subsection of a file is a whole regular file.

=head1 SYNOPSIS

  use PerlIO::subfile;
  open FOO, "<:subfile(start=123,end=+43)", "bigfile" or die $!;
  print while <FOO>; # Just prints the specified subsection of the file
  seek (FOO, 0, SEEK_SET) # Takes you to offset 123 in bigfile.

=head1 DESCRIPTION

zip files (and other archive files) contain multiple other files within them.
If the contained file is stored uncompressed then it would be nice to save
having to copying it out before a program accesses it.  Instead, it would be
nice to give a file handle onto the subfile which behaves as if the temporary
copy has taken place, but actually reads from the original zip.  Basically all
you need to do is nobble C<seek> and C<tell> so that file offsets are given
from the start of the contained file (and you can't C<seek> your way outside the
bounds), and nobble C<read> so that C<eof> happens in the right place.

=head2 EXPORT

PerlIO::subfile exports no subroutines or symbols, just a perl layer C<subfile>

=head1 LAYER ARGUMENTS

The C<subfile> layer takes a comma separated list of arguments.
The value will be treated as a hexadecimal number if it starts C<Ox>, octal
if it starts with C<O> followed by a digit, decimal in other cases.
(Or whatever your C library's C<strtoul> function things is valid)
Values can be preceded with C<+> or C<-> to treat them as relative, otherwise
they are taken as absolute.

=over 4

=item start

Start of the subfile within the whole file.  An absolute value is taken as
a file position, and immediately causes seek to that position (using
C<SEEK_SET>)).  A relative value is taken as a value relative to the current
position, and immediately causes a seek using C<SEEK_CUR>)).

Omitting start will cause the subfile to start at the current file position.

=item end

End of the subfile within the whole file.  An absolute value is taken as
an absolute file position (in the parent file).  A relative value is taken
as relative to the (current) start.

The absolute value 0 (zero) is taken as "unbounded" - you can read to the
end of file on the parent file.

=back

Arguments are parsed left to right, so it's possible to specify a range as

    end=+8,start=4
    # end 8 bytes beyond current file position, start at byte 4 of file


If you're writing a perl extension in XS, calling PerlIOSubfile_pushed with
an SV that is SvIOK and not SvPOK, then the argument is treated as a
relative end= value. This behaviour probably isn't accessible from the perl
language level. ex::lib::zip uses this.

=head1 BUGS

This is a lazy implementation.  It adds a whole extra (unneeded) layer of
buffering.  There ought to be a total re-write to make most methods just call
the parent, with (probably) only read and seek suitably clipped.  Then again,
as I'm using it for zip files, how many files in zips are stored rather than
deflated?

It also doesn't do write.  Mainly because I have no need for writes at this
time.

=head1 AUTHOR

Nicholas Clark, E<lt>nwc10+subfile@colon.colondot.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut
