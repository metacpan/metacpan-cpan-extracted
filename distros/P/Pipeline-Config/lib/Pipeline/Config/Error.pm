=head1 NAME

Pipeline::Config::Error - base Error class for this project.

=head1 SYNOPSIS

  # see Error.pm

=cut

package Pipeline::Config::Error;

use strict;
use warnings::register;

use base qw( Error );

our $VERSION  = ((require Pipeline::Config), $Pipeline::Config::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.2 $ '))[2];

sub new {
    my $class = shift;
    local $Error::Depth = $Error::Depth + 1;
    return $class->SUPER::new( -text => shift ) if (scalar(@_) == 1);
    return $class->SUPER::new( @_ );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Base class for Errors in this project.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Error>

=cut

