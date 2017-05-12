package Power::Outlet::Common::IP::SNMP;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP};
use Net::SNMP qw{INTEGER};

our $VERSION='0.16';


=head1 NAME

Power::Outlet::Common::IP::SNMP - Power::Outlet base class for SNMP power outlet

=head1 SYNOPSIS

  use base qw{Power::Outlet::Common::IP::SNMP};

=head1 DESCRIPTION
 
Power::Outlet::Common::IP::SNMP is a package for controlling and querying an SNMP-based network attached power outlet.

=head1 USAGE

  use base qw{Power::Outlet::Common::IP::SNMP};

=head1 PROPERTIES

=head2 community

Sets and returns the SNMP community.

  my $community=$outlet->community("private"); #read/write
  my $community=$outlet->community("public");  #read only features

=cut

sub community {
  my $self=shift;
  $self->{"community"}=shift if @_;
  $self->{"community"}=$self->_community_default unless defined $self->{"community"}; #MFG Default
  return $self->{"community"};
}

=head2 snmp_version

Returns 1

=cut

sub snmp_version {1};                #iBootBar
sub _host_default {"192.168.0.254"}; #iBootBar
sub _port_default {"161"};           #SNMP
sub _community_default {"private"};  #iBootBar

=head1 METHODS

=head2 snmp_session

Returns a cached L<Net::SNMP> session object

=cut

sub snmp_session {
  my $self=shift;
  $self->{"snmp_session"}=shift if @_;
  unless (defined $self->{"snmp_session"}) {
    my ($session, $error) = Net::SNMP->session(
     -version   => $self->snmp_version,
     -hostname  => $self->host,
     -port      => $self->port,
     -community => $self->community,
    );
    die("Error $error") if $error;
    $self->{"snmp_session"}=$session;
  }
  return $self->{"snmp_session"};
}

=head2 snmp_get

  my $value=$self->snmp_get($oid);

=cut

sub snmp_get {
  my $self=shift;
  my $oid=shift;
  my $session=$self->snmp_session;
  my $result=$session->get_request(-varbindlist=>[$oid]) or die(sprintf("Error: %s", $session->error));
  my $return=$result->{$oid};
  return $return;
}

=head2 snmp_set

  $self->snmp_set($oid, $value); #only supports integer values

=cut

sub snmp_set {
  my $self=shift;
  my $oid=shift;
  my $value=shift;
  my $session=$self->snmp_session;
  $session->set_request(-varbindlist=>[$oid, INTEGER, $value]) or die(sprintf("Error: %s", $session->error));
  return "SUCCESS";
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
