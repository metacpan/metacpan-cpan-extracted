=head1 NAME

OpenFrame::WebApp::Error::LoadClass - thrown when a class could not be loaded.

=head1 SYNOPSIS

  # see Error.pm

=cut

package OpenFrame::WebApp::Error::LoadClass;

use strict;
use warnings::register;

use base qw( Error );

our $VERSION = (split(/ /, ' $Revision: 1.1 $ '))[2];

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Simple error class - exists for the name only.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Error>

=cut

