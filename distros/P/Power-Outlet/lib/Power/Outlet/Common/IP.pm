package Power::Outlet::Common::IP;
use strict;
use warnings;
use base qw{Power::Outlet::Common};

our $VERSION = '0.48';

=head1 NAME

Power::Outlet::Common::IP - Power::Outlet base class for Internet Protocol power outlet

=head1 SYNOPSIS

  use base qw{Power::Outlet::Common::IP};

=head1 DESCRIPTION
 
Power::Outlet::Common::IP is a base package for controlling and querying Internet based power outlet.

=head1 USAGE

  use base qw{Power::Outlet::Common::IP};

=head1 CONSTRUCTOR

=head1 PROPERTIES

=head2 host

Sets and returns the hostname or IP address.

Manufacturer Default: 192.168.1.254

=cut

sub host {
  my $self=shift;
  $self->{"host"}=shift if @_;
  $self->{"host"}=$self->_host_default unless defined $self->{"host"};
  return $self->{"host"};
}

sub _host_default {"192.168.1.254"}; #MFG Default for iBoot

=head2 port

Sets and returns the TCP port

Manufacturer Default: 80

=cut

sub port {
  my $self=shift;
  $self->{"port"}=shift if @_;
  $self->{"port"}=$self->_port_default unless defined $self->{"port"};
  return $self->{"port"};
}

sub _port_default {"80"}; #MFG Default for iBoot

sub _name_default {
  my $self=shift;
  return $self->host;
}

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
