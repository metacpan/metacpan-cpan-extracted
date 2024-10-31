#
# $Id: Expand.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Expand;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | expand domain
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $field = $self->options->{0} or return;

   my $values = $self->value($input, $field);
   # No field by that name, we keep original input untouched:
   $self->output->add($input) unless defined $values;

   for my $v (@$values) {
      my $clone = $self->clone($input);
      $self->set($clone, $field, $v);
      $self->output->add($clone);
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Expand - expand processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
