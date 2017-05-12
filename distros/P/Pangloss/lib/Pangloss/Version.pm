=head1 NAME

Pangloss::Version - distribution version for Pangloss.

=head1 SYNOPSIS

 our $VERSION = ((require Pangloss::Version), $Pangloss::VERSION)[1];

=cut

package Pangloss::Version;

use strict;
use warnings::register;

our $VERSION = '0.06';

$Pangloss::VERSION = $VERSION;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

Contains distribution version of Pangloss as:

  $Pangloss::Version::VERSION;

and invades the Pangloss namespace to set:

  $Pangloss::VERSION;

which is easier to type.

Designed for minimal-overhead, esp. for CPAN, MakeMaker & Module::Build's
version parsing functions.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>

=cut


