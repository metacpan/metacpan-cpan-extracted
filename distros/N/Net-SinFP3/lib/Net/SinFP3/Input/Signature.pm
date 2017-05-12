#
# $Id: Signature.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input::Signature;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
__PACKAGE__->cgBuildIndices;

use Net::SinFP3::Ext::S;
use Net::SinFP3::Next::Active;

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

   my $p = $self->_parseSignature();

   return Net::SinFP3::Next::Active->new(
      global => $self->global,
      s1     => Net::SinFP3::Ext::S->new(%{$p->[0]}),
      s2     => Net::SinFP3::Ext::S->new(%{$p->[1]}),
      s3     => Net::SinFP3::Ext::S->new(%{$p->[2]}),
   );
}

sub _parseSignature {
   my $self = shift;

   my $log = $self->global->log;

   print "Please enter active signature:\n";
   my @lines = ();
   while (<>) {
      chomp;
      push @lines, $_;
   }

   my $buf = join('', @lines);
   if (! defined($buf) || ! length($buf)) {
      $log->fatal("No input given");
   }

   my $patternsS1;
   my $patternsS2;
   my $patternsS3;
   for my $line (@lines) {
      #$log->debug("LINE[$line]");
      if ($line =~ m/^\s*S1:\s*(B.*?F.*?W.*?O.*?M.*?S.*?L.*).*?$/s) {
         $patternsS1 = $1;
      }
      elsif ($line =~ m/^\s*S2:\s*(B.*?F.*?W.*?O.*?M.*?S.*?L.*).*?$/s) {
         $patternsS2 = $1;
      }
      elsif ($line =~ m/^\s*S3:\s*(B.*?F.*?W.*?O.*?M.*?S.*?L.*).*?$/s) {
         $patternsS3 = $1;
      }
   }

   $log->debug("patternsS1[$patternsS1]");
   $log->debug("patternsS2[$patternsS2]");
   $log->debug("patternsS3[$patternsS3]");

   if ((! defined($patternsS1) || ! length($patternsS1))
   ||  (! defined($patternsS2) || ! length($patternsS2))
   ||  (! defined($patternsS3) || ! length($patternsS3))) {
      $log->fatal("No valid active signature found in given string");
   }

   $log->debug("[$patternsS1]");
   $log->debug("[$patternsS2]");
   $log->debug("[$patternsS3]");

   my @patternsS1 = split(/\s+/, $patternsS1);
   my @patternsS2 = split(/\s+/, $patternsS2);
   my @patternsS3 = split(/\s+/, $patternsS3);

   if (@patternsS1 < 6) {
      $log->fatal("patternsS1: ",Dumper(\@patternsS1));
   }
   if (@patternsS2 < 6) {
      $log->fatal("patternsS2: ",Dumper(\@patternsS2));
   }
   if (@patternsS3 < 6) {
      $log->fatal("patternsS3: ",Dumper(\@patternsS3));
   }

   my $s1 = {
      B => $patternsS1[0],
      F => $patternsS1[1],
      W => $patternsS1[2],
      O => $patternsS1[3],
      M => $patternsS1[4],
      S => $patternsS1[5],
      L => $patternsS1[6],
   };

   my $s2 = {
      B => $patternsS2[0],
      F => $patternsS2[1],
      W => $patternsS2[2],
      O => $patternsS2[3],
      M => $patternsS2[4],
      S => $patternsS2[5],
      L => $patternsS2[6],
   };

   my $s3 = {
      B => $patternsS3[0],
      F => $patternsS3[1],
      W => $patternsS3[2],
      O => $patternsS3[3],
      M => $patternsS3[4],
      S => $patternsS3[5],
      L => $patternsS3[6],
   };

   return [ $s1, $s2, $s3 ];
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::Signature - takes an active signature

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
