#
# $Id: Exists.pm,v cfbea05b0bc4 2025/01/28 15:06:19 gomor $
#
package OPP::Proc::Exists;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | exists cpe
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $field = $self->options->{0} or return;

   my $values = $self->value($input, $field);
   # Field by that name, we keep original input untouched:
   $self->output->add($input) if defined $values;

   # Otherwise, we skip it.

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Exists - exists processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
