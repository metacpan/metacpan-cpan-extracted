#
# $Id: PortError.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Result::PortError;
use strict;
use warnings;

use base qw(Net::SinFP3::Result);
our @AS = qw(
   ip
   port
   hostname
   reverse
   frame
   p1Reason
   p2Reason
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::TCP qw(:consts);

sub take {
   return [
      'Net::SinFP3::Search::Active',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      ip       => '127.0.0.1',
      port     => 0,
      hostname => 'unknown',
      reverse  => 'unknown',
      p1Reason => 'unknown',
      p2Reason => 'unknown',
      @_,
   );

   return $self;
}

sub printSignature {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;

   my $buf = '';
   $buf .= "Result for target [".$self->ip."]:".$self->port.":";

   return $buf;
}

sub print {
   my $self = shift;

   my $buf = "> Cannot fingerprint a closed or filtered port:\n";
   $buf .= "> Error for P1 reply: ".$self->p1Reason."\n";
   $buf .= "> Error for P2 reply: ".$self->p2Reason;

   return $buf;
}

1;

__END__

=head1 NAME

Net::SinFP3::Result::PortError - result object when target port is in error

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
