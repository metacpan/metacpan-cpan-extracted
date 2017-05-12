package Ouroboros::Library;

use File::ShareDir qw/dist_file/;

our $VERSION = "0.12";

use strict;
use warnings;

sub c_source {
    dist_file("Ouroboros", "libouroboros.c");
}

sub c_header {
    dist_file("Ouroboros", "libouroboros.h");
}

1;

__END__

=head1 NAME

Ouroboros::Library - helpers to find libouroboros sources

=head1 DESCRIPTION

C<Ouroboros> distribution bundles C source of the wrappers with each install to
allow users to link wrappers to their modules directly, if such option is
available.

=head1 METHODS

=over

=item C<c_source>

Returns path to one or more C files. These files provide symbols described in the L<Ouroboros::Spec>.

=item C<c_header>

Returns path to one or more C header files. These files define symbols described in the L<Ouroboros::Spec>.

=back
