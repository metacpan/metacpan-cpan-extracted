#
# $Id: Rename.pm,v 4f57597d0aa4 2025/02/10 07:44:58 gomor $
#
package OPP::Proc::Rename;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | rename source1=destination1 source2=destination2
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;

   my %fields = ();
   for my $k (keys %$options) {
      next if $k eq 'args';
      next unless defined($options->{$k});
      $fields{$k} = $options->{$k}[0] if defined($options->{$k}[0]);
   }

   for my $k (keys %fields) {
      next unless defined($fields{$k});
      my $src = $k;
      my $dst = $fields{$k};
      if (defined($input->{$src})) {
         $input->{$dst} = $input->{$src};
         delete $input->{$src};
      }
   }

   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Rename - rename processor

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE E<lt>contact_at_onyphe.ioE<gt>

=cut
