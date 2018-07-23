#
# $Id: S.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Ext::S;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   B
   F
   W
   O
   M
   S
   L
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      B => 'B00000',
      F => 'F0',
      W => 'W0',
      O => 'O0',
      M => 'M0',
      S => 'S0',
      L => 'L0',
      @_,
   );

   return $self;
}

sub print {
   my $self = shift;

   my $buf = $self->B.' '.$self->F.' '.$self->W.' '.$self->O.' '.$self->M.' '.
             $self->S.' '.$self->L;

   return $buf;
}

1;

__END__

=head1 NAME

Net::SinFP3::Ext::S - SinFP3 signature object

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
