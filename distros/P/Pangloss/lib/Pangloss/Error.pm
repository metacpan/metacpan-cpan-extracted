=head1 NAME

Pangloss::Error - base class for all Pangloss Errors.

=head1 SYNOPSIS

  # see OpenFrame::WebApp::Error

=cut

package Pangloss::Error;

use strict;
use warnings::register;

use base qw( OpenFrame::WebApp::Error );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

1;

__END__

=head1 DESCRIPTION

Base class for Error exceptions in Pangloss.  Inherits its interface from
L<OpenFrame::WebApp::Error>.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Error>,
L<OpenFrame::WebApp::Error>,
L<Pangloss>

=cut


