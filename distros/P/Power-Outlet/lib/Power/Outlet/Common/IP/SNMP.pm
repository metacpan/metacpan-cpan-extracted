package Power::Outlet::Common::IP::SNMP;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP};
use Net::SNMP qw{};

our $VERSION = '0.46';

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

  my $value = $self->snmp_get($oid);

=cut

sub snmp_get {
  my $self = shift;
  my $oid  = shift;
  return $self->snmp_multiget([$oid])->{$oid};
}

=head2 snmp_multiget

  my $oid_values = $self->snmp_multiget(\@oids); #isa HASH
  my %oid_values = $self->snmp_multiget(\@oids); #isa ()

=cut

sub snmp_multiget {
  my $self    = shift;
  my $oids    = shift; #isa ARRAY
  die("Error: parameter must be array reference") unless ref($oids) eq "ARRAY";
  my $session = $self->snmp_session;
  my $result  = $session->get_request(-varbindlist=>$oids) or die(sprintf("Error: %s", $session->error)); #isa HASH
  return wantarray ? %$result : $result;
}

=head2 snmp_set

  $self->snmp_set($oid, $value);        #type INTEGER
  $self->snmp_set($oid, $value, $type); #type from Net::SNMP types

=cut

sub snmp_set {
  my $self = shift;
  my $oid  = shift;
  die("Error: parameter oid required") unless defined $oid;
  return $self->snmp_multiset([$oid], @_);
}

=head2 snmp_multiset

  $self->snmp_multiset(\@oids, $value);        #type INTEGER
  $self->snmp_multiset(\@oids, $value, $type); #type from Net::SNMP types

=cut

sub snmp_multiset {
  my $self    = shift;
  my $oids    = shift;
  die("Error: parameter oids must be an array reference") unless ref($oids) eq "ARRAY";
  my $value   = shift;
  die("Error: parameter values required") unless defined($value);
  my $type    = shift;
  $type       = Net::SNMP::INTEGER unless defined($type);
  my $session = $self->snmp_session;
  $session->set_request(-varbindlist=>[map {$_, $type, $value} @$oids]) or die(sprintf("Error: %s", $session->error));
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
