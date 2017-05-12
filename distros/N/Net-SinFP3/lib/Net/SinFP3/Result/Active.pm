#
# $Id: Active.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Result::Active;
use strict;
use warnings;

use base qw(Net::SinFP3::Result);
our @AS = qw(
   ip
   port
   hostname
   reverse
   frame

   s1
   s2
   s3

   trusted
   idSignature
   ipVersion
   systemClass
   vendor
   os
   osVersion
   osVersionFamily
   matchType
   matchMask
   matchScore
);
our @AA = qw(
   osVersionChildrenList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::SinFP3::Ext::S;

sub take {
   return [
      'Net::SinFP3::Search::Active',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      ip                    => '127.0.0.1',
      port                  => '1',
      hostname              => 'unknown',
      reverse               => 'unknown',
      osVersionChildrenList => [],
      @_,
   );

   return $self;
}

sub getPossibleOsList {
   my $self = shift;
   my ($resultList) = @_;

   my %os = ();
   for my $r (@$resultList) {
      $os{$r->os}++;
   }

   my @osList = ();
   if (keys %os > 0) {
      @osList = map { $_ } keys %os;
   }

   return \@osList;
}

sub updateMatchScore {
   my $self = shift;
   my $score = {
      'OH1' => 18,
      'WH1' => 10,
      'BH1' => 6,
      'SH1' => 6,
      'FH1' => 4,
      'MH1' => 4,
      'LH1' => 4,

      'OH0' => 37,
      'WH0' => 21,
      'BH0' => 12,
      'SH0' => 12,
      'FH0' => 6,
      'MH0' => 6,
      'LH0' => 6,

      'BH2' => 0,
      'FH2' => 0,
      'WH2' => 0,
      'OH2' => 0,
      'MH2' => 0,
      'SH2' => 0,
      'LH2' => 0,
   };
   my $matchMask = $self->matchMask;
   my @toks      = $matchMask =~ /(BH.)(FH.)(WH.)(OH.)(MH.)(SH.)(LH.)/;
   my $result    = 0;
   for (@toks) {
      $result += $score->{$_};
   }
   return $self->matchScore($result);
}

sub printSignature {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;

   my $buf = '';
   $buf .= "Result for target [".$self->ip."]:".$self->port.":";
   $buf .= "\nS1: ".$self->s1->print if $self->s1;
   $buf .= "\nS2: ".$self->s2->print if $self->s2;
   $buf .= "\nS3: ".$self->s3->print if $self->s3;

   if ($self->s2) {
      my $s2 = $self->s2;
      if ($s2 && length($s2->O) <= 9) {
         $buf .= "\n> WARNING: not enough TCP options for P2 reply, results ".
                 "may be false";
      }
   }

   return $buf;
}

sub print {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;

   my $buf = $self->ipVersion;
   if ($log->level > 2) {
      $buf .= "[".$self->idSignature."]";
   }
   $buf .= ": [score:".$self->matchScore."]";
   $buf .= ': '.$self->matchMask.'/'.$self->matchType.
      ': '.$self->systemClass.
      ': '.$self->vendor.
      ': '.$self->os.
      ': '.$self->osVersion
   ;

   my $buf2 = '';
   for my $os ($self->osVersionChildrenList) {
      $buf2 .= "$os, ";
   }
   $buf2 =~ s/, $//;
   if (length($buf2)) {
      $buf .= " ($buf2)";
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::SinFP3::Result::Active - contains all information about matched fingerprint

=head1 SYNOPSIS

   # A SinFP object has previously been created,
   # used, and some matches have been found

   for my $r ($sinfp->resultList) {
      print 'idSignature:     '.$r->idSignature    ."\n";
      print 'ipVersion:       '.$r->ipVersion      ."\n";
      print 'systemClass:     '.$r->systemClass    ."\n";
      print 'vendor:          '.$r->vendor         ."\n";
      print 'os:              '.$r->os             ."\n";
      print 'osVersion:       '.$r->osVersion      ."\n";
      print 'osVersionFamily: '.$r->osVersionFamily."\n";
      print 'matchType:       '.$r->matchType      ."\n";
      print 'matchMask:       '.$r->matchMask      ."\n";
      print 'matchScore:      '.$r->matchScore     ."\n";

      for ($r->osVersionChildrenList) {
         print "osVersionChildren: $_\n";
      }

      print "\n";
   }

   # Or use the print method
   for my $r ($sinfp->resultList) {
      print $r->print;
   }

=head1 DESCRIPTION

This module is the "result" object, used to ask SinFP which operating systems have matched by searching from the signature database.

=head1 METHODS

=over 4

=item B<new>

Object constructor.

=item B<printSignature>

Display computed signature.

=item B<print>

Display the complete result details.

=item B<updateMatchScore>

Re-compute the match score (based on the match mask).

=back

=head1 ATTRIBUTES

=over 4

=item B<idSignature>

=item B<ipVersion>

=item B<systemClass>

=item B<vendor>

=item B<os>

=item B<osVersion>

=item B<osVersionFamily>

=item B<matchType>

=item B<matchMask>

=item B<matchScore>

Standard attributes, names are self explanatory.

=item B<osVersionChildrenList>

This one returns an array of OS version children. For example, if a Linux 2.6.x matches, you may have more known versions from this array (2.6.18, ...).

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
