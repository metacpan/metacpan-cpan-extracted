#
# $Id: Filter.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Filter;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | fieldcount domain | filter domaincount:>=3
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options or return;

   for my $o (keys %$options) {
      next if $o eq 'args';  # Skip original arguments line
      my $values = $self->value($input, $o);
      next unless $values;  # Skip input when no field found
      my $filter = $options->{$o};  # Example: $filter = [ >=3 ]
      $filter = $filter->[0];  # Example: $filter >= 3
      for my $this (@$values) {  # Example: $this = 3
         if ($filter =~ m{((?:>|<|>=|<=|=))(\d+)$}) {  # Example: $1 = >=, $2 = 3
            if    ($1 eq '>' ) { $self->output->add($input) if $this >  $2 }
            elsif ($1 eq '>=') { $self->output->add($input) if $this >= $2 }
            elsif ($1 eq '<' ) { $self->output->add($input) if $this <  $2 }
            elsif ($1 eq '<=') { $self->output->add($input) if $this <= $2 }
            elsif ($1 eq '=' ) { $self->output->add($input) if $this == $2 }
         }
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Filter - filter processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
