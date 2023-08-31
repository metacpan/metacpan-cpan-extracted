#
# $Id: Top.pm,v 58d7ce835577 2023/03/25 10:34:10 gomor $
#
package OPP::Proc::Top;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | top protocol
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $field = $self->options->{0}; # XXX: check argument

   my $values = $self->value($input, $field);
   return 1 unless defined($values);

   for my $v (@$values) {
      $self->state->incr($v, $self->idx);
      $self->output->add($self->state->current($self->idx));
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Top - top processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
