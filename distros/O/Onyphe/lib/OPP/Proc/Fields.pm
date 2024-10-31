#
# $Id: Fields.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Fields;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | fields ip,protocol,domain,app.http.component.product
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $keep = $self->options->{0} || {};

   # Build list of fields to be kept from input argument:
   if (defined($keep)) {
      $keep = { map { $_ => 1 } split(/\s*,\s*/, $keep) };
   }

   # Get list of full input field names:
   my $fields = $self->fields($input);

   # Iterate over all input fields and delete those not wanted for being kept:
   for my $k (@$fields) {
      $self->delete($input, $k) if !$keep->{$k};
   }

   $self->output->add($input) if %$input > 0;

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Fields - fields processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
