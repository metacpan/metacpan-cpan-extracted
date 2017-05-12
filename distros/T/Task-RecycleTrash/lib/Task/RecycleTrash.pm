package Task::RecycleTrash;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}

sub dummy { 1 }

1;

__END__

=pod

=head1 NAME

Task::RecycleTrash - Check/install the dependencies for File::Remove::trash

=head1 DESCRIPTION

The B<trash> function was added to L<File::Remove> to provide access to
various operating system's native "holding area" for deleted files.

On Mac OS X this is known as the "trash" bin, on Windows this is known as
the "recycle" bin.

Unfortunately, the dependencies needed to interact with this functionality
can be quite difficult in several cases, most notably on Mac OS X where the
L<Mac::Glue> (and thus L<Mac::Carbon>) module is needed.

This created the rediculous situation in which a Mac OS X machine would
need to install and (audibly) test a voice synthesis engine in order to add
the capability to reliably delete a file.

To resolve this problem, the "trash" functionality in L<File::Remove> will
ultimately be moved to a seperate distribution, but in the short term the
dependencies for the B<trash> function will simply not be declared.

B<Task::RecycleTrash> provides a replacement dependency for people that
genuinely do need to use the B<trash> function in L<File::Remove>.

It will install the dependencies needed on each platform, and then run some
simple tests to ensure that the trash function is working as intended.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Task>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
