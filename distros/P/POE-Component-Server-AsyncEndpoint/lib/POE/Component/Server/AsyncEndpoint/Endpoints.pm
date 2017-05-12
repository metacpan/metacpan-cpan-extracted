package POE::Component::Server::AsyncEndpoint::Endpoints;

use warnings;
use strict;
our @EXPORT = qw( EP_STAT_NA EP_STAT_OK EP_STAT_WA EP_STAT_FA EP_STOPPED );
use base qw(Exporter);
use vars qw($VERSION);
$VERSION = '0.10';

use constant EP_STAT_NA => 0;   # not available
use constant EP_STAT_OK => 1;   # ok
use constant EP_STAT_WA => 2;   # waiting response
use constant EP_STAT_FA => 3;   # fail
use constant EP_STOPPED => 5;   # runtime stop


use File::Find;
use File::Util;

use Carp qw(croak);


my @endpoints = ();

sub init {
  find(\&wanted, qw(.));
  return @endpoints;
}

sub wanted {
  my $endpoints = shift @_;
  if (/^endpoint$/) {

    my $name = $File::Find::dir;
    my $pname = $File::Find::name;

    open(EPCONF, '<', './endpoint.conf')
      or croak "No configuration file for Endpoint: $pname $!";

    my $ikc_addr = undef;
    my $ikc_port = undef;
    my $start = undef;

    while (<EPCONF>) {
      if ($_ =~ /^\s*ikc_addr\s*=\s*([0-9a-zA-Z_.-]+)$/) {
        $ikc_addr = $1 if defined $1;
      }
      if ($_ =~ /^\s*ikc_port\s*=\s*([0-9]+)$/) {
        $ikc_port = $1 if defined $1;
      }
      if ($_ =~ /^\s*start\s*=\s*([01])$/) {
        $start = $1 if defined $1;
        $start = 0 unless $start;
      }

    }

    close(EPCONF);

    croak "No valid ikc_addr and/or ikc_port in conf file for Endpoint: $pname"
      unless ( (defined $ikc_addr) && (defined $ikc_port) );

    push @endpoints, {
      name => $name,
      pname => $pname,
      ikc_addr => $ikc_addr,
      ikc_port => $ikc_port,
      stat => EP_STAT_NA,
      retries => 0,
      wheel => undef,
      start => $start,
    }
  }

}

1;

__END__

=head1 NAME

POE::Component::Server::AsyncEndpoint::Endpoints

=head1 DESCRIPTION

This class just scans the directory structure and returns an array of
Endpoint descriptors.

=head1 EXPORTS

Just a few constants:

EP_STAT_NA : Endpoint status not available
EP_STAT_OK : Endpoint status OK
EP_STAT_WA : Endpoint status waiting for response
EP_STAT_FA : Endpoint status fail
EP_STOPPED : Endpoint is stopped; do not restart


=head1 SEE ALSO

L<POE::Component::Server::AsyncEndpoint>

=head1 AUTHOR

Alejandro Imass <ait@p2ee.org>
Alejandro Imass <aimass@corcaribe.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alejandro Imass / Corcaribe Tecnología C.A. for the P2EE Project

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

