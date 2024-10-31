#
# $Id: Uniq.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Uniq;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | uniq hostname
# | uniq ip,port,forward
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $fields = $self->options->{0}; # XXX: check argument
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

   unless ($self->state->exists($k, $self->idx)) {
      my $clone = $self->clone($input);
      my %fields = map { $_ => 1 } @fields;
      for my $this (@{$self->fields($clone)}) {
         next if $fields{$this};
         $self->delete($clone, $this);
      }
      $self->output->add($clone);
   }

   $self->state->incr($k, $self->idx);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Uniq - uniq processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
