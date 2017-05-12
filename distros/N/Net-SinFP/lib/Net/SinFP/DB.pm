#
# $Id: DB.pm 2236 2015-02-15 17:03:25Z gomor $
#
package Net::SinFP::DB;
use strict;
use warnings;

require DBIx::SQLite::Simple;
our @ISA = qw(DBIx::SQLite::Simple);
our @AS = qw(
   passiveMode
   ipv6

   _tOsVersionChildren

   _cSignature
   _cPatternBinary
   _cPatternTcpFlags
   _cPatternTcpWindow
   _cPatternTcpOptions
   _cPatternTcpMss
   _cIpVersion
   _cSystemClass
   _cVendor
   _cOs
   _cOsVersion
   _cOsVersionFamily
   _cOsVersionChildren
);
our @AA = qw(
   signatureList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

require Net::SinFP::DB::Signature;
require Net::SinFP::DB::IpVersion;
require Net::SinFP::DB::PatternBinary;
require Net::SinFP::DB::PatternTcpFlags;
require Net::SinFP::DB::PatternTcpWindow;
require Net::SinFP::DB::PatternTcpOptions;
require Net::SinFP::DB::PatternTcpMss;
require Net::SinFP::DB::SystemClass;
require Net::SinFP::DB::Vendor;
require Net::SinFP::DB::Os;
require Net::SinFP::DB::OsVersion;
require Net::SinFP::DB::OsVersionFamily;
require Net::SinFP::DB::OsVersionChildren;

sub new {
   shift->SUPER::new(
      passiveMode => 0,
      ipv6        => 0,
      @_,
   );
}

sub lookupOsInfos {
   my $self = shift;
   my ($s) = @_;

   # Already looked up
   return if $s->os;

   # Lookup values
   $s->ipVersion  ($self->_cIpVersion->[$s->idIpVersion]->ipVersion);
   $s->systemClass($self->_cSystemClass->[$s->idSystemClass]->systemClass);
   $s->vendor     ($self->_cVendor->[$s->idVendor]->vendor);
   $s->os         ($self->_cOs->[$s->idOs]->os);
   $s->osVersion  ($self->_cOsVersion->[$s->idOsVersion]->osVersion);
   $s->osVersionFamily($self->_cOsVersionFamily->[$s->idOsVersionFamily]->osVersionFamily);

   my $osVersionChildren = $self->_tOsVersionChildren->select(
      idSignature => $s->idSignature,
   );

   if (@$osVersionChildren) {
      my @osVersion;
      push @osVersion, $self->_cOsVersion->[$_->idOsVersion]->osVersion
         for @$osVersionChildren;
      $s->osVersionChildren(\@osVersion);
   }
   else {
      $s->osVersionChildren([]);
   }
}

sub _cache {
   my $self = shift;

   # Tables only used locally
   my $tSignature         = Net::SinFP::DB::Signature->new;
   my $tIpVersion         = Net::SinFP::DB::IpVersion->new;
   my $tPatternBinary     = Net::SinFP::DB::PatternBinary->new;
   my $tPatternTcpFlags   = Net::SinFP::DB::PatternTcpFlags->new;
   my $tPatternTcpWindow  = Net::SinFP::DB::PatternTcpWindow->new;
   my $tPatternTcpOptions = Net::SinFP::DB::PatternTcpOptions->new;
   my $tPatternTcpMss     = Net::SinFP::DB::PatternTcpMss->new;
   my $tSystemClass       = Net::SinFP::DB::SystemClass->new;
   my $tVendor            = Net::SinFP::DB::Vendor->new;
   my $tOs                = Net::SinFP::DB::Os->new;
   my $tOsVersion         = Net::SinFP::DB::OsVersion->new;
   my $tOsVersionFamily   = Net::SinFP::DB::OsVersionFamily->new;
   my $tOsVersionChildren = Net::SinFP::DB::OsVersionChildren->new;

   # Table used for OsVersionChildren lookup in lookupOsInfos()
   $self->_tOsVersionChildren($tOsVersionChildren);

   $self->_cSignature        ($tSignature->selectById);
   $self->_cPatternBinary    ($tPatternBinary->selectById    );
   $self->_cPatternTcpFlags  ($tPatternTcpFlags->selectById  );
   $self->_cPatternTcpWindow ($tPatternTcpWindow->selectById );
   $self->_cPatternTcpOptions($tPatternTcpOptions->selectById);
   $self->_cPatternTcpMss    ($tPatternTcpMss->selectById    );
   $self->_cIpVersion        ($tIpVersion->selectById        );
   $self->_cSystemClass      ($tSystemClass->selectById      );
   $self->_cVendor           ($tVendor->selectById           );
   $self->_cOs               ($tOs->selectById               );
   $self->_cOsVersion        ($tOsVersion->selectById        );
   $self->_cOsVersionFamily  ($tOsVersionFamily->selectById  );
}

sub _cleanCache {
   my $self = shift;

   $self->_cPatternBinary    (undef);
   $self->_cPatternTcpFlags  (undef);
   $self->_cPatternTcpWindow (undef);
   $self->_cPatternTcpOptions(undef);
   $self->_cPatternTcpMss    (undef);
}

sub _rewriteBinary {
   my $self = shift;
   my ($b) = @_;
   (my $p0 = $b->patternBinaryHeuristic0) =~ s/^B.*/B...../;
   (my $p1 = $b->patternBinaryHeuristic1) =~ s/^B.*/B...../;
   (my $p2 = $b->patternBinaryHeuristic2) =~ s/^B.*/B...../;
   $b->patternBinaryHeuristic0($p0);
   $b->patternBinaryHeuristic1($p1);
   $b->patternBinaryHeuristic2($p2);
}

# In passive mode, the P2 probe is not our own, so timestamp is not
# built as we want. We rewrite it to be able to match.
sub _rewriteTcpOptions {
   my $self = shift;
   my ($o) = @_;
   (my $o0 = $o->patternTcpOptionsHeuristic0) =~ s/44454144/......../;
   (my $o1 = $o->patternTcpOptionsHeuristic1) =~ s/44454144/......../;
   (my $o2 = $o->patternTcpOptionsHeuristic2) =~ s/44454144/......../;
   $o->patternTcpOptionsHeuristic0($o0);
   $o->patternTcpOptionsHeuristic1($o1);
   $o->patternTcpOptionsHeuristic2($o2);
}

sub _sigBuild {
   my $self = shift;
   my ($s) = @_;

   my $p1Binary     = $self->_cPatternBinary->[$s->idP1PatternBinary];
   my $p1TcpFlags   = $self->_cPatternTcpFlags->[$s->idP1PatternTcpFlags];
   my $p1TcpWindow  = $self->_cPatternTcpWindow->[$s->idP1PatternTcpWindow];
   my $p1TcpOptions = $self->_cPatternTcpOptions->[$s->idP1PatternTcpOptions];
   my $p1TcpMss     = $self->_cPatternTcpMss->[$s->idP1PatternTcpMss];

   $self->_rewriteBinary($p1Binary) if $self->passiveMode;

   $s->sigP1H0({
      B => $p1Binary->patternBinaryHeuristic0,
      F => $p1TcpFlags->patternTcpFlagsHeuristic0,
      W => $p1TcpWindow->patternTcpWindowHeuristic0,
      O => $p1TcpOptions->patternTcpOptionsHeuristic0,
      M => $p1TcpMss->patternTcpMssHeuristic0,
   });
   $s->sigP1H1({
      B => $p1Binary->patternBinaryHeuristic1,
      F => $p1TcpFlags->patternTcpFlagsHeuristic1,
      W => $p1TcpWindow->patternTcpWindowHeuristic1,
      O => $p1TcpOptions->patternTcpOptionsHeuristic1,
      M => $p1TcpMss->patternTcpMssHeuristic1,
   });
   $s->sigP1H2({
      B => $p1Binary->patternBinaryHeuristic2,
      F => $p1TcpFlags->patternTcpFlagsHeuristic2,
      W => $p1TcpWindow->patternTcpWindowHeuristic2,
      O => $p1TcpOptions->patternTcpOptionsHeuristic2,
      M => $p1TcpMss->patternTcpMssHeuristic2,
   });

   my $p2Binary     = $self->_cPatternBinary->[$s->idP2PatternBinary];
   my $p2TcpFlags   = $self->_cPatternTcpFlags->[$s->idP2PatternTcpFlags];
   my $p2TcpWindow  = $self->_cPatternTcpWindow->[$s->idP2PatternTcpWindow];
   my $p2TcpOptions = $self->_cPatternTcpOptions->[$s->idP2PatternTcpOptions];
   my $p2TcpMss     = $self->_cPatternTcpMss->[$s->idP2PatternTcpMss];

   # XXX: should move to _passiveMatchUpdate() in SinFP.pm
   if ($self->passiveMode) {
      $self->_rewriteBinary($p2Binary);
      $self->_rewriteTcpOptions($p2TcpOptions);
   }

   $s->sigP2H0({
      B => $p2Binary->patternBinaryHeuristic0,
      F => $p2TcpFlags->patternTcpFlagsHeuristic0,
      W => $p2TcpWindow->patternTcpWindowHeuristic0,
      O => $p2TcpOptions->patternTcpOptionsHeuristic0,
      M => $p2TcpMss->patternTcpMssHeuristic0,
   });
   $s->sigP2H1({
      B => $p2Binary->patternBinaryHeuristic1,
      F => $p2TcpFlags->patternTcpFlagsHeuristic1,
      W => $p2TcpWindow->patternTcpWindowHeuristic1,
      O => $p2TcpOptions->patternTcpOptionsHeuristic1,
      M => $p2TcpMss->patternTcpMssHeuristic1,
   });
   $s->sigP2H2({
      B => $p2Binary->patternBinaryHeuristic2,
      F => $p2TcpFlags->patternTcpFlagsHeuristic2,
      W => $p2TcpWindow->patternTcpWindowHeuristic2,
      O => $p2TcpOptions->patternTcpOptionsHeuristic2,
      M => $p2TcpMss->patternTcpMssHeuristic2,
   });

   my $p3Binary     = $self->_cPatternBinary->[$s->idP3PatternBinary];
   my $p3TcpFlags   = $self->_cPatternTcpFlags->[$s->idP3PatternTcpFlags];
   my $p3TcpWindow  = $self->_cPatternTcpWindow->[$s->idP3PatternTcpWindow];
   my $p3TcpOptions = $self->_cPatternTcpOptions->[$s->idP3PatternTcpOptions];
   my $p3TcpMss     = $self->_cPatternTcpMss->[$s->idP3PatternTcpMss];

   $self->_rewriteBinary($p3Binary) if $self->passiveMode;

   $s->sigP3H0({
      B => $p3Binary->patternBinaryHeuristic0,
      F => $p3TcpFlags->patternTcpFlagsHeuristic0,
      W => $p3TcpWindow->patternTcpWindowHeuristic0,
      O => $p3TcpOptions->patternTcpOptionsHeuristic0,
      M => $p3TcpMss->patternTcpMssHeuristic0,
   });
   $s->sigP3H1({
      B => $p3Binary->patternBinaryHeuristic1,
      F => $p3TcpFlags->patternTcpFlagsHeuristic1,
      W => $p3TcpWindow->patternTcpWindowHeuristic1,
      O => $p3TcpOptions->patternTcpOptionsHeuristic1,
      M => $p3TcpMss->patternTcpMssHeuristic1,
   });
   $s->sigP3H2({
      B => $p3Binary->patternBinaryHeuristic2,
      F => $p3TcpFlags->patternTcpFlagsHeuristic2,
      W => $p3TcpWindow->patternTcpWindowHeuristic2,
      O => $p3TcpOptions->patternTcpOptionsHeuristic2,
      M => $p3TcpMss->patternTcpMssHeuristic2,
   });
}

sub loadSignatures {
   my $self = shift;

   $self->_cache;

   # Tables only used locally
   my $tSignature = Net::SinFP::DB::Signature->new;
   my $tIpVersion = Net::SinFP::DB::IpVersion->new;

   my $ipVersion     = $self->ipv6 ? 'IPv6' : 'IPv4';
   my $idIpVersion   = $tIpVersion->getIdIpVersion($ipVersion);
   my $signatureList = $tSignature->select(idIpVersion => $idIpVersion);
   die("Unable to load signatures from sinfp.db.\n".
       "Try installing latest DBD::SQLite module.\n")
      unless scalar @$signatureList;

   $self->_sigBuild($_) for @$signatureList;

   # Remove no more needed cache entries, to save memory
   $self->_cleanCache;

   $self->signatureList($signatureList);
}

sub getSignature { shift->_cSignature->[shift()] }

1;

=head1 NAME

Net::SinFP::DB - main access to signature database

=head1 DESCRIPTION

Go to http://www.gomor.org/sinfp to know more.

=cut

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
