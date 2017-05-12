package Net::SNMP::Mixin::System;

use 5.006;
use warnings;
use strict;

# store this package name in a handy variable,
# used for unambiguous prefix of mixin attributes
# storage in object hash
#
my $prefix = __PACKAGE__;

# this module import config
#
use Carp ();

use Net::SNMP::Mixin::Util qw/push_error get_init_slot/;

# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = ( qw/get_system_group/);
}

use Sub::Exporter -setup => {
  exports   => [@mixin_methods],
  groups    => { default => [@mixin_methods], },
};

# SNMP oid constants used in this module
#
use constant {
  SYS_DESCR          => '1.3.6.1.2.1.1.1.0',
  SYS_OBJECT_ID      => '1.3.6.1.2.1.1.2.0',
  SYS_UP_TIME        => '1.3.6.1.2.1.1.3.0',
  SYS_CONTACT        => '1.3.6.1.2.1.1.4.0',
  SYS_NAME           => '1.3.6.1.2.1.1.5.0',
  SYS_LOCATION       => '1.3.6.1.2.1.1.6.0',
  SYS_SERVICES       => '1.3.6.1.2.1.1.7.0',
};

=head1 NAME

Net::SNMP::Mixin::System - mixin class for the mib-2 system-group values

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

A Net::SNMP mixin class for mib-II system-group info. It's just in the distribution to act as a blueprint for mixin authors.

  use Net::SNMP;
  use Net::SNMP::Mixin;

  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );

  $session->mixer('Net::SNMP::Mixin::System');
  $session->init_mixins;
  snmp_dispatcher();
  $session->init_ok();
  die $session->errors if $session->errors;

  my $system_group = $session->get_system_group;

  printf "Name: %s, Contact: %s, Location: %s\n",
    $system_group->{sysName},
    $system_group->{sysContact},
    $system_group->{sysLocation};

=head1 MIXIN METHODS

=head2 B<< OBJ->get_system_group() >>

Returns the mib-II system-group as a hash reference:

  {
    sysDescr        => DisplayString,
    sysObjectID     => OBJECT_IDENTIFIER,
    sysUpTime       => TimeTicks,
    sysContact      => DisplayString,
    sysName         => DisplayString,
    sysLocation     => DisplayString,
    sysServices     => INTEGER,
  }

=cut

sub get_system_group {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # just a shallow copy for shallow values
  return { %{ $session->{$prefix}{sysGroup} } };
}

=head1 INITIALIZATION

=cut

=head2 B<< OBJ->_init($reload) >>

Fetch the SNMP mib-II system-group values from the host. Don't call this method direct! Returns nothing in case of failure so init_mixins can stop initialization.

=cut

#
# due to the asynchron nature, we don't know what init job is really the last, we decrement
# the value after each callback
#
use constant THIS_INIT_JOBS => 1;

sub _init {
  my ( $session, $reload ) = @_;
  my $agent = $session->hostname;

  die "$agent: $prefix already initialized and reload not forced.\n"
    if exists get_init_slot($session)->{$prefix}
      && get_init_slot($session)->{$prefix} == 0
      && not $reload;

  # set number of async init jobs for proper initialization
  get_init_slot($session)->{$prefix} = THIS_INIT_JOBS;

  # initialize the object system-group infos
  my $success = _fetch_system_group($session);
  $success ? return 1 : return;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_system_group($session) >>

Fetch values from the system-group once during object initialization. Push error message onto the error buffer in case of failure and returns nothing.

=cut

sub _fetch_system_group {
  my $session = shift;
  my $result;

  # fetch the mib-II system-group
  $result = $session->get_request(
    -varbindlist => [

      SYS_DESCR,
      SYS_OBJECT_ID,
      SYS_UP_TIME,
      SYS_CONTACT,
      SYS_NAME,
      SYS_LOCATION,
      SYS_SERVICES,
    ],

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_system_group_cb ) : (),
  );

  unless (defined $result) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  # in nonblocking mode the callback will be called asynchronously
  return 1 if $session->nonblocking;

  # ok we are in synchronous mode, call the result mangling function
  # by hand
  _system_group_cb($session);

}

=head2 B<< _system_group_cb($session) >>

The callback for _fetch_system_group. Push error message onto the error buffer in case of failure and returns nothing.

=cut

sub _system_group_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless (defined $vbl) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  $session->{$prefix}{sysGroup}{sysDescr}    = $vbl->{ SYS_DESCR() };
  $session->{$prefix}{sysGroup}{sysObjectID} = $vbl->{ SYS_OBJECT_ID() };
  $session->{$prefix}{sysGroup}{sysUpTime}   = $vbl->{ SYS_UP_TIME() };
  $session->{$prefix}{sysGroup}{sysContact}  = $vbl->{ SYS_CONTACT() };
  $session->{$prefix}{sysGroup}{sysName}     = $vbl->{ SYS_NAME() };
  $session->{$prefix}{sysGroup}{sysLocation} = $vbl->{ SYS_LOCATION() };
  $session->{$prefix}{sysGroup}{sysServices} = $vbl->{ SYS_SERVICES() };

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

unless ( caller() ) {
  print "$prefix compiles and initializes successful.\n";
}

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a bug or are experiencing difficulties that are not explained within the POD documentation, please submit a bug to the RT system (see link below). However, it would help greatly if you are able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not be forthcoming, please feel free to (politely) remind me by sending an email to gaissmai@cpan.org .

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin

=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>
=head1 COPYRIGHT & LICENSE

Copyright 2008-2015 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

# vim: sw=2
