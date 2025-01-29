#
# $Id: Pivots.pm,v cfbea05b0bc4 2025/01/28 15:06:19 gomor $
#
package OPP::Proc::Pivots;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# NOTE: pivots can handle both SCALAR & ARRAYs for all fields
#
# | pivots
# | pivots domain,subject.organization,subject.email
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $defaults = [ qw(
      domain organization geolocus.netname netname subject.organization
      subject.email issuer.organization
      app.http.tracker.ga app.http.tracker.gaw app.http.tracker.gpub
      app.http.tracker.fbq app.http.tracker.snaptr app.http.tracker.newrelic
   ) ];

   my $rewrite = {
      'app.extract.domain' => 'domain',
   };

   my $options = $self->options;
   my $pivots = defined($options->{0}) ? [ split(',', $options->{0}) ] : $defaults;

   my %pivots = map { $_ => 1 } @$pivots;

   for my $field (keys %$input) {
      next unless $pivots{$field};
      my $v = $self->value($input, $field) or next;
      next unless @$v;
      $field = $rewrite->{$field} || $field;
      for (@$v) {
         $self->output->add({ $field => $_ }) unless $self->state->exists("$field|$_", $self->idx);
         $self->state->add("$field|$_", 1, $self->idx);
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Pivots - pivots processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
