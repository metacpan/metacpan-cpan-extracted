package PerlIO::via::Pod;

$VERSION= '0.06';

# be as struct as possible
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

    # create the object with the right attributes
    return bless { inpod => 0 }, $_[0];
} #PUSHED

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 processed string (if any)

sub FILL {

    # process all lines
    local( $_ );
    while ( defined( $_= readline( $_[1] ) )) {

        # pod, but not the end of it
	if ( m#^=[a-zA-Z]# ) {
            return $_ if $_[0]->{inpod}= !m#^=cut#;
        }

        # still in pod
        elsif ($_[0]->{inpod}) {
            return $_;
        }
    }

    # we're done
    return undef;
} #FILL

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written

sub WRITE {

    # all lines
    foreach ( split( m#(?<=$/)#, $_[1] ) ) {

        # not at end of pod
	if ( m#^=[a-zA-Z]# ) {
            if ($_[0]->{inpod} = !m#^=cut#) {
                return -1 if !print { $_[2] } $_;
            }
        }

        # still in pod
        elsif ( $_[0]->{inpod} ) {
            return -1 if !print { $_[2] } $_;
        }
    }

    return length( $_[1] );
} #WRITE

#-------------------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::Pod - PerlIO layer for extracting plain old documentation

=head1 SYNOPSIS

 use PerlIO::via::Pod;

 open( my $in, '<:via(Pod)', 'file.pm' )
  or die "Can't open file.pm for reading: $!\n";
 
 open( my $out, '>:via(Pod)', 'file.pm' )
  or die "Can't open file.pm for writing: $!\n";

=head1 VERSION

This documentation describes version 0.06.

=head1 DESCRIPTION

This module implements a PerlIO layer that extracts plain old documentation
(pod) on input B<and> on output.  It is intended as a development tool only,
but may have uses outside of development.

=head1 REQUIRED MODULES

 (none)

=head1 EXAMPLES

Here are some examples, some may even be useful.

=head2 Pod only filter

A script that only lets plain old documentation pass.

 #!/usr/bin/perl
 use PerlIO::via::Pod;
 binmode( STDIN,':via(Pod)' ); # could also be STDOUT
 print while <STDIN>;

=head1 SEE ALSO

L<PerlIO::via>, L<PerlIO::via::UnPod> and any other PerlIO::via modules on CPAN.

=head1 COPYRIGHT

maintained by LNATION, <thisusedtobeanemail@gmail.com>

Copyright (c) 2002, 2003, 2004, 2012 Elizabeth Mattijsen.  All rights reserved.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
