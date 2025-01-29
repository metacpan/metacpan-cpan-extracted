#
# $Id: Dedup.pm,v cfbea05b0bc4 2025/01/28 15:06:19 gomor $
#
package OPP::Proc::Dedup;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | dedup hostname
# | dedup hostname,ip
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $fields = $self->options->{0};
   return unless defined($fields);

   my @fields = split('\s*,\s*', $fields);

   my $k = '';
   for my $this (@fields) {
      my $values = $self->value($input, $this);
      next unless defined($values);
      for my $v (@$values) {
         $k .= $this.'-'.$v.':';
      }
   }

   # Skip when no key found:
   return 1 unless length $k;

   $self->output->add($input) unless $self->state->exists($k, $self->idx);
   $self->state->incr($k, $self->idx);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Dedup - dedup processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
