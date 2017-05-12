#
# $Id: Unknown.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Result::Unknown;
use strict;
use warnings;

use base qw(Net::SinFP3::Result);
our @AS = qw(
   ip
   port
   hostname
   reverse
   frame
   sp
   s1
   s2
   s3
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Ext::S;
use Net::SinFP3::Ext::SP;

sub take {
   return [
      'Net::SinFP3::Search::Active',
      'Net::SinFP3::Search::Passive',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      ip       => '127.0.0.1',
      port     => 0,
      hostname => 'unknown',
      reverse  => 'unknown',
      @_,
   );

   return $self;
}

sub printSignature {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;

   my $buf = '';

   # Active signature
   if ($self->s1 || $self->s2 || $self->s3) {
      $buf .= "Result for target [".$self->ip."]:".$self->port.":";
      $buf .= "\nS1: ".$self->s1->print if $self->s1;
      $buf .= "\nS2: ".$self->s2->print if $self->s2;
      $buf .= "\nS3: ".$self->s3->print if $self->s3;
   }
   # Passive signature
   elsif ($self->sp) {
      if ($self->frame) {
         my $frame = $self->frame;
         my $ip    = $frame->ref->{IPv4} || $frame->ref->{IPv6};
         $buf     .= $ip->src.':'.$frame->ref->{TCP}->src.' > '.
                     $ip->dst.':'.$frame->ref->{TCP}->dst."\n";
      }

      $buf .= 'SP: '.$self->sp->print;
   }
   else {
      $log->fatal("No signature to print");
   }

   return $buf;
}

sub print {
   my $self = shift;

   my $buf = "Unknown fingerprint";

   return $buf;
}

1;

__END__

=head1 NAME

Net::SinFP3::Result::Unknown - result object when target fingerprint is unknown

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
