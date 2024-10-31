#
# $Id: Whois.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Whois;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | whois ip
# | whois domain
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $field = $self->options->{0} || 'domain';
   return unless defined($field);

   my $values = $self->value($input, $field);
   return 1 unless defined($values);

   for my $this (@$values) {
      next if $self->state->exists($this, $self->idx);
      $self->state->incr($this, $self->idx);

      my $cmd = "timeout --kill-after=20s --signal=QUIT 15s whois $this";

      my $new = { $field => $this };
      $new->{data} = `$cmd 2> /dev/null`;
      $self->output->add($new);
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Whois - exec processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
