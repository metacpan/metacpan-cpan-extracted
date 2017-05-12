#!/usr/bin/perl -w

package ReadDir;

use 5.005;
use strict;

require Exporter;
require DynaLoader;

BEGIN {
    use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK $VERSION);

    @ISA = qw(Exporter DynaLoader);

    %EXPORT_TAGS = ( 'all' => [ qw( &readdir_inode &readdir_hashref
				    &readdir_arrayref) ] );

    @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

    $VERSION = '0.03';
};

# contact me if you need this as a complete XS routine, I'm just being
# lazy - Sam.
sub readdir_arrayref($) { [ readdir_inode(shift) ] }

bootstrap ReadDir $VERSION;

1;
__END__

=head1 NAME

ReadDir - Get the inode numbers in your readdir call.

=head1 SYNOPSIS

  use ReadDir qw(&readdir_inode);

  my (@files) = readdir_inode ".";

  printf ("%7d %s\n", $_->[1], $_->[0])
      foreach (@files);

=head1 DESCRIPTION

readdir_inode is a lot like the builtin readdir, but this function
returns the inode numbers of the directory entries as well.  If it is
returned by your system, the contents of the "d_type" field are
returned as well.

So, the example in the synopsis is a quick `C<ls -i>'.

This will save you a `stat' in certain situations.

I didn't implement the whole opendir/readdir/closedir system, because
I think that's an overcomplication; but see L<IO::Dirent> for a
replacement of the readdir() function that works with opendir.

=head1 FUNCTIONS

=over

=item readdir_inode($dir)

Returns an ARRAY of C<[ $name, $inode ]> for the given directory.

=item readdir_arrayref($dir)

Returns a reference to an ARRAY of C<[ $name, $inode ]> for the passed
directory.

=item readdir_hashref($dir)

Returns a reference to a HASH consisting of C<($name =E<gt> $inode)>
pairs.

=back

=head1 FURTHER EXAMPLES

 use ReadDir;
 $contents = readdir_hashref(".");

 delete $contents->{"."};
 delete $contents->{".."};

 while (my ($filename, $inode) = each %$contents) {
     printf ("%7d %s\n", $inode, $filename);
 }

 $contents = readdir_arrayref("..");
 for my $dent (@$contents) {
     printf ("%7d %s\n", $dent->[1], $dent->[2]);
 }

=head2 CAVEATS

If the directory entry in question is a mount point, you will receive
the inode number of the B<underlying directory>, not the root inode of
the mounted filesystem.  This behaviour may or may not vary between
systems.

This may not be a very portable function, either.  It works on at
least Linux, Solaris, and FreeBSD.  It does not return anything useful
on Windows based platforms.

Remember, the operating system keeps its own cache of directory
entries.  Consider whether or not you are just adding to complete
system bloat using this function :-).

=head1 AUTHOR

Sam Vilain, E<lt>sam@vilain.netE<gt>

Many thanks to Ville Herva for debugging an XS memory leak for me, and
providing readdir_hashref!

=head1 SEE ALSO

L<perlfunc>.  IO::Dirent provides an alternate approach to the same
thing that

=cut


