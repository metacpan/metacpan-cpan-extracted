#
# $Id: Search.pm 2236 2015-02-15 17:03:25Z gomor $
#
package Net::SinFP::Search;
use strict;
use warnings;

require Class::Gomor::Array;
our @ISA = qw(Class::Gomor::Array);

our @AS = qw(
   db
   sigP1
   sigP2
   sigP3
   useAdvancedMasks
   ipv6
   enableP2Match
);
our @AA = qw(
   maskStandardList
   maskAdvancedList
   maskUserList
   resultList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::SinFP::Consts qw(:matchType :matchMask);
require Net::SinFP::Result;

sub new {
   my $self = shift->SUPER::new(
      useAdvancedMasks => 0,
      ipv6             => 0,
      maskUserList     => [],
      enableP2Match    => 0,
      @_,
   );

   if (! $self->db) {
      confess("You MUST specify an open SinFP DB in `db' attribute\n");
   }

   $self->maskStandardList([
      'BH0FH0WH0OH0MH0',
      'BH1FH0WH0OH0MH0',
      'BH0FH0WH0OH0MH1',
      'BH0FH0WH1OH0MH0',
      'BH0FH0WH1OH0MH1',
      'BH1FH0WH0OH0MH1',
      'BH1FH0WH1OH0MH1',
      'BH0FH0WH0OH1MH0',
      'BH1FH0WH0OH1MH0',
   ]);

   $self->maskAdvancedList([
      'BH0FH0WH1OH1MH1',
      'BH1FH0WH1OH1MH1',
      'BH0FH0WH1OH0MH2',
      'BH0FH0WH2OH0MH0',
      'BH0FH0WH2OH0MH1',
      'BH0FH0WH2OH0MH2',
      'BH0FH0WH0OH2MH0',
      'BH0FH0WH1OH2MH1',
      'BH2FH0WH0OH0MH1',
      'BH2FH0WH1OH0MH1',
      'BH2FH0WH1OH1MH1',
      'BH2FH0WH2OH0MH2',
      'BH0FH0WH2OH1MH2',
      'BH1FH0WH2OH1MH2',
      'BH2FH2WH2OH2MH2',
   ]);

   $self;
}

sub __findPossibleSpace {
   my $self = shift;
   my ($src, $s, $a, $result) = @_;
   for my $f ('B', 'F', 'W', 'O', 'M') {
      for my $h ('H0', 'H1', 'H2') {
         my $method = $a.$h;
         my $dst = $s->$method->{$f};
         if ($src->{$f} =~ /^$dst$/) {
            $$result->{$f.$h}->{$s->idSignature} = $dst;
         }
      }
   }
}

sub _findPossibleSpace {
   my $self = shift;

   my $s1 = $self->sigP1;
   my $s2 = $self->sigP2;
   my $s3 = $self->sigP3;

   my ($s1List, $s2List, $s3List);
   for my $s ($self->db->signatureList) {
      $self->__findPossibleSpace($s1, $s, 'sigP1', \$s1List) if $s1;
      $self->__findPossibleSpace($s2, $s, 'sigP2', \$s2List) if $s2;
      $self->__findPossibleSpace($s3, $s, 'sigP3', \$s3List) if $s3;
   }

   [ $s1List, $s2List, $s3List ];
}

sub _getMaskList {
   my $self = shift;
   $self->maskUserList ? [ $self->maskUserList ] : [ $self->maskStandardList ];
}

sub _countElementsInHash {
   my $self = shift;
   my ($h) = @_;
   my $count;
   for my $k (keys %$h) {
      $count->{$k} = scalar keys %{$h->{$k}};
   }
   $count;
}

sub _splitSignatureListWithMask {
   my $self = shift;
   my ($sList, $mask) = @_;
   my @chunk = $mask =~ /(.{3})(.{3})(.{3})(.{3})(.{3})/;
   {
      B => $sList->{$chunk[0]},
      F => $sList->{$chunk[1]},
      W => $sList->{$chunk[2]},
      O => $sList->{$chunk[3]},
      M => $sList->{$chunk[4]},
   };
}

sub _searchSmallerElementFromHash {
   my $self = shift;
   my ($h) = @_;
   my ($last, $smaller);
   for my $k (keys %$h) {
      return undef if $h->{$k} == 0;
      do { $last = $h->{$k}; $smaller = $k; next } unless $last;
      if ($h->{$k} < $last) {
         $smaller = $k;
      }
      $last = $h->{$k};
   }
   $smaller;
}

sub _getIntersectionWithMask {
   my $self = shift;
   my ($h, $mask) = @_;

   my $split   = $self->_splitSignatureListWithMask($h, $mask);
   my $count   = $self->_countElementsInHash($split);
   my $smaller = $self->_searchSmallerElementFromHash($count);

   # We have at least one empty space, we can stop now (optimization)
   return undef unless $smaller;

   my $inter;
   for my $id (keys %{$split->{$smaller}}) {
      if (exists $split->{W}->{$id}
      &&  exists $split->{O}->{$id}
      &&  exists $split->{M}->{$id}
      &&  exists $split->{B}->{$id}
      &&  exists $split->{F}->{$id}) {
         $inter->{$id} = '';
      }
   }
   $inter;
}

sub _getIntersectionP1P2P3 {
   my $self = shift;
   my ($h) = @_;

   my $count   = $self->_countElementsInHash($h);
   my $smaller = $self->_searchSmallerElementFromHash($count);

   # We have at least one empty space, we can stop now (optimization)
   return undef unless $smaller;

   my $inter;
   for my $id (keys %{$h->{$smaller}}) {
      if (exists $h->{S2}->{$id}
      &&  exists $h->{S1}->{$id}
      &&  exists $h->{S3}->{$id}) {
         $inter->{$id} = '';
      }
   }
   $inter;
}

sub _getIntersectionP1P2 {
   my $self = shift;
   my ($h) = @_;

   my $count   = $self->_countElementsInHash($h);
   my $smaller = $self->_searchSmallerElementFromHash($count);

   # We have at least one empty space, we can stop now (optimization)
   return undef unless $smaller;

   my $inter;
   for my $id (keys %{$h->{$smaller}}) {
      if (exists $h->{S2}->{$id}
      &&  exists $h->{S1}->{$id}) {
         $inter->{$id} = '';
      }
   }
   $inter;
}

sub _getIntersectionP2 { shift; shift->{S2} }

sub _searchWithMaskList {
   my $self = shift;
   my ($s1List, $s2List, $s3List, $maskList) = @_;

   my $resultList;
   for my $m (@$maskList) {
      my $s1Inter = $self->_getIntersectionWithMask($s1List, $m);
      my $s2Inter = $self->_getIntersectionWithMask($s2List, $m);
      my $s3Inter = $self->_getIntersectionWithMask($s3List, $m);

      last if (exists $resultList->{NS_MATCH_TYPE_P1P2P3()}
           &&  exists $resultList->{NS_MATCH_TYPE_P1P2()}
           &&  exists $resultList->{NS_MATCH_TYPE_P2()});

      if ($m =~ /BH0FH0WH0OH0MH0/) {
         $m = NS_MATCH_MASK_HEURISTIC0;
      }
      elsif ($m =~ /BH1FH1WH1OH1MH1/) {
         $m = NS_MATCH_MASK_HEURISTIC1;
      }
      elsif ($m =~ /BH2FH2WH2OH2MH2/) {
         $m = NS_MATCH_MASK_HEURISTIC2;
      }

      if (! exists $resultList->{NS_MATCH_TYPE_P1P2P3()}
      &&  $s1Inter && $s2Inter && $s3Inter) {
         my $resultHash = $self->_getIntersectionP1P2P3(
            { S1 => $s1Inter, S2 => $s2Inter, S3 => $s3Inter }
         );
         if ($resultHash) {
            $resultList->{NS_MATCH_TYPE_P1P2P3()}{$m} = $resultHash;
            next;
         }
      }
      if (! exists $resultList->{NS_MATCH_TYPE_P1P2()}
      &&  $s1Inter && $s2Inter) {
         my $resultHash = $self->_getIntersectionP1P2(
            { S1 => $s1Inter, S2 => $s2Inter }
         );
         if ($resultHash) {
            $resultList->{NS_MATCH_TYPE_P1P2()}{$m} = $resultHash;
            next;
         }
      }
      if ($self->enableP2Match && ! exists $resultList->{NS_MATCH_TYPE_P2()}
      &&  $s2Inter) {
         my $resultHash = $self->_getIntersectionP2({ S2 => $s2Inter });
         if ($resultHash) {
            $resultList->{NS_MATCH_TYPE_P2()}{$m} = $resultHash;
            next;
         }
      }
   }

   if (scalar keys %$resultList > 0) {
      return $self->_addToResultList($resultList);
   }

   undef;
}

sub search {
   my $self = shift;

   my ($s1List, $s2List, $s3List) = @{$self->_findPossibleSpace};

   my $resultList;
   my $maskList = $self->_getMaskList;

   $resultList = $self->_searchWithMaskList(
      $s1List, $s2List, $s3List, $maskList,
   );

   if ($self->useAdvancedMasks && ! $resultList) {
      $resultList = $self->_searchWithMaskList(
         $s1List, $s2List, $s3List, [ $self->maskAdvancedList ],
      );
   }

   $resultList;
}

sub _getSigListFromType {
   my $self = shift;
   my ($h, $type) = @_;

   my $sigList;
   for my $mask (keys %{$h->{$type}}) {
      for my $id (keys %{$h->{$type}{$mask}}) {
         my $sig = $self->db->getSignature($id);
         $self->db->lookupOsInfos($sig);
         $sig->matchType($type);
         $sig->matchMask($mask);
         push @$sigList, $sig;
      }
   }
   $sigList;
}

sub _addToResultList {
   my $self = shift;
   my ($h) = @_;

   my $sigList;
   if (exists $h->{NS_MATCH_TYPE_P1P2P3()}) {
      $sigList = $self->_getSigListFromType($h, NS_MATCH_TYPE_P1P2P3);
   }
   elsif (exists $h->{NS_MATCH_TYPE_P1P2()}) {
      $sigList = $self->_getSigListFromType($h, NS_MATCH_TYPE_P1P2);
   }
   elsif (exists $h->{NS_MATCH_TYPE_P2()}) {
      $sigList = $self->_getSigListFromType($h, NS_MATCH_TYPE_P2);
   }

   my $resultList;
   for my $s (@$sigList) {
      my $result = Net::SinFP::Result->new(
         idSignature     => $s->idSignature,
         ipVersion       => $s->ipVersion,
         systemClass     => $s->systemClass,
         vendor          => $s->vendor,
         os              => $s->os,
         osVersion       => $s->osVersion,
         osVersionFamily => $s->osVersionFamily,
         matchType       => $s->matchType,
         matchMask       => $s->matchMask,
      );

      my $children = [];
      push @$children, $_ for $s->osVersionChildren;
      $result->osVersionChildrenList($children);

      push @$resultList, $result;
   }

   $self->resultList($resultList);
}

1;

=head1 NAME

Net::SinFP::Search - matching signatures search engine

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
