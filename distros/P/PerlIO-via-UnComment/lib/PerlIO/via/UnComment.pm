package PerlIO::via::UnComment;

$VERSION= '0.05';

# be as strict as possible
use strict;

# satisfy -require-
1;

#-----------------------------------------------------------------------
#
# Standard Perl features
#
#-----------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

    # return an object
    return bless \*PUSHED, $_[0];
} #PUSHED

#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 processed string (if any)

sub FILL {

    # return first line that isn't a comment
    local( $_ );
    m/^#/ or return $_ while defined( $_= readline( $_[1] ) );

    return undef;
} #FILL

#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written or -1 if failure

sub WRITE {

    # print all lines that don't start with #
  LINE:
    foreach ( split( m#(?<=$/)#, $_[1] ) ) {
	next LINE if m/^#/;

        return -1 if !print {$_[2]} $_;
    }

    return length( $_[1] );
} #WRITE

#-----------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::UnComment - PerlIO layer for removing comments

=head1 SYNOPSIS

 use PerlIO::via::UnComment;

 open( my $in,'<:via(UnComment)','file.pm' )
  or die "Can't open file.pm for reading: $!\n";
 
 open( my $out,'>:via(UnComment)','file.pm' )
  or die "Can't open file.pm for writing: $!\n";

=head1 VERSION

This documentation describes version 0.05.

=head1 DESCRIPTION

This module implements a PerlIO layer that removes comments (any lines that
start with '#') on input B<and> on output.  It is intended as a development
tool only, but may have uses outside of development.

=head1 EXAMPLES

Here are some examples, some may even be useful.

=head2 Source only filter, but with pod

A script that only lets uncommented source code and pod pass.

 #!/usr/bin/perl
 use PerlIO::via::UnComment;
 binmode( STDIN,':via(UnComment)' ); # could also be STDOUT
 print while <STDIN>;

=head2 Source only filter, even without pod

A script that only lets uncommented source code.

 #!/usr/bin/perl
 use PerlIO::via::UnComment;
 use PerlIO::via::UnPod;
 binmode( STDIN,':via(UnComment):via(UnPod)' ); # could also be STDOUT
 print while <STDIN>;

=head1 REQUIRED MODULES

 (none)

=head1 SEE ALSO

L<PerlIO::via>, L<PerlIO::via::UnPod> and any other PerlIO::via modules on CPAN.

=head1 COPYRIGHT

maintained by LNATION, <thisusedtobeanemail@gmail.com>

Copyright (c) 2002, 2003, 2004, 2012 Elizabeth Mattijsen.  All rights reserved.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
