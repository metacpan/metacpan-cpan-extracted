#
# $Id: Fieldcount.pm,v cfbea05b0bc4 2025/01/28 15:06:19 gomor $
#
package OPP::Proc::Fieldcount;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | fieldcount domain
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $field = $self->options->{0} || {};

   my $values = $self->value($input, $field);
   return 1 unless defined($values);  # No field in doc, skip it

   my $new_fieldname = $field.'count';
   $new_fieldname =~ s{\.}{}g;
   
   # Update document with count field:
   $input->{$new_fieldname} = @$values;

   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Fieldcount - fieldcount processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
