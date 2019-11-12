package PerlIO::via::UnPod;

$VERSION= '0.06';

# be as strict as possible
use strict;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

    # create object with right attributes
    return bless { insrc => 1 }, $_[0];
} #PUSHED

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 processed string (if any)

sub FILL {

    # process all lines
    local($_);
    while ( defined( $_= readline( $_[1] ) ) ) {

        # pod, and the end of it
	if ( m#^=[a-zA-Z]# ) {
            $_[0]->{insrc}= m#^=cut#;
        }

        # still in source
        elsif ( $_[0]->{insrc} ) {
            return $_;
        }
    }

    return undef;
} #FILL

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written or -1 to indicate failure

sub WRITE {

    # all lines
    foreach ( split( m#(?<=$/)#, $_[1] ) ) {

        # pod, and the end of it
	if ( m#^=[a-zA-Z]# ) {
            $_[0]->{insrc}= m#^=cut#;
        }

        # still in source
        elsif ( $_[0]->{insrc} ) {
            return -1 if !print {$_[2]} $_;
        }
    }

    return length( $_[1] );
} #WRITE

#-------------------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::UnPod - PerlIO layer for removing plain old documentation

=head1 SYNOPSIS

 use PerlIO::via::UnPod;

 open( my $in,'<:via(UnPod)','file.pm' )
  or die "Can't open file.pm for reading: $!\n";
 
 open( my $out,'>:via(UnPod)','file.pm' )
  or die "Can't open file.pm for writing: $!\n";

=head1 VERSION

This documentation describes version 0.06.

=head1 DESCRIPTION

This module implements a PerlIO layer that removes plain old documentation
(pod) on input B<and> on output.  It is intended as a development tool only,
but may have uses outside of development.

=head1 REQUIRED MODULES

 (none)

=head1 EXAMPLES

Here are some examples, some may even be useful.

=head2 Source only filter

A script that only lets source code pass.

 #!/usr/bin/perl
 use PerlIO::via::UnPod;
 binmode( STDIN,':via(UnPod)' ); # could also be STDOUT
 print while <STDIN>;

=head1 SEE ALSO

L<PerlIO::via>, L<PerlIO::via::Pod> and any other PerlIO::via modules on CPAN.

=head1 COPYRIGHT

maintained by LNATION, <thisusedtobeanemail@gmail.com>

Copyright (c) 2002, 2003, 2004, 2012 Elizabeth Mattijsen.  All rights reserved.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
