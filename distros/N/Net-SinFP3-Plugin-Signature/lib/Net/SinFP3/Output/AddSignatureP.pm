#
# $Id: AddSignatureP.pm 22 2015-01-04 16:42:47Z gomor $
#
package Net::SinFP3::Output::AddSignatureP;
use strict;
use warnings;

use base qw(Net::SinFP3::Output);
our @AS = qw(
   trusted
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Data::Dumper;

use Net::SinFP3::Ext::DBI::SignatureP;
use Net::SinFP3::Ext::DBI::IpVersion;
use Net::SinFP3::Ext::DBI::SystemClass;
use Net::SinFP3::Ext::DBI::Vendor;
use Net::SinFP3::Ext::DBI::Os;
use Net::SinFP3::Ext::DBI::OsVersion;
use Net::SinFP3::Ext::DBI::OsVersionFamily;
use Net::SinFP3::Ext::DBI::OsVersionChildren;
use Net::SinFP3::Ext::DBI::PatternTcpFlags;
use Net::SinFP3::Ext::DBI::PatternTcpWindow;
use Net::SinFP3::Ext::DBI::PatternTcpOptions;
use Net::SinFP3::Ext::DBI::PatternTcpMss;
use Net::SinFP3::Ext::DBI::PatternTcpWScale;
use Net::SinFP3::Ext::DBI::PatternTcpOLength;

# For easier access
my $tIpVersion         = 'Net::SinFP3::Ext::DBI::IpVersion';
my $tPatternTcpFlags   = 'Net::SinFP3::Ext::DBI::PatternTcpFlags';
my $tPatternTcpWindow  = 'Net::SinFP3::Ext::DBI::PatternTcpWindow';
my $tPatternTcpOptions = 'Net::SinFP3::Ext::DBI::PatternTcpOptions';
my $tPatternTcpMss     = 'Net::SinFP3::Ext::DBI::PatternTcpMss';
my $tPatternTcpWScale  = 'Net::SinFP3::Ext::DBI::PatternTcpWScale';
my $tPatternTcpOLength = 'Net::SinFP3::Ext::DBI::PatternTcpOLength';
my $tSystemClass       = 'Net::SinFP3::Ext::DBI::SystemClass';
my $tVendor            = 'Net::SinFP3::Ext::DBI::Vendor';
my $tOs                = 'Net::SinFP3::Ext::DBI::Os';
my $tOsVersion         = 'Net::SinFP3::Ext::DBI::OsVersion';
my $tOsVersionFamily   = 'Net::SinFP3::Ext::DBI::OsVersionFamily';
my $tOsVersionChildren = 'Net::SinFP3::Ext::DBI::OsVersionChildren';

sub take {
   return [
      'Net::SinFP3::Result::Passive',
      'Net::SinFP3::Result::Unknown',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      trusted => 0,
      @_,
   );

   return $self;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my $log     = $global->log;
   my $db      = $global->db;
   my @results = $global->result;

   my $r   = $results[0];
   my $ref = ref($r);

   my $buf = '';
   $buf .= 'SP: '.$r->sp->print."\n" if $r->sp;

   $buf .= "[+] Results for target: [".$r->ip."]:".$r->port."\n"
      if $r->ip && $r->port;

   if ($ref =~ /^Net::SinFP3::Result::Unknown$/) {
      $buf .= $r->print;
   }
   elsif ($ref =~ /^Net::SinFP3::Result::Passive$/) {
      for my $r (@results) {
         $buf .= $r->print."\n";
      }
   }
   else {
      $log->error("Don't know what to do with this result object [$ref]");
      return;
   }

   my $sp = $r->sp;
   if ($sp && length($sp->O) <= 9) {
      $buf .= '[!] WARNING: not enough TCP options for SP reply, '.
              'result may be false'."\n";
   }

   print $buf."\n";

   # Disconnect, give access to this process, it is not using
   # the same Perl interface to SQLite
   $db->post;

   my $dbh = Net::SinFP3::Ext::DBI->connection(
      "dbi:SQLite:dbname=".$db->file,
      '',
      '',
      { AutoCommit => 0 },
   );

   my $spToks = $r->sp->print;
   
   my @patternsSP = (split('\s+', $spToks))[0..5];
   
   # Get possible option if a match is similar to this new signature
   my %systemClassList      = ();
   my %vendorList           = ();
   my %osList               = ();
   my %osVersionList        = ();
   my %osVersionFamilyList  = ();
   my $addOsVersionChildren = 0;
   if (@results > 0) {
      for my $o (@results) {
         next unless ref($o) =~ /^Net::SinFP3::Result::Passive$/;
         if ($o->matchMask eq "FH0WH0OH0MH0SH0LH0") {
            print "[-] A HEURISTIC0 match was found, you may want to add an ".
                  "OsVersionChildren instead.\n";
            _addOsVersionChildren($o) && $addOsVersionChildren++;
         }
         $systemClassList    {$o->systemClass}++;
         $vendorList         {$o->vendor}++;
         $osList             {$o->os}++;
         $osVersionList      {$o->osVersion}++;
         $osVersionFamilyList{$o->osVersionFamily}++;
      }
   }
   # We only wanted to add osVersionChildren
   if ($addOsVersionChildren) {
      return 1;
   }
   print "[+] POSSIBLE systemClass    : [", join(' ', keys %systemClassList),
         "]\n";
   print "[+] POSSIBLE vendor         : [", join(' ', keys %vendorList),
         "]\n";
   print "[+] POSSIBLE os             : [", join(' ', keys %osList),
         "]\n";
   print "[+] POSSIBLE osVersion      : [", join(' ', keys %osVersionList),
         "]\n";
   print "[+] POSSIBLE osVersionFamily: [",
         join(' ', keys %osVersionFamilyList), "]\n";
   
   # Add new possible patterns
   for my $p (\@patternsSP) {
      _addNewPatternTcpFlags  ({ patternTcpFlagsHeuristic0   => $p->[0] });
      _addNewPatternTcpWindow ({ patternTcpWindowHeuristic0  => $p->[1] });
      _addNewPatternTcpOptions({ patternTcpOptionsHeuristic0 => $p->[2] });
      _addNewPatternTcpMss    ({ patternTcpMssHeuristic0     => $p->[3] });
      _addNewPatternTcpWScale ({ patternTcpWScaleHeuristic0  => $p->[4] });
      _addNewPatternTcpOLength({ patternTcpOLengthHeuristic0 => $p->[5] });
   }
   
   # Get input from user
   my $systemClass     = _getSystemClass();
   my $vendor          = _getVendor();
   my $os              = _getOs();
   my $osVersion       = _getOsVersion();
   my $osVersionFamily = _getOsVersionFamily();
   
   # Add new possible elements
   my $nSystemClass = _addNewElementSystemClass({
      systemClass => $systemClass,
   });
   my $nVendor          = _addNewElementVendor({ vendor => $vendor });
   my $nOs              = _addNewElementOs({ os => $os });
   my $nOsVersion       = _addNewElementOsVersion({ osVersion => $osVersion });
   my $nOsVersionFamily = _addNewElementOsVersionFamily({
      osVersionFamily => $osVersionFamily,
   });
   
   # Get stored IDs
   my ($idTcpFlagsSP, $idTcpWindowSP, $idTcpOptionsSP, $idTcpMssSP,
       $idTcpWScaleSP, $idTcpOLengthSP) = _selectPatterns(\@patternsSP);
   my @idIpVersion = $tIpVersion->search(
      ipVersion => $global->ipv6 ? 'IPv6' : 'IPv4',
   );
   my $idIpVersion       = $idIpVersion[0]->idIpVersion;
   my $idSystemClass     = $nSystemClass->idSystemClass;
   my $idVendor          = $nVendor->idVendor;
   my $idOs              = $nOs->idOs;
   my $idOsVersion       = $nOsVersion->idOsVersion;
   my $idOsVersionFamily = $nOsVersionFamily->idOsVersionFamily;
   
   # Add the signature
   my $sig = Net::SinFP3::Ext::DBI::SignatureP->insert({
      idIpVersion         => $idIpVersion,
      trusted             => $self->trusted ? 1 : 0,
      idSystemClass       => $idSystemClass,
      idVendor            => $idVendor,
      idOs                => $idOs,
      idOsVersion         => $idOsVersion,
      idOsVersionFamily   => $idOsVersionFamily,
      idPatternTcpFlags   => $idTcpFlagsSP,
      idPatternTcpWindow  => $idTcpWindowSP,
      idPatternTcpOptions => $idTcpOptionsSP,
      idPatternTcpMss     => $idTcpMssSP,
      idPatternTcpWScale  => $idTcpWScaleSP,
      idPatternTcpOLength => $idTcpOLengthSP,
   });
   $sig->update;
   $sig->dbi_commit;

   return 1;
}

sub __getInput {
   my ($type) = @_;
   print "Enter $type:\n";
   my $value;
   while (<>) {
      chomp;
      $value .= $_;
   }
   die("No $type entered") unless $value;
   return $value;
}
sub _getSystemClass     { __getInput('systemClass')     }
sub _getVendor          { __getInput('vendor')          }
sub _getOs              { __getInput('os')              }
sub _getOsVersion       { __getInput('osVersion')       }
sub _getOsVersionFamily { __getInput('osVersionFamily') }
sub _getOsVersionChildren {
   my $list = __getInput('osVersionChildren (comma speparated list)');
   my @osVersionChildrenList = split('\s*,\s*', $list);
   return \@osVersionChildrenList;
}

sub _selectPatterns {
   my ($p) = @_;
   my @idPatternTcpFlags   = $tPatternTcpFlags->search  (patternTcpFlagsHeuristic0 => $p->[0]);
   my @idPatternTcpWindow  = $tPatternTcpWindow->search (patternTcpWindowHeuristic0 => $p->[1]);
   my @idPatternTcpOptions = $tPatternTcpOptions->search(patternTcpOptionsHeuristic0 => $p->[2]);
   my @idPatternTcpMss     = $tPatternTcpMss->search    (patternTcpMssHeuristic0 => $p->[3]);
   my @idPatternTcpWScale  = $tPatternTcpWScale->search (patternTcpWScaleHeuristic0 => $p->[4]);
   my @idPatternTcpOLength = $tPatternTcpOLength->search(patternTcpOLengthHeuristic0 => $p->[5]);
   return (
      $idPatternTcpFlags[0]->idPatternTcpFlags,
      $idPatternTcpWindow[0]->idPatternTcpWindow,
      $idPatternTcpOptions[0]->idPatternTcpOptions,
      $idPatternTcpMss[0]->idPatternTcpMss,
      $idPatternTcpWScale[0]->idPatternTcpWScale,
      $idPatternTcpOLength[0]->idPatternTcpOLength,
   );
}

sub __addNewPattern {
   my ($table, $element) = @_;
   my @search = $table->search(%$element);
   if (@search < 1) {
      my @values = keys %$element;
      my $key    = $values[0];       # We fetch the first and only one key
      my $value  = $element->{$key}; # We fetch first key value
      (my $field = $key) =~ s/Heuristic0$//;
      print "[+] New pattern: [$value] for field [$field]\n";
      print "Enter heuristic1 value (enter CTRL+D on a new line when done):\n";
      my $h1;
      while (<>) {
         chomp;
         $h1 .= $_;
      }
      print "Enter heuristic2 value (enter CTRL+D on a new line when done):\n";
      my $h2;
      while (<>) {
         chomp;
         $h2 .= $_;
      }
      $h1 = $value unless $h1;
      $h2 = $value unless $h2;
      return __addNewElement($table, {
         $field.'Heuristic0' => $value,
         $field.'Heuristic1' => $h1,
         $field.'Heuristic2' => $h2,
      });
   }
   return $search[0];
}

sub _addNewPatternTcpFlags   { __addNewPattern($tPatternTcpFlags,   @_) }
sub _addNewPatternTcpWindow  { __addNewPattern($tPatternTcpWindow,  @_) }
sub _addNewPatternTcpOptions { __addNewPattern($tPatternTcpOptions, @_) }
sub _addNewPatternTcpMss     { __addNewPattern($tPatternTcpMss,     @_) }
sub _addNewPatternTcpWScale  { __addNewPattern($tPatternTcpWScale,  @_) }
sub _addNewPatternTcpOLength { __addNewPattern($tPatternTcpOLength, @_) }

sub __addNewElement {
   my ($table, $element) = @_;
   my @search = $table->search(%$element);
   if (@search < 1) {
      my $new = $table->insert($element);
      $new->update;
      print "[+] Added new element: ",Dumper($element),"\n";
      return $new;
   }
   return $search[0];
}
sub _addNewElementSystemClass       { __addNewElement($tSystemClass,       @_) }
sub _addNewElementVendor            { __addNewElement($tVendor,            @_) }
sub _addNewElementOs                { __addNewElement($tOs,                @_) }
sub _addNewElementOsVersion         { __addNewElement($tOsVersion,         @_) }
sub _addNewElementOsVersionFamily   { __addNewElement($tOsVersionFamily,   @_) }
sub _addNewElementOsVersionChildren { __addNewElement($tOsVersionChildren, @_) }

sub _addOsVersionChildren {
   my ($result) = @_;

   my $idSignatureP = $result->idSignatureP;
   print "Would you like to add OsVersionChildren for this one? (CTRL+D for not)\n".
         "=> [", $result->os, " ", $result->osVersion, "]\n";
   my $input = '';
   while (<>) {
      chomp;
      $input .= $_;
   }
   return unless $input;

   my $osVersionChildrenList = _getOsVersionChildren();
   my @idOsVersionList = ();
   for my $o (@$osVersionChildrenList) {
      my $new = _addNewElementOsVersion({ osVersion => $o });
      push @idOsVersionList, $new->idOsVersion;
   }
   for my $o (@idOsVersionList) {
      _addNewElementOsVersionChildren({
         idSignatureP => $idSignatureP,
         idOsVersion => $o,
      });
   }
   $tOsVersionChildren->dbi_commit;
   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::AddSignatureP - add a passive signature to SinFP3 database

=head1 DESCRIPTION

Passive signatures are TCP SYNs only.

Go to http://www.networecon.com/tools/sinfp/ to know more.

=head1 METHODS

=over 4

=item B<new>

Object constructor.

=item B<run>

Run this plugin.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
