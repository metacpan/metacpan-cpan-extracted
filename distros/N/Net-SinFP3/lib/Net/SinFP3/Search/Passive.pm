#
# $Id: Passive.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Search::Passive;
use strict;
use warnings;

use base qw(Net::SinFP3::Search);
our @AS = qw(
   sp
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3 qw(:matchMask);

use Net::SinFP3::Ext::SP;
use Net::SinFP3::Result::Passive;
use Net::SinFP3::Result::PortError;
use Net::SinFP3::Result::Unknown;

use Net::Frame::Layer::TCP qw(:consts);

sub take {
   return [
      'Net::SinFP3::Mode::Passive',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   return $self;
}

sub _getPossibleSignaturePIds {
   my $self = shift;
   my ($sp) = @_;

   my $global = $self->global;
   my $log    = $global->log;
   my $db     = $global->db;

   my %patterns = (
      PatternTcpFlags   => 'F',
      PatternTcpWindow  => 'W',
      PatternTcpOptions => 'O',
      PatternTcpMss     => 'M',
      PatternTcpWScale  => 'S',
      PatternTcpOLength => 'L',
   );

   my %results = ();
   for my $tPattern (keys %patterns) {
      my $pId = "id$tPattern";

      # $sp->{F} for instance
      my $p = $sp->{$patterns{$tPattern}};

      my $_table = "_$tPattern";
      my %ids    = ();
      for my $h ('Heuristic0', 'Heuristic1', 'Heuristic2') {
         for my $t ($db->$_table) {
            (my $method = $tPattern.$h) =~ s/^(.)(.*)$/@{[lc($1)]}$2/;
            # We match either using regexp from DB,
            # or regexp built in passive mode
            if ($p =~ /^@{[$t->{$method}]}$/ || $t->{$method} =~ /$p/) {
               #print "DEBUG: [$p] against [".$t->{$method}."]\n";
               my $id   = $t->{$pId};
               my $list = $db->searchSignaturePIds(
                  $pId => $id,
               );
               for (@$list) {
                  $ids{$h}->{$_}++;
                  #print "DEBUG: possibleId [$id]\n";
               }
            }
         }
      }
      $results{$patterns{$tPattern}} = \%ids;
   }

   #use Data::Dumper;
   #print "DEBUG: _getPossibleSignaturePIds: ",
      #Dumper(\%results),"\n";

   return \%results;
}

sub _searchSmallestHeuristicHash {
   my $self = shift;
   my ($heuristic, @patterns) = @_;

   my @ids  = ();
   my $last = 10_000; # Invalid huge number
   for my $pList (@patterns) {
      my $count = keys %{$pList->{$heuristic}};
      next if $count == 0;  # We need to skip, otherwise there is a bug ;)
      if ($count < $last) {
         @ids  = keys %{$pList->{$heuristic}};
         $last = $count;
      }
   }
   return \@ids;
}

sub _searchSmallestHashWithMask {
   my $self = shift;

   my @ids  = ();
   my $last = 10_000; # Invalid huge number
   for my $pList (@_) {
      my $count = keys %$pList;
      next if $count == 0;  # We need to skip, otherwise there is a bug ;)
      if ($count < $last) {
         @ids  = keys %$pList;
         $last = $count;
      }
   }
   return \@ids;
}

sub _getIntersection {
   my $self = shift;
   my ($fList, $wList, $oList, $mList, $sList, $lList) = @_;

   my $inter;
   for my $h ('Heuristic0', 'Heuristic1', 'Heuristic2') {
      my $smallest = $self->_searchSmallestHeuristicHash(
         $h, $fList, $wList, $oList, $mList, $sList, $lList,
      );
      #print "[*] DEBUG: _getIntersection: _searchSmallestHeuristicHash[$h]: ",Dumper($smallest),"\n";
      for my $id (@$smallest) {
         if (($fList->{Heuristic0}->{$id} || $fList->{Heuristic1}->{$id} || $fList->{Heuristic2}->{$id})
         &&  ($wList->{Heuristic0}->{$id} || $wList->{Heuristic1}->{$id} || $wList->{Heuristic2}->{$id})
         &&  ($oList->{Heuristic0}->{$id} || $oList->{Heuristic1}->{$id} || $oList->{Heuristic2}->{$id})
         &&  ($mList->{Heuristic0}->{$id} || $mList->{Heuristic1}->{$id} || $mList->{Heuristic2}->{$id})
         &&  ($sList->{Heuristic0}->{$id} || $sList->{Heuristic1}->{$id} || $sList->{Heuristic2}->{$id})
         &&  ($lList->{Heuristic0}->{$id} || $lList->{Heuristic1}->{$id} || $lList->{Heuristic2}->{$id})) {
            my $f = $fList->{Heuristic0}->{$id} && 'FH0'
                 || $fList->{Heuristic1}->{$id} && 'FH1'
                 || $fList->{Heuristic2}->{$id} && 'FH2';
            my $w = $wList->{Heuristic0}->{$id} && 'WH0'
                 || $wList->{Heuristic1}->{$id} && 'WH1'
                 || $wList->{Heuristic2}->{$id} && 'WH2';
            my $o = $oList->{Heuristic0}->{$id} && 'OH0'
                 || $oList->{Heuristic1}->{$id} && 'OH1'
                 || $oList->{Heuristic2}->{$id} && 'OH2';
            my $m = $mList->{Heuristic0}->{$id} && 'MH0'
                 || $mList->{Heuristic1}->{$id} && 'MH1'
                 || $mList->{Heuristic2}->{$id} && 'MH2';
            my $s = $sList->{Heuristic0}->{$id} && 'SH0'
                 || $sList->{Heuristic1}->{$id} && 'SH1'
                 || $sList->{Heuristic2}->{$id} && 'SH2';
            my $l = $lList->{Heuristic0}->{$id} && 'LH0'
                 || $lList->{Heuristic1}->{$id} && 'LH1'
                 || $lList->{Heuristic2}->{$id} && 'LH2';
            $inter->{"$f$w$o$m$s$l"}->{$id}++;
         }
      }
      # Stop if we found matches with this smallest heuristic level
      #last if keys %$inter > 0;
   }
   return $inter;
}

sub _getIntersectionWithMask {
   my $self = shift;
   my ($fList, $wList, $oList, $mList, $sList, $lList, $mask) = @_;

   my $f = $mask =~ /FH0/ && 'Heuristic0'
        || $mask =~ /FH1/ && 'Heuristic1'
        || $mask =~ /FH2/ && 'Heuristic2';
   my $w = $mask =~ /WH0/ && 'Heuristic0'
        || $mask =~ /WH1/ && 'Heuristic1'
        || $mask =~ /WH2/ && 'Heuristic2';
   my $o = $mask =~ /OH0/ && 'Heuristic0'
        || $mask =~ /OH1/ && 'Heuristic1'
        || $mask =~ /OH2/ && 'Heuristic2';
   my $m = $mask =~ /MH0/ && 'Heuristic0'
        || $mask =~ /MH1/ && 'Heuristic1'
        || $mask =~ /MH2/ && 'Heuristic2';
   my $s = $mask =~ /SH0/ && 'Heuristic0'
        || $mask =~ /SH1/ && 'Heuristic1'
        || $mask =~ /SH2/ && 'Heuristic2';
   my $l = $mask =~ /LH0/ && 'Heuristic0'
        || $mask =~ /LH1/ && 'Heuristic1'
        || $mask =~ /LH2/ && 'Heuristic2';

   # We force a search using a very specific heuristic mask
   my $smallest = $self->_searchSmallestHashWithMask(
      $fList->{$f}, $wList->{$w}, $oList->{$o}, $mList->{$m},
      $sList->{$s}, $lList->{$l},
   );

   my $inter;
   for my $id (@$smallest) {
      if ($fList->{$f}->{$id}
      &&  $wList->{$w}->{$id}
      &&  $oList->{$o}->{$id}
      &&  $mList->{$m}->{$id}
      &&  $sList->{$s}->{$id}
      &&  $lList->{$l}->{$id}) {
         $inter->{$mask}->{$id}++;
      }
   }

   return $inter;
}

sub _searchSmallestInterWithMask {
   my $self = shift;

   my @ids  = ();
   my $last = 10_000; # Invalid huge number
   for my $inter (@_) {
      my $count = keys %$inter;
      next if $count == 0;   # We need to skip, otherwise there is a bug ;)
      if ($count < $last) {
         @ids  = keys %$inter;
         $last = $count;
      }
   }
   return \@ids;
}

sub _tohash {
   my $self = shift;
   my ($s) = @_;
   return {
      F => $self->$s->F,
      W => $self->$s->W,
      O => $self->$s->O,
      M => $self->$s->M,
      S => $self->$s->S,
      L => $self->$s->L,
   };
}

sub _countInter {
   my $self = shift;
   my ($ids) = @_;
   $ids->{nInter} = keys %{$ids->{Inter}};
   return $ids;
}

sub search {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;

   # Convert it to optimize a bit
   my $sp = $self->_tohash('sp');

   my $ids   = {};
   my $res   = $self->_getPossibleSignaturePIds($sp);
   my $inter = $self->_getIntersection(
      $res->{F}, $res->{W}, $res->{O}, $res->{M}, $res->{S}, $res->{L},
   );
   $ids->{Ids}   = $res;
   $ids->{Inter} = $inter;

   # Make masks unique
   my %maskList = map { $_ => 1 } (keys %{$ids->{Inter}});

   # Update number of resulting intersection
   $self->_countInter($ids);

   # For all masks, expand possible Signature IDs to make
   # all of them comparable
   for my $mask (keys %maskList) {
      #print "[*] ".Dumper($ids->{$p}{Ids})."\n";
      if (!exists $ids->{Inter}->{$mask}) {
         #print "[*] Running with [$mask] against [$p]\n";
         my $interNew = $self->_getIntersectionWithMask(
            $ids->{Ids}->{F}, $ids->{Ids}->{W}, $ids->{Ids}->{O},
            $ids->{Ids}->{M}, $ids->{Ids}->{S}, $ids->{Ids}->{L},
            $mask,
         );
         if ($interNew) {
            use Data::Dumper;
            $log->debug("interNew: ".Dumper($interNew));
            $ids->{Inter}->{$mask} = $interNew->{$mask};
         }
      }
   }

   # Update number of resulting intersections
   # after we have expanded mask list
   $self->_countInter($ids);

   my @resultList = ();

   #print "DEBUG: NS_MATCH_TYPE_P2\n";
   my $results = $self->_buildResultList($ids->{Inter});
   push @resultList, @$results;

   my $clean4 = $self->_cleanResults(\@resultList, 'IPv4');
   my $clean6 = $self->_cleanResults(\@resultList, 'IPv6');

   # We keep IPv4 signatures in IPv6 mode only if no IPv6 matchs
   # Else in IPv4 mode, we only keep IPv4 matchs
   my @clean = ();
   if ($self->global->ipv6 && @$clean6 > 0) {
      push @clean, @$clean6;
   }
   elsif (@$clean4 > 0) {
      push @clean, @$clean4;
   }

   return \@clean;
}

sub _cleanResults {
   my $self = shift;
   my ($results, $ip) = @_;

   my $global = $self->global;

   # Sort to easily filter out
   my $sorted = {};
   for my $r (@$results) {
      if ($r->ipVersion ne $ip) {
         next;
      }
      if ($global->threshold != 0 && $r->matchScore < $global->threshold) {
         next;
      }
      push @{$sorted->{$r->matchScore}}, $r;
   }

   my $p2 = $sorted;

   my @sorted2 = ();
   if (keys %$p2 > 0) {
      # Sort results by IP version and score, keep only highest score for an ID
      my %idList    = ();
      my $bestScore = 0;
      for my $p (sort { $b <=> $a } keys %$sorted) {
         for my $r (@{$sorted->{$p}}) {
            if (! exists($idList{$r->idSignatureP})) {
               if ($global->bestScore) {
                  if ($r->matchScore >= $bestScore) {
                     push @sorted2, $r;
                     $idList{$r->idSignatureP}++;
                     if (! $bestScore) {
                        $bestScore = $r->matchScore;
                     }
                  }
               }
               else {
                  push @sorted2, $r;
                  $idList{$r->idSignatureP}++;
               }
            }
         }
      }
   }
   else {
      # Or no matchs at all
      return [];
   }

   return \@sorted2;
}

sub _buildResultList {
   my $self = shift;
   my ($result) = @_;

   my $global = $self->global;
   my $log    = $global->log;
   my $db     = $global->db;

   my @resultList = ();
   for my $mask (keys %$result) {
      for my $id (keys %{$result->{$mask}}) {
         my %args   = ();
         my $sig    = $db->retrieveSignatureP($id);
         my $result = Net::SinFP3::Result::Passive->new(
            global          => $self->global,
            sp              => $self->sp,
            trusted         => $sig->{trusted},
            idSignatureP    => $sig->{idSignatureP},
            ipVersion       => $sig->{ipVersion},
            systemClass     => $sig->{systemClass},
            vendor          => $sig->{vendor},
            os              => $sig->{os},
            osVersion       => $sig->{osVersion},
            osVersionFamily => $sig->{osVersionFamily},
            matchType       => 'P2',
            matchMask       => $mask,
            osVersionChildrenList => $db->getOsVersionChildrenPList(
               $id,
            ),
         );
         $result->updateMatchScore;
         push @resultList, $result;
      }
   }

   return \@resultList;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;
   my $mode   = $global->mode;

   if (! defined($mode->sp)) {
      $log->error("Nothing to search");
      return;
   }

   $self->sp($mode->sp);

   my $result = $self->search;
   if (@$result == 0) {
      my $r = Net::SinFP3::Result::Unknown->new(
         global => $self->global,
         sp     => $self->sp,
      );
      $result = [ $r ];
   }

   # Fill frame attribute if available
   if ($mode->frame) {
      my $f   = $mode->frame;
      my $ip  = $f->ref->{IPv4} || $f->ref->{IPv6};
      my $tcp = $f->ref->{TCP};
      for my $r (@$result) {
         $r->frame($mode->frame);
         $r->ip($ip->dst);
         $r->port($tcp->dst);
         if ($global->dnsReverse) {
            $r->reverse($global->getAddrReverse(addr => $r->ip) || 'unknown');
         }
      }
   }

   return $result;
}

1;

__END__

=head1 NAME

Net::SinFP3::Search::Passive - matching passive signatures search engine

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
