#
# $Id: Flatten.pm,v 4d337b0a6526 2023/03/08 08:06:55 gomor $
#
package OPP::Proc::Flatten;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | flatten
#
sub process {
   my $self = shift;
   my ($input) = @_;

   $input->{_opp_nounflatten} = 1;
   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Flatten - flatten processor 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
