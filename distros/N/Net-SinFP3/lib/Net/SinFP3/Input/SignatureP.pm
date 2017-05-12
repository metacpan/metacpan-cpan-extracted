#
# $Id: SignatureP.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input::SignatureP;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
__PACKAGE__->cgBuildIndices;

use Net::SinFP3::Ext::SP;
use Net::SinFP3::Next::Passive;

use Data::Dumper;

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   return $self;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   # We only have one next object
   $self->last(1);

   my $p = $self->_parseSignatureP();

   return Net::SinFP3::Next::Passive->new(
      global => $self->global,
      sp     => Net::SinFP3::Ext::SP->new(%$p),
   );
}

sub _parseSignatureP {
   my $self = shift;

   my $log = $self->global->log;

   print "Please enter passive signature:\n";
   my @lines = ();
   while (<>) {
      chomp;
      push @lines, $_;
   }

   my $buf = join('', @lines);
   if (! defined($buf) || ! length($buf)) {
      $log->fatal("No input given");
   }

   my ($patternsSP) = $buf =~ m/^.*(?:SP:)?\s*(F.*?W.*?O.*?M.*?S.*?L.*).*?$/s;
   if (! defined($patternsSP) || ! length($patternsSP)) {
      $log->fatal("No passive signature found in given string");
   }

   $log->debug("[$patternsSP]");

   my @patternsSP = split(/\s+/, $patternsSP);

   if (@patternsSP < 5) {
      $log->fatal("patternsSP: ",Dumper(\@patternsSP));
   }

   my $sp = {
      F => $patternsSP[0],
      W => $patternsSP[1],
      O => $patternsSP[2],
      M => $patternsSP[3],
      S => $patternsSP[4],
      L => $patternsSP[5],
   };

   return $sp;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::SignatureP - takes a passive signature

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
