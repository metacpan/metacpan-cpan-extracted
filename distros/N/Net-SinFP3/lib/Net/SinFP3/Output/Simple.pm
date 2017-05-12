#
# $Id: Simple.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Output::Simple;
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

sub take {
   return [
      'Net::SinFP3::Result::Active',
      'Net::SinFP3::Result::Passive',
      'Net::SinFP3::Result::Unknown',
      'Net::SinFP3::Result::PortError',
   ];
}

sub _runUnknown {
   my $self = shift;
   my ($results) = @_;

   my $global = $self->global;
   my $log    = $global->log;
   my $mode   = $global->mode;

   my $ref = ref($mode);
   my $r   = $results->[0];

   my $line = '';
   if ($ref =~ /^Net::SinFP3::Mode::Passive$/) {
      my $frame = $r->frame;
      my $ip    = $frame->ref->{IPv4} || $frame->ref->{IPv6};
      my $tcp   = $frame->ref->{TCP};
      $line     = sprintf("[%-15s]:%-5d > [%-15s]:%-5d  reverse: %s  ".
                          "[Unknown OS]",
         $ip->src,
         $tcp->src,
         $ip->dst,
         $tcp->dst,
         $r->reverse,
      );
   }
   elsif ($ref =~ /^Net::SinFP3::Mode::Active$/) {
      $line = sprintf("[%-15s]:%-5d  reverse: %s  [Unknown OS]",
         $r->ip,
         $r->port,
         $r->reverse,
      );
   }

   print $line."\n";

   return 1;
}

sub _runPortError {
   my $self = shift;
   my ($results) = @_;

   my $r   = $results->[0];
   my $buf = sprintf("[%-15s]:%-5d  reverse: %s  [Port error: %s]",
      $r->ip,
      $r->port,
      $r->reverse,
      $r->p2Reason,
   );

   print $buf."\n";

   return 1;
}

sub _runActive {
   my $self = shift;
   my ($results) = @_;

   my %os = ();
   for my $r (@$results) {
      my $os = $r->os.' '.$r->osVersionFamily;
      if (! $os{$os}->{matchScore} || $r->matchScore > $os{$os}->{matchScore}) {
         $os{$os}->{matchScore} = $r->matchScore;
      }
   }

   my @lines = ();
   for my $r (@$results) {
      my $os = $r->os.' '.$r->osVersionFamily;
      if ($os{$os}->{matchScore} == $r->matchScore) {
         my $line = sprintf("[%-15s]:%-5d  reverse: %s  [%3d%%: %s]",
            $r->ip,
            $r->port,
            $r->reverse,
            $r->matchScore,
            $os,
         );

         my $found = 0;
         for my $this (@lines) {
            if ($this eq $line) {
               $found++;
               last;
            }
         }
         if ($found) {
            next;
         }

         push @lines, $line;
      }
   }

   print join("\n", @lines)."\n";

   return 1;
}

sub _runPassive {
   my $self = shift;
   my ($results) = @_;

   my $global = $self->global;
   my $log = $global->log;

   my %os = ();
   for my $r (@$results) {
      my $os = $r->os.' '.$r->osVersionFamily;
      if (! $os{$os}->{matchScore} || $r->matchScore > $os{$os}->{matchScore}) {
         $os{$os}->{matchScore} = $r->matchScore;
      }
   }

   my @lines = ();
   for my $r (@$results) {
      my $os = $r->os.' '.$r->osVersionFamily;
      if ($os{$os}->{matchScore} == $r->matchScore) {
         my $frame = $r->frame;
         my $ip = $frame->ref->{IPv4} || $frame->ref->{IPv6};
         my $tcp = $frame->ref->{TCP};
         my $line = sprintf("[%-15s]:%-5d > [%-15s]:%-5d  reverse: %s  ".
                            "[%3d%%: %s %s]",
            $ip->src,
            $tcp->src,
            $ip->dst,
            $tcp->dst,
            $r->reverse,
            $r->matchScore,
            $r->os,
            $r->osVersionFamily,
         );

         my $found = 0;
         for my $this (@lines) {
            if ($this eq $line) {
               $found++;
               last;
            }
         }
         if ($found) {
            next;
         }

         push @lines, $line;
      }
   }

   print join("\n", @lines)."\n";

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my $log     = $global->log;
   my @results = $global->result;

   my $ref = ref($results[0]);
   if ($ref =~ /^Net::SinFP3::Result::Unknown$/) {
      return $self->_runUnknown(\@results);
   }
   elsif ($ref =~ /^Net::SinFP3::Result::PortError$/) {
      return $self->_runPortError(\@results);
   }
   elsif ($ref =~ /^Net::SinFP3::Result::Active$/) {
      $self->_runActive(\@results);
   }
   elsif ($ref =~ /^Net::SinFP3::Result::Passive$/) {
      $self->_runPassive(\@results);
   }
   else {
      $log->warning("Don't know what to do with this result object ".
                    "with type: [$ref]");
   }

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::Simple - output results in a simple way to console

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
