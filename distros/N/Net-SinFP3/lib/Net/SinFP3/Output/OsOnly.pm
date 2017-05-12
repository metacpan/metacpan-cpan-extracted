#
# $Id: OsOnly.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Output::OsOnly;
use strict;
use warnings;

use base qw(Net::SinFP3::Output);
__PACKAGE__->cgBuildIndices;

sub take {
   return [
      'Net::SinFP3::Result::Active',
      'Net::SinFP3::Result::Passive',
      'Net::SinFP3::Result::PortError',
      'Net::SinFP3::Result::Unknown',
   ];
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my $log     = $global->log;
   my @results = $global->result;

   my $buf   = '';
   my $first = 1;
   my %os    = ();
   for my $r (@results) {
      my $ref = ref($r);
      if ($ref =~ /^Net::SinFP3::Result::Unknown$/) {
         $buf .= $r->printSignature."\n";
         $buf .= $r->print."\n";
         print $buf;
         return 1;
      }
      elsif ($ref =~ /^Net::SinFP3::Result::PortError$/) {
         $buf .= $r->printSignature."\n";
         $buf .= $r->print."\n";
         print $buf;
         return 1;
      }
      elsif ($ref =~ /^Net::SinFP3::Result::Active$/
         ||  $ref =~ /^Net::SinFP3::Result::Passive$/) {
         if ($first) {
            $buf .= $r->printSignature."\n";
            $first = 0;
         }
         (exists($os{$r->os}) && $r->matchScore >= $os{$r->os}->matchScore)
            ? ($os{$r->os} = $r)
            : ($os{$r->os} = $r);
      }
      else {
         $log->warning("Don't know what to do with this result object ".
                       "with type: [$ref]");
      }
   }

   # Sort by score
   my %byScore = ();
   for my $k (keys %os) {
      my $r = $os{$k};
      push @{$byScore{$r->matchScore}}, $r;
   }

   for my $k (sort { $b <=> $a } keys %byScore) {
      my $list = $byScore{$k};
      for my $r (@$list) {
         my $str = $r->ipVersion.': [score:'.$r->matchScore.']: '.
                   $r->matchMask.'/'.$r->matchType.': '.$r->os."\n";
         $buf .= $str;
      }
   }

   print $buf;

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::OsOnly - display only OS results on console output

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
