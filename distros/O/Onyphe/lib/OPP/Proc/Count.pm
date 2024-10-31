#
# $Id: Count.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Count;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | count
#
sub process {
   my $self = shift;
   my ($input) = @_;

   $self->state->incr('count', $self->idx);
   $input->{count} = $self->state->value('count', $self->idx);
   $self->output->add({ count => $self->state->value('count', $self->idx) });

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Count - count processor 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
