#
# $Id: CSV.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Output::CSV;
use strict;
use warnings;

use base qw(Net::SinFP3::Output);
our @AS = qw(
   osOnly
   file
   _fd
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Data::Dumper;

sub take {
   return [
      'Net::SinFP3::Result::Active',
      'Net::SinFP3::Result::Unknown',
      'Net::SinFP3::Result::PortError',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      osOnly => 1,
      file   => 'sinfp3-output.csv',
      @_,
   );

   return $self;
}

sub _writeCsvLine {
   my $self = shift;
   my ($resultList) = @_;

   my $global = $self->global;
   my $log    = $global->log;
   my $next   = $global->next;

   my $buf = '';
   my $r   = $resultList->[0];
   if ($self->osOnly) {
      my $osList = $r->getPossibleOsList($resultList);

      my $ip      = $r->ip;
      my $port    = $r->port;
      my $sOsList = join(',', @$osList);
      $buf        = "Results for target: [$ip]:$port: $sOsList\n";

      my $fd = $self->_fd;

      print $fd ref($next).";$ip;$port;".scalar(@$osList).";$sOsList;\n";
   }
   else {
      $log->fatal("Not implemented yet");
   }

   return $buf;
}

sub init {
   my $self = shift;

   my $log = $self->global->log;

   open(my $out, '>>', $self->file)
      or $log->fatal("Cannot open file: ".$self->file);

   $self->_fd($out);

   return 1;
}

sub post {
   my $self = shift;

   my $fd = $self->_fd;
   if ($fd) {
      close($fd);
   }

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my $log     = $global->log;
   my @results = $global->result;

   for my $r (@results) {
      my $ref = ref($r);
      if ($ref =~ /^Net::SinFP3::Result::Unknown$/) {
         return 1;
      }
      elsif ($ref =~ /^Net::SinFP3::Result::PortError$/) {
         return 1;
      }
      elsif ($ref =~ /^Net::SinFP3::Result::Active$/) {
         my $buf = $self->_writeCsvLine(\@results);
         print $buf;
         last;
      }
      else {
         $log->warning("Don't know what to do with this result object ".
                       "with type: [$ref]");
         next;
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::CSV - plugin to save results in CSV format

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
