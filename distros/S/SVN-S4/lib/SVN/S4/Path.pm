# See copyright, etc in below POD section.
######################################################################

package SVN::S4::Path;
use IO::AIO;
use File::Spec;
use File::Spec::Functions;
use strict;

use SVN::S4::Debug qw (DEBUG is_debug);

our $VERSION = '1.064';

######################################################################

sub isURL {
    my $filename = shift;
    return ($filename =~ m%://%);
}

sub fileNoLinks {
    my $filename = shift;
    # Remove any symlinks in the filename
    # Subversion doesn't allow "cd ~/sim/project" where project is a symlink!
    # Modified example from the web

    #print "FNLinp: $filename\n";
    $filename = File::Spec->rel2abs($filename);
    my @right = File::Spec->splitdir($filename);
    my @left;

    while (@right) {
	#print "PARSE: ",catfile(@left),"  --- ",catfile(@right),"\n";
	my $item = shift @right;
	next if $item eq ".";
	if ($item eq "") {
	    push @left, $item;
	    next;
	}
	elsif ($item eq "..") {
	    pop @left if @left > 1;
	    next;
	}

	my $link = readlink (catfile(@left, $item));

	if (defined $link) {
	    if (file_name_is_absolute($link)) {
		@left = File::Spec->splitdir($link);
	    } else {
		unshift @right, File::Spec->splitdir($link);
	    }
	    # Start search over, as we might have more links to resolve
	    unshift @right, @left;
	    @left = ();
	    next;
	} else {
	    push @left, $item;
	    next;
	}
    }
    my $out = catfile(@left);
    #print "FNLabs: $out\n";
    return $out;
}

sub wholefile {
    # Return whole contents of specified file
    my $filename = shift;
    my $fh = IO::File->new ("<$filename") or return undef;

    my $wholefile;
    {   local $/;
	undef $/;
	$wholefile = <$fh>;
    }
    $fh->close();
    return $wholefile;
}

sub prefetchDirTree {
    my @dirs = @_;
    _prefetchDirTreeRecurse("", \@dirs);
    IO::AIO::flush();
}

sub _prefetchDirTreeRecurse {
    my $dir = shift;
    my $bases = shift;
    foreach my $base (@{$bases}) {
	my $file = $dir;
	$file .= "/" if $file ne "";
	$file .= $base;
	if (1) {  # $base ne ".svn"
	    IO::AIO::aio_scandir($file, 16, sub {
		_prefetchDirTreeRecurse($file, @_); } );
	}
    }
}

######################################################################
### Package return
1;
__END__

=pod

=head1 NAME

SVN::S4::Path - File path and parsing utilities

=head1 SYNOPSIS

   my $file = fileNoLinks($filename)

=head1 DESCRIPTION

This module provides operations on files and paths.

=head1 METHODS

=over 4

=item fileNoLinks($filename)

Resolve any symlinks in the given filename.

=item isURL($filename)

Return true if the filename is a absolute URL file name.

=item wholefile($filename)

Return contents of the file as a string, or undef if does not exist.

=item prefetchDirTree($dir)

Use AIO to read directory stat() information into the file cache, so
subsequent stats() or svn operations will proceed very quickly.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2002-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SVN::S4>

=cut
