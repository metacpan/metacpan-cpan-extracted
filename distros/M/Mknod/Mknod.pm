package Mknod;

use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	mknod
    S_IFREG
    S_IFIFO
    S_IFBLK
    S_IFCHR
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Mknod', $VERSION);

# Preloaded methods go here.

sub mknod {
    if (defined $_[2]) {
        goto &mknod3;
    }
    if (defined $_[1]) {
        goto &mknod2;
    }
    else {
        print Carp::shortmess("Usage: mknod(file, mode [,dev])");
        return 0;
    }
}

1;
__END__

=head1 NAME

Mknod - Perl extension for the mknod(2) call

=head1 SYNOPSIS

  use Mknod;
  # create a pipe 
  mknod('hole', S_IFIFO|0644);
  # or a device
  mknod('ttyS0', S_IFCHR|0644, 4|64);

=head1 DESCRIPTION

  It seemed to me this system call wasnt available to perl yet.
  If I was just looking in the wrong place, please let me know:)

  Returns 1 on ok and 0 on failure.

=head2 EXPORT

  mknod()
  S_IFREG
  S_IFIFO
  S_IFBLK
  S_IFCHR

This behaviour can be prevented:
  use Mknod ();
  Mknod::mknod(...)

=head1 SEE ALSO

  mknod(1)
  mknod(2)

=head1 AUTHOR

Raoul Zwart, E<lt>rlzwart@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
