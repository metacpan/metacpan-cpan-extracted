=head1 NAME

Pipeline::Config::UnknownTypeError - thrown when config type could not be
resolved.

=head1 SYNOPSIS

  # see Error.pm

=cut

package Pipeline::Config::UnknownTypeError;

use strict;
use warnings::register;

use base qw( Pipeline::Config::Error );

our $VERSION  = ((require Pipeline::Config), $Pipeline::Config::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

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

L<Pipeline::Config::Error>

=cut

