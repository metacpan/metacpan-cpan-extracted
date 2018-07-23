#
# $Id: Console.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Output::Console;
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

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my $log     = $global->log;
   my @results = $global->result;

   my $buf   = '';
   my $first = 1;
   for my $r (@results) {
      my $ref = ref($r);
      if ($ref =~ /^Net::SinFP3::Result::Unknown$/) {
         $buf .= $self->_print($r, \$first);
         print $buf;
         return 1;
      }
      elsif ($ref =~ /^Net::SinFP3::Result::PortError$/) {
         $buf .= $self->_print($r, \$first);
         print $buf;
         return 1;
      }
      elsif ($ref =~ /^Net::SinFP3::Result::Active$/) {
         $buf .= $self->_print($r, \$first);
      }
      elsif ($ref =~ /^Net::SinFP3::Result::Passive$/) {
         $buf .= $self->_print($r, \$first);
      }
      else {
         $log->warning("Don't know what to do with this result object ".
                       "with type: [$ref]");
      }
   }

   print $buf;

   return 1;
}

sub _print {
   my $self = shift;
   my ($r, $first) = @_;
   my $buf = '';
   if ($$first) {
      $buf .= $r->printSignature."\n";
      $$first = 0;
   }
   $buf .= $r->print."\n";
   return $buf;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::Console - display results on console output

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
