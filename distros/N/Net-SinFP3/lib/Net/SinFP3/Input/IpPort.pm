#
# $Id: IpPort.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input::IpPort;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
our @AS = qw(
   mac
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Next::IpPort;

sub give {
   return [
      'Net::SinFP3::Next::IpPort',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      mac => '00:00:00:00:00:00',
      @_,
   );

   my $global = $self->global;
   my $log    = $global->log;

   if (! defined($global->target)) {
      $log->fatal("You must provide `target' attribute in Global object");
   }

   if (! defined($global->port)) {
      $log->fatal("You must provide `port' attribute in Global object");
   }

   if (! $global->targetIp) {
      $log->fatal("Invalid target IP provided: [".$global->targetIp."]");
   }

   my $port = $global->port;
   if ($port !~ /^[-,\d]+$/) {
      $log->fatal("Invalid port provided: [$port]");
   }

   return $self;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $global = $self->global;
   my $log = $global->log;

   my $portList = $global->portList;
   my $ip = $global->targetIp;
   my $hostname = $global->targetHostname;

   my $reverse = $global->targetReverse;
   my $mac = $self->mac;

   my @nextList = ();
   for my $port (@$portList) {
      my $next = Net::SinFP3::Next::IpPort->new(
         global => $self->global,
         ip => $ip,
         port => $port,
         hostname => $hostname,
         reverse => $reverse,
         mac => $mac,
      );
      push @nextList, $next;
   }

   $self->nextList(\@nextList);

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my @nextList = $self->nextList;
   my $next = shift @nextList;
   $self->nextList(\@nextList);

   return $next;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::IpPort - object describing a SinFP target

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
