#
# $Id: Addfield.pm,v 683f32a81df6 2024/03/07 08:31:39 gomor $
#
package OPP::Proc::Addfield;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | addfield scope=target mytag=test
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
      my $values = $self->value($input, $k);
      if (defined($input->{$k})) {
         my $current = $input->{$k};
         $current = ref($current) eq 'ARRAY' ? $current : [ $current ];
         my %values = map { $_ => 1 } ( @$current, $fields{$k} );
         $input->{$k} = [ sort { $a cmp $b } keys %values ];
      }
      else {
         $input->{$k} = $fields{$k};
      }
   }

   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Addfield - addfield processor

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE E<lt>contact_at_onyphe.ioE<gt>

=cut
