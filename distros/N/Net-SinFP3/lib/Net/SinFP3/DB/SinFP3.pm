#
# $Id: SinFP3.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::DB::SinFP3;
use strict;
use warnings;

use base qw(Net::SinFP3::DB);
our @AS = qw(
   file
   _dbh
   _prepared
);
our @AA = qw(
   _PatternBinary
   _PatternTcpFlags
   _PatternTcpWindow
   _PatternTcpOptions
   _PatternTcpMss
   _PatternTcpWScale
   _PatternTcpOLength
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use DBI;
use Data::Dumper;

use FindBin qw($Bin);
use LWP::UserAgent;
use Digest::MD5;

sub new {
   my $self = shift->SUPER::new(
      _dbh               => 0,
      _PatternBinary     => [],
      _PatternTcpFlags   => [],
      _PatternTcpWindow  => [],
      _PatternTcpOptions => [],
      _PatternTcpMss     => [],
      _PatternTcpWScale  => [],
      _PatternTcpOLength => [],
      @_,
   );

   my $log = $self->global->log;

   my $file = $self->file;
   if (!defined($file)) {
      for ("$Bin/", "$Bin/../db/") {
         if (-f $_.'sinfp3.db') {
            $file = $_.'sinfp3.db';
            last;
         }
      }
   }

   if (!defined($file)) {
      $log->fatal("No database file found");
   }
   elsif (!-f $file) {
      $log->fatal("Database file not found [$file]: $!");
   }

   $self->file($file);

   return $self;
}

sub getOsVersionChildrenList {
   my $self = shift;
   my ($id) = @_;

   my $dbh = $self->_dbh;
   my $idOsVersion = $self->_prepared->{idOsVersion};
   my $rv = $idOsVersion->execute($id);
   my $h = $idOsVersion->fetchall_hashref('idOsVersion');

   my @osVersionList = ();
   my $sOsVersion = $self->_prepared->{osVersion};
   for my $k (keys %$h) {
      my $rv = $sOsVersion->execute($k);
      my $h = $sOsVersion->fetchrow_hashref;
      push @osVersionList, $h->{osVersion};
   }

   return \@osVersionList;
}

sub getOsVersionChildrenPList {
   my $self = shift;
   my ($id) = @_;

   my $dbh = $self->_dbh;
   my $s   = $dbh->prepare(qq{SELECT idOsVersion FROM OsVersionChildren WHERE idSignatureP=?});
   my $rv  = $s->execute($id);
   my $h   = $s->fetchall_hashref('idOsVersion');

   my @osVersionList = ();
   my $sOsVersion = $dbh->prepare(qq{SELECT osVersion FROM OsVersion WHERE idOsVersion=?});
   for my $k (keys %$h) {
      my $rv = $sOsVersion->execute($k);
      my $h  = $sOsVersion->fetchrow_hashref;
      push @osVersionList, $h->{osVersion};
   }

   return \@osVersionList;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;

   $log->verbose("Using database file: ".$self->file);

   my $dbh = DBI->connect(
      "dbi:SQLite:dbname=".$self->file, '', '', {
      sqlite_use_immediate_transaction => 0,  # Avoid lock
      RaiseError => 0,
      PrintError => 0,
      AutoCommit => 0,
      HandleError => sub {
         my ($errstr, $dbh, $arg) = @_;
         # Let's keep fatal() for all errors as a debugging mechanism for now
         $log->fatal("Database error: [$errstr]");
         return 1;
      },
   }) or $log->fatal("Database error: [".$DBI::errstr."]");
   $self->_dbh($dbh);

   my $sSignature  = $dbh->prepare(qq{SELECT count(*) from Signature});
   my $sSignatureP = $dbh->prepare(qq{SELECT count(*) from SignatureP});

   # We fail if Signature or SignatureP is empty
   # The problem may be solved by using the latest DBD::SQLite module
   my $rv = $sSignature->execute;
   my $h  = $sSignature->fetchrow_hashref;
   my ($k, $v) = each(%$h);
   return unless $v > 0;

   $rv = $sSignatureP->execute;
   $h  = $sSignatureP->fetchrow_hashref;
   ($k, $v) = each(%$h);
   return unless $v > 0;

   # Cache tables for future matching
   for my $tPattern (qw(
      PatternBinary
      PatternTcpFlags
      PatternTcpWindow
      PatternTcpOptions
      PatternTcpMss
      PatternTcpWScale
      PatternTcpOLength
   )) {
      my $_table = "_$tPattern";
      my $id = 'id'.$tPattern;
      my $s  = $dbh->prepare(qq{SELECT * FROM $tPattern});
      my $rv = $s->execute;
      my $h  = $s->fetchall_hashref($id);
      my @ary = ();
      for my $k (keys %$h) {
         push @ary, $h->{$k};
      }
      #print Dumper(\@ary),"\n";
      $self->$_table(\@ary);
   }

   # Create prepared statements
   $self->_prepare;

   return 1;
}

sub _prepare {
   my $self = shift;

   my $dbh = $self->_dbh;

   my %select = (
      idOsVersion => qq{SELECT idOsVersion FROM OsVersionChildren WHERE idSignature=?},

      osVersion => qq{SELECT osVersion FROM OsVersion WHERE idOsVersion=?},
      ipVersion => qq{SELECT ipVersion FROM IpVersion WHERE idIpVersion=?},
      os => qq{SELECT os FROM Os WHERE idOs=?},
      osVersionFamily => qq{SELECT osVersionFamily FROM OsVersionFamily WHERE idOsVersionFamily=?},
      systemClass => qq{SELECT systemClass FROM SystemClass WHERE idSystemClass=?},
      vendor => qq{SELECT vendor FROM Vendor WHERE idVendor=?},

      patternBinary => qq{SELECT * FROM PatternBinary WHERE idPatternBinary=?},
      patternTcpFlags => qq{SELECT * FROM PatternTcpFlags WHERE idPatternTcpFlags=?},
      patternTcpWindow => qq{SELECT * FROM PatternTcpWindow WHERE idPatternTcpWindow=?},
      patternTcpOptions => qq{SELECT * FROM PatternTcpOptions WHERE idPatternTcpOptions=?},
      patternTcpMss => qq{SELECT * FROM PatternTcpMss WHERE idPatternTcpMss=?},
      patternTcpWScale => qq{SELECT * FROM PatternTcpWScale WHERE idPatternTcpWScale=?},
      patternTcpOLength => qq{SELECT * FROM PatternTcpOLength WHERE idPatternTcpOLength=?},
      signature => qq{SELECT * FROM Signature WHERE idSignature=?},

      idS1PatternBinary     => qq{SELECT idSignature FROM Signature WHERE idS1PatternBinary=?},
      idS1PatternTcpFlags   => qq{SELECT idSignature FROM Signature WHERE idS1PatternTcpFlags=?},
      idS1PatternTcpWindow  => qq{SELECT idSignature FROM Signature WHERE idS1PatternTcpWindow=?},
      idS1PatternTcpOptions => qq{SELECT idSignature FROM Signature WHERE idS1PatternTcpOptions=?},
      idS1PatternTcpMss     => qq{SELECT idSignature FROM Signature WHERE idS1PatternTcpMss=?},
      idS1PatternTcpWScale  => qq{SELECT idSignature FROM Signature WHERE idS1PatternTcpWScale=?},
      idS1PatternTcpOLength => qq{SELECT idSignature FROM Signature WHERE idS1PatternTcpOLength=?},
      idS2PatternBinary     => qq{SELECT idSignature FROM Signature WHERE idS2PatternBinary=?},
      idS2PatternTcpFlags   => qq{SELECT idSignature FROM Signature WHERE idS2PatternTcpFlags=?},
      idS2PatternTcpWindow  => qq{SELECT idSignature FROM Signature WHERE idS2PatternTcpWindow=?},
      idS2PatternTcpOptions => qq{SELECT idSignature FROM Signature WHERE idS2PatternTcpOptions=?},
      idS2PatternTcpMss     => qq{SELECT idSignature FROM Signature WHERE idS2PatternTcpMss=?},
      idS2PatternTcpWScale  => qq{SELECT idSignature FROM Signature WHERE idS2PatternTcpWScale=?},
      idS2PatternTcpOLength => qq{SELECT idSignature FROM Signature WHERE idS2PatternTcpOLength=?},
      idS3PatternBinary     => qq{SELECT idSignature FROM Signature WHERE idS3PatternBinary=?},
      idS3PatternTcpFlags   => qq{SELECT idSignature FROM Signature WHERE idS3PatternTcpFlags=?},
      idS3PatternTcpWindow  => qq{SELECT idSignature FROM Signature WHERE idS3PatternTcpWindow=?},
      idS3PatternTcpOptions => qq{SELECT idSignature FROM Signature WHERE idS3PatternTcpOptions=?},
      idS3PatternTcpMss     => qq{SELECT idSignature FROM Signature WHERE idS3PatternTcpMss=?},
      idS3PatternTcpWScale  => qq{SELECT idSignature FROM Signature WHERE idS3PatternTcpWScale=?},
      idS3PatternTcpOLength => qq{SELECT idSignature FROM Signature WHERE idS3PatternTcpWScale=?},
      all                   => qq{SELECT idSignature FROM Signature},
      idPatternTcpFlags   => qq{SELECT idSignatureP from SignatureP WHERE idPatternTcpFlags=?},
      idPatternTcpWindow  => qq{SELECT idSignatureP from SignatureP WHERE idPatternTcpWindow=?},
      idPatternTcpOptions => qq{SELECT idSignatureP from SignatureP WHERE idPatternTcpOptions=?},
      idPatternTcpMss     => qq{SELECT idSignatureP from SignatureP WHERE idPatternTcpMss=?},
      idPatternTcpWScale  => qq{SELECT idSignatureP from SignatureP WHERE idPatternTcpWScale=?},
      idPatternTcpOLength => qq{SELECT idSignatureP from SignatureP WHERE idPatternTcpOLength=?},
      allP                => qq{SELECT idSignatureP FROM SignatureP},
   );

   my %prepared = ();
   for my $this (keys %select) {
      my $select = $dbh->prepare($select{$this});
      $prepared{$this} = $select;
   }

   $self->_prepared(\%prepared);

   return 1;
}

sub searchSignatureIds {
   my $self = shift;
   my ($key, $value) = @_;

   my $dbh = $self->_dbh;

   my $select = $self->_prepared->{$key || 'all'};

   my $rv;
   # First case, we want only a subset of all signatures
   if ($value) {
      $rv = $select->execute($value);
   }
   # Second case, we want all signature IDs
   else {
      $rv = $select->execute;
   }

   my @list = ();
   my $a = $select->fetchall_arrayref;
   for my $id (@$a) {
      push @list, @$id;
   }

   return \@list;
}

sub searchSignaturePIds {
   my $self = shift;
   my ($key, $value) = @_;

   my $dbh = $self->_dbh;

   my $select = $self->_prepared->{$key || 'allP'};

   my $rv;
   # First case, we want only a subset of all signatures
   if ($value) {
      $rv = $select->execute($value);
   }
   # Second case, we want all signature IDs
   else {
      $rv = $select->execute;
   }

   my @list = ();
   my $a = $select->fetchall_arrayref;
   for my $id (@$a) {
      push @list, @$id;
   }

   return \@list;
}

sub _lookupSignature {
   my $self = shift;
   my ($h) = @_;

   my $dbh = $self->_dbh;

   my $prepared = $self->_prepared;

   my $sIpVersion = $prepared->{ipVersion};
   my $sOs = $prepared->{os};
   my $sOsVersion = $prepared->{osVersion};
   my $sOsVersionFamily = $prepared->{osVersionFamily};
   my $sSystemClass = $prepared->{systemClass};
   my $sVendor = $prepared->{vendor};

   my $rv;
   $rv = $sIpVersion->execute($h->{idIpVersion});
   $rv = $sOs->execute($h->{idOs});
   $rv = $sOsVersion->execute($h->{idOsVersion});
   $rv = $sOsVersionFamily->execute($h->{idOsVersionFamily});
   $rv = $sSystemClass->execute($h->{idSystemClass});
   $rv = $sVendor->execute($h->{idVendor});

   my $ipVersion       = $sIpVersion->fetchrow_hashref;
   my $os              = $sOs->fetchrow_hashref;
   my $osVersion       = $sOsVersion->fetchrow_hashref;
   my $osVersionFamily = $sOsVersionFamily->fetchrow_hashref;
   my $systemClass     = $sSystemClass->fetchrow_hashref;
   my $vendor          = $sVendor->fetchrow_hashref;

   my %l = (
      %$h,
      trusted         => $h->{trusted},
      ipVersion       => $ipVersion->{ipVersion},
      os              => $os->{os},
      osVersion       => $osVersion->{osVersion},
      osVersionFamily => $osVersionFamily->{osVersionFamily},
      systemClass     => $systemClass->{systemClass},
      vendor          => $vendor->{vendor},
   );
   if (exists($h->{idSignature})) {
      $l{idSignature} = $h->{idSignature};
   }
   else {
      $l{idSignatureP} = $h->{idSignatureP};
   }

   return \%l;
}

sub lookupPatterns {
   my $self = shift;
   my ($signature) = @_;

   my $dbh = $self->_dbh;

   my $prepared = $self->_prepared;

   my $sBinary = $prepared->{patternBinary};
   my $sTcpFlags = $prepared->{patternTcpFlags};
   my $sTcpWindow = $prepared->{patternTcpWindow};
   my $sTcpOptions = $prepared->{patternTcpOptions};
   my $sTcpMss = $prepared->{patternTcpMss};
   my $sTcpWScale = $prepared->{patternTcpWScale};
   my $sTcpOLength = $prepared->{patternTcpOLength};

   for my $p ('S1', 'S2', 'S3') {
      my $idBinary     = 'id'.$p.'PatternBinary';
      my $idTcpFlags   = 'id'.$p.'PatternTcpFlags';
      my $idTcpWindow  = 'id'.$p.'PatternTcpWindow';
      my $idTcpOptions = 'id'.$p.'PatternTcpOptions';
      my $idTcpMss     = 'id'.$p.'PatternTcpMss';
      my $idTcpWScale  = 'id'.$p.'PatternTcpWScale';
      my $idTcpOLength = 'id'.$p.'PatternTcpOLength';

      my $rv     = $sBinary->execute($signature->{$idBinary});
      my $binary = $sBinary->fetchrow_hashref;

      $rv          = $sTcpFlags->execute($signature->{$idTcpFlags});
      my $tcpFlags = $sTcpFlags->fetchrow_hashref;

      $rv           = $sTcpWindow->execute($signature->{$idTcpWindow});
      my $tcpWindow = $sTcpWindow->fetchrow_hashref;

      $rv            = $sTcpOptions->execute($signature->{$idTcpOptions});
      my $tcpOptions = $sTcpOptions->fetchrow_hashref;

      $rv        = $sTcpMss->execute($signature->{$idTcpMss});
      my $tcpMss = $sTcpMss->fetchrow_hashref;

      $rv           = $sTcpWScale->execute($signature->{$idTcpWScale});
      my $tcpWScale = $sTcpWScale->fetchrow_hashref;

      $rv            = $sTcpOLength->execute($signature->{$idTcpOLength});
      my $tcpOLength = $sTcpOLength->fetchrow_hashref;

      for my $h ('Heuristic0', 'Heuristic1', 'Heuristic2') {
         my $mBinaryHeuristic     = 'patternBinary'.$h;
         my $mTcpFlagsHeuristic   = 'patternTcpFlags'.$h;
         my $mTcpWindowHeuristic  = 'patternTcpWindow'.$h;
         my $mTcpOptionsHeuristic = 'patternTcpOptions'.$h;
         my $mTcpMssHeuristic     = 'patternTcpMss'.$h;
         my $mTcpWScaleHeuristic  = 'patternTcpWScale'.$h;
         my $mTcpOLengthHeuristic = 'patternTcpOLength'.$h;

         $signature->{$p.$mBinaryHeuristic}     = $binary->{$mBinaryHeuristic};
         $signature->{$p.$mTcpFlagsHeuristic}   = $tcpFlags->{$mTcpFlagsHeuristic};
         $signature->{$p.$mTcpWindowHeuristic}  = $tcpWindow->{$mTcpWindowHeuristic};
         $signature->{$p.$mTcpOptionsHeuristic} = $tcpOptions->{$mTcpOptionsHeuristic};
         $signature->{$p.$mTcpMssHeuristic}     = $tcpMss->{$mTcpMssHeuristic};
         $signature->{$p.$mTcpWScaleHeuristic}  = $tcpWScale->{$mTcpWScaleHeuristic};
         $signature->{$p.$mTcpOLengthHeuristic} = $tcpOLength->{$mTcpOLengthHeuristic};
      }
   }

   return $signature;
}

sub lookupPatternsP {
   my $self = shift;
   my ($signature) = @_;

   my $dbh = $self->_dbh;

   my $sBinary = $dbh->prepare(
      qq{SELECT * FROM PatternBinary WHERE idPatternBinary=?}
   );
   my $sTcpFlags = $dbh->prepare(
      qq{SELECT * FROM PatternTcpFlags WHERE idPatternTcpFlags=?}
   );
   my $sTcpWindow = $dbh->prepare(
      qq{SELECT * FROM PatternTcpWindow WHERE idPatternTcpWindow=?}
   );
   my $sTcpOptions = $dbh->prepare(
      qq{SELECT * FROM PatternTcpOptions WHERE idPatternTcpOptions=?}
   );
   my $sTcpMss = $dbh->prepare(
      qq{SELECT * FROM PatternTcpMss WHERE idPatternTcpMss=?}
   );
   my $sTcpWScale = $dbh->prepare(
      qq{SELECT * FROM PatternTcpWScale WHERE idPatternTcpWScale=?}
   );
   my $sTcpOLength = $dbh->prepare(
      qq{SELECT * FROM PatternTcpOLength WHERE idPatternTcpOLength=?}
   );

   my $idTcpFlags   = 'idPatternTcpFlags';
   my $idTcpWindow  = 'idPatternTcpWindow';
   my $idTcpOptions = 'idPatternTcpOptions';
   my $idTcpMss     = 'idPatternTcpMss';
   my $idTcpWScale  = 'idPatternTcpWScale';
   my $idTcpOLength = 'idPatternTcpOLength';

   my $rv       = $sTcpFlags->execute($signature->{$idTcpFlags});
   my $tcpFlags = $sTcpFlags->fetchrow_hashref;

   $rv           = $sTcpWindow->execute($signature->{$idTcpWindow});
   my $tcpWindow = $sTcpWindow->fetchrow_hashref;

   $rv            = $sTcpOptions->execute($signature->{$idTcpOptions});
   my $tcpOptions = $sTcpOptions->fetchrow_hashref;

   $rv        = $sTcpMss->execute($signature->{$idTcpMss});
   my $tcpMss = $sTcpMss->fetchrow_hashref;

   $rv           = $sTcpWScale->execute($signature->{$idTcpWScale});
   my $tcpWScale = $sTcpWScale->fetchrow_hashref;

   $rv            = $sTcpOLength->execute($signature->{$idTcpOLength});
   my $tcpOLength = $sTcpOLength->fetchrow_hashref;

   for my $h ('Heuristic0', 'Heuristic1', 'Heuristic2') {
      my $mTcpFlagsHeuristic   = 'patternTcpFlags'.$h;
      my $mTcpWindowHeuristic  = 'patternTcpWindow'.$h;
      my $mTcpOptionsHeuristic = 'patternTcpOptions'.$h;
      my $mTcpMssHeuristic     = 'patternTcpMss'.$h;
      my $mTcpWScaleHeuristic  = 'patternTcpWScale'.$h;
      my $mTcpOLengthHeuristic = 'patternTcpOLength'.$h;

      $signature->{$mTcpFlagsHeuristic}   = $tcpFlags->{$mTcpFlagsHeuristic};
      $signature->{$mTcpWindowHeuristic}  = $tcpWindow->{$mTcpWindowHeuristic};
      $signature->{$mTcpOptionsHeuristic} = $tcpOptions->{$mTcpOptionsHeuristic};
      $signature->{$mTcpMssHeuristic}     = $tcpMss->{$mTcpMssHeuristic};
      $signature->{$mTcpWScaleHeuristic}  = $tcpWScale->{$mTcpWScaleHeuristic};
      $signature->{$mTcpOLengthHeuristic} = $tcpOLength->{$mTcpOLengthHeuristic};
   }

   return $signature;
}

sub retrieveSignature {
   my $self = shift;
   my ($id) = @_;

   my $select = $self->_prepared->{signature};
   my $rv = $select->execute($id);
   my $h = $select->fetchrow_hashref;

   my $signature = $self->_lookupSignature($h);

   return $signature;
}

sub retrieveSignatureP {
   my $self = shift;
   my ($id) = @_;

   my $dbh    = $self->_dbh;
   my $select = $dbh->prepare(qq{SELECT * FROM SignatureP WHERE idSignatureP=?});
   my $rv     = $select->execute($id);
   my $h      = $select->fetchrow_hashref;

   my $signature = $self->_lookupSignature($h);

   return $signature;
}

sub post {
   my $self = shift;

   if ($self->_dbh) {
      my $prepared = $self->_prepared;
      for (keys %$prepared) {
         undef($prepared->{$_});
      }
      $self->_dbh->disconnect;
   }

   return 1;
}

sub _updateDb {
   my $self = shift;
   my ($ua) = @_;

   my $log = $self->global->log;

   my $dbFile = $self->file;

   my $url = "http://www.metabrik.org/wp-content/files/sinfp/sinfp3-latest.db";
   my $db  = $ua->get($url);
   if ($db->is_success) {
      open(my $out, '>', $dbFile) or $log->fatal(
         "open2: $dbFile: $!"
      );
      print $out $db->decoded_content;
      CORE::close($out);
   }
   else {
      $log->fatal("GET [$url]: ".$db->status_line);
   }
   $log->info("Update complete for [$dbFile]");

   return 1;
}

sub update {
   my $self = shift;

   my $log = $self->global->log;

   my $ua = LWP::UserAgent->new;
   $ua->timeout(10);
   $ua->env_proxy;
   $ua->agent("Net::SinFP3 ".$Net::SinFP3::VERSION);

   my $dbFile = $self->file;

   my $url = "http://www.metabrik.org/wp-content/files/sinfp/sinfp3-latest.db.md5";
   my $db  = $ua->get($url);
   if ($db->is_success) {
      (my $md5 = $db->decoded_content) =~ s/^.*=\s+(.*)$/$1/;
      chomp($md5);
      open(my $in, '<', $dbFile) or $log->fatal(
         "open1: $dbFile: $!"
      );
      my $old = Digest::MD5->new;
      $old->addfile($in);
      my $oldmd5 = $old->hexdigest;
      CORE::close($in);
      if ($oldmd5 ne $md5) {
         $self->_updateDb($ua);
      }
      else {
         $log->info("Database already up-to-date");
      }
   }
   else {
      $log->fatal("GET [$url]: ". $db->status_line);
   }

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::DB::SinFP3 - main access to signature database

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
