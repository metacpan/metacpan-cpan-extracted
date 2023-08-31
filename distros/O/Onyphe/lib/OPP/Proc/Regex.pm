#
# $Id: Regex.pm,v df49b574c57c 2023/03/24 06:37:31 gomor $
#
package OPP::Proc::Regex;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | regex data='^.+?Server: (apache)' outputfield=server
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $outputfield = defined($options->{outputfield}) && $options->{outputfield}[0] || 'regex';
   for my $o (keys %$options) {
      next if $o eq 'args';  # Skip original arguments line
      next if $o eq 'outputfield';  # Skip that too
      my $values = $self->value($input, $o);
      next unless $values;  # Skip input when no field found
      my $regex = $options->{$o};  # Example: $regex = [ '^.+?Server: apache' ]
      $regex = $regex->[0];  # Example: $regex '^.+?Server: apache'
      for my $this (@$values) {  # Example: $this = 'Server: apache'
         if ($this =~ m{$regex}si) {
            my $capture = $1;
            $input->{$outputfield} = $capture if defined $capture;
            $self->output->add($input);
         }
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Regex - regex processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
