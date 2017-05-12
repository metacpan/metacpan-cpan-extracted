#
# $Id: Null.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Log::Null;
use strict;
use warnings;

use base qw(Net::SinFP3::Log);
__PACKAGE__->cgBuildIndices;

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   return $self;
}

sub warning {
   my $self = shift;
   return 1;
}

sub error {
   my $self = shift;
   return 1;
}

sub fatal {
   my $self = shift;
   return 1;
}

sub info {
   my $self = shift;
   return 1;
}

sub verbose {
   my $self = shift;
   return 1;
}

sub debug {
   my $self = shift;
   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Log::Null - disable logging

=head1 SYNOPSIS

   use Net::SinFP3::Log::Null;

   my $log = Net::SinFP3::Log::Null->new;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

=item B<info>

=item B<warning>

=item B<error>

=item B<fatal>

=item B<verbose>

=item B<debug>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
