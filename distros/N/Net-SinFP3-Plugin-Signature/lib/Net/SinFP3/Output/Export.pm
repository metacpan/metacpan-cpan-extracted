#
# $Id: Export.pm 22 2015-01-04 16:42:47Z gomor $
#
package Net::SinFP3::Output::Export;
use strict;
use warnings;

use base qw(Net::SinFP3::Output);
__PACKAGE__->cgBuildIndices;

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   return $self;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;
   my $db     = $global->db;

   if (ref($db) !~ /Net::SinFP3::DB::SinFP3/) {
      $log->fatal("Give a Net::SinFP3::DB::SinFP3 object (you gave [".ref($db)."]");
   }

   my $idList = $db->searchSignatureIds;
   for my $id (sort { $a <=> $b } @$idList) {
      my $s = $db->retrieveSignature($id);
      $s    = $db->lookupPatterns($s);
      _printSignature($db, $s);
   }

   return 1;
}

sub _printSignature {
   my ($db, $s) = @_;

   print
      $s->{ipVersion}. ': '.
      $s->{systemClass}. ': '.
      $s->{vendor}. ': '.
      $s->{os}. ': '.
      $s->{osVersion}. ': ['.
      $s->{osVersionFamily}. ']';

   my $osVersionChildren = $db->getOsVersionChildrenList($s->{idSignature});
   my $buf = '';
   for my $osVersion (@$osVersionChildren) {
      $buf .= $osVersion.', ';
   }
   $buf =~ s/, $//;
   print " ($buf)" if $buf;
   print "\n";

   print
      'ID: '. $s->{idSignature}. "\n".
      'Trusted: '.$s->{trusted}."\n";

   for my $h ('Heuristic0', 'Heuristic1', 'Heuristic2') {
      my $mBinaryHeuristic     = 'patternBinary'.$h;
      my $mTcpFlagsHeuristic   = 'patternTcpFlags'.$h;
      my $mTcpWindowHeuristic  = 'patternTcpWindow'.$h;
      my $mTcpOptionsHeuristic = 'patternTcpOptions'.$h;
      my $mTcpMssHeuristic     = 'patternTcpMss'.$h;
      my $mTcpWScaleHeuristic  = 'patternTcpWScale'.$h;
      my $mTcpOLengthHeuristic = 'patternTcpOLength'.$h;
      (my $hn = $h) =~ s/euristic//;
      for my $p ('S1', 'S2', 'S3') {
         my $idBinary     = 'id'.$p.'PatternBinary';
         my $idTcpFlags   = 'id'.$p.'PatternTcpFlags';
         my $idTcpWindow  = 'id'.$p.'PatternTcpWindow';
         my $idTcpOptions = 'id'.$p.'PatternTcpOptions';
         my $idTcpMss     = 'id'.$p.'PatternTcpMss';
         my $idTcpWScale  = 'id'.$p.'PatternTcpWScale';
         my $idTcpOLength = 'id'.$p.'PatternTcpOLength';

         print
            $p.$hn.': '.
            $s->{$p.$mBinaryHeuristic}.' '.
            $s->{$p.$mTcpFlagsHeuristic}.' '.
            $s->{$p.$mTcpWindowHeuristic}.' '.
            $s->{$p.$mTcpOptionsHeuristic}.' '.
            $s->{$p.$mTcpMssHeuristic}.' '.
            $s->{$p.$mTcpWScaleHeuristic}.' '.
            $s->{$p.$mTcpOLengthHeuristic}.
            "\n";
      }
   }

   print "\n";

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::Export - export active signatures

=head1 DESCRIPTION

Go to http://www.networecon.com/tools/sinfp/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
