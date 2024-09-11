package Net::SNMP::Mixin::PoE;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Net::SNMP::Mixin::PoE - mixin class for power over ethernet related infos from
the POWER-ETHERNET-MIB (RFC-3621)

=cut

#
# store this package name in a handy variable,
# used for unambiguous prefix of mixin attributes
# storage in object hash
#
my $prefix = __PACKAGE__;

#
# this module import config
#
use Carp ();
use Net::SNMP::Mixin::Util qw/idx2val push_error get_init_slot/;

#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (qw/ get_poe_port_table get_poe_main_table /);
}

use Sub::Exporter -setup => {
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods], },
};

#
# SNMP oid constants used in this module from the POWER-ETHERNET-MIB
#
use constant POE_PORT_TABLE       => '.1.3.6.1.2.1.105.1.1';
use constant POE_PORT_TABLE_ENTRY => POE_PORT_TABLE . '.1';

use constant {
  POE_PORT_GROUP_IDX         => POE_PORT_TABLE_ENTRY . '.1',
  POE_PORT_IDX               => POE_PORT_TABLE_ENTRY . '.2',
  POE_PORT_ADMIN_ENABLE      => POE_PORT_TABLE_ENTRY . '.3',
  POE_PORT_POWER_PAIRS_CTRL  => POE_PORT_TABLE_ENTRY . '.4',
  POE_PORT_POWER_PAIRS       => POE_PORT_TABLE_ENTRY . '.5',
  POE_PORT_DETECTION_STATUS  => POE_PORT_TABLE_ENTRY . '.6',
  POE_PORT_POWER_PRIORITY    => POE_PORT_TABLE_ENTRY . '.7',
  POE_PORT_MPS_ABSENT        => POE_PORT_TABLE_ENTRY . '.8',
  POE_PORT_TYPE              => POE_PORT_TABLE_ENTRY . '.9',
  POE_PORT_POWER_CLASS       => POE_PORT_TABLE_ENTRY . '.10',
  POE_PORT_INVALID_SIGNATURE => POE_PORT_TABLE_ENTRY . '.11',
  POE_PORT_POWER_DENIED      => POE_PORT_TABLE_ENTRY . '.12',
  POE_PORT_OVERLOAD          => POE_PORT_TABLE_ENTRY . '.13',
  POE_PORT_SHORT             => POE_PORT_TABLE_ENTRY . '.14',
};

use constant POE_MAIN_TABLE       => '.1.3.6.1.2.1.105.1.3.1';
use constant POE_MAIN_TABLE_ENTRY => POE_MAIN_TABLE . '.1';

use constant {
  POE_MAIN_GROUP_IDX   => POE_MAIN_TABLE_ENTRY . '.1',
  POE_MAIN_POWER       => POE_MAIN_TABLE_ENTRY . '.2',
  POE_MAIN_OPER_STATUS => POE_MAIN_TABLE_ENTRY . '.3',
  POE_MAIN_CONSUMPTION => POE_MAIN_TABLE_ENTRY . '.4',
  POE_MAIN_THRESHOLD   => POE_MAIN_TABLE_ENTRY . '.5',
};

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin;

  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );

  $session->mixer('Net::SNMP::Mixin::PoE');
  $session->init_mixins;
  snmp_dispatcher();
  $session->init_ok();
  die $session->errors if $session->errors;

  my $poe_main_tbl = $session->get_poe_main_table;
  foreach my $group (sort { $a <=> $b } keys %$poe_main_tbl) {
    printf "PoE Group:   %d\n",          $group;
    printf "OperStatus:  %d\n",          $poe_main_tbl->{$group}{operStatus};
    printf "Power:       %-4d [Watt]\n", $poe_main_tbl->{$group}{power};
    printf "Consumption: %-4d [Watt]\n", $poe_main_tbl->{$group}{consumption};
    printf "Threshold:   %-4d [%%]\n",   $poe_main_tbl->{$group}{threshold};
  }

  my $poe_port_tbl = $session->get_poe_port_table;
  foreach my $group (sort { $a <=> $b } keys %$poe_port_tbl) {
    foreach my $port (sort { $a <=> $b } keys %{$poe_port_tbl->{$group}}) {
      my $adminEnable      = $poe_port_tbl->{$group}{$port}{adminEnable};
      my $powerPairsCtrl   = $poe_port_tbl->{$group}{$port}{powerPairsCtrl};
      my $powerPairs       = $poe_port_tbl->{$group}{$port}{powerPairs};
      my $detectionStatus  = $poe_port_tbl->{$group}{$port}{detectionStatus};
      my $priority         = $poe_port_tbl->{$group}{$port}{priority};
      my $mpsAbsent        = $poe_port_tbl->{$group}{$port}{mpsAbsent};
      my $type             = $poe_port_tbl->{$group}{$port}{type};
      my $powerClass       = $poe_port_tbl->{$group}{$port}{powerClass};
      my $invalidSignature = $poe_port_tbl->{$group}{$port}{invalidSignature};
      my $powerDenied      = $poe_port_tbl->{$group}{$port}{powerDenied};
      my $overload         = $poe_port_tbl->{$group}{$port}{overload};
      my $short            = $poe_port_tbl->{$group}{$port}{short};

      printf "%d %d %d %d %d %d %d %d %s %d %d %d %d %d\n",                                               #
        $group,     $port, $adminEnable, $powerPairsCtrl,   $powerPairs,  $detectionStatus, $priority,    #
        $mpsAbsent, $type, $powerClass,  $invalidSignature, $powerDenied, $overload,        $short;
    }
  }

=head1 DESCRIPTION

A mixin class for power over ethernet related infos from the POWER-ETHERNET-MIB.

=head1 MIXIN METHODS

=head2 B<< OBJ->get_poe_port_table >>

Returns the PoE pethPsePortTable as a hash reference. The table is indexed by the PoE pethMainPseGroupIndex and the portIdx within the group:

  {
    group => INTEGER {
      port => INTEGER {
        adminEnable      => 1|2,
        powerPairsCtrl   => 1|2,
        powerPairs       => 1|2,
        detectionStatus  => 0|1|2|3|4|5|6,
        priority         => 1|2|3,
        mpsAbsent        => COUNTER,
        type             => STRING,
        powerClass       => 0|1|2|3|4|5,
        invalidSignature => COUNTER,
        powerDenied      => COUNTER,
        overload         => COUNTER,
        short            => COUNTER,
      }
    }
  }


=cut

sub get_poe_port_table {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # stash for return values
  my $result = {};

  # the MIB tables are stored in {column}{row}{value} order
  # but we return {row}{column}{value}
  #
  # grab all rows from one random choosen column
  my @rows = keys %{ $session->{$prefix}{poePortTbl}{adminEnable} };

  foreach my $row (@rows) {

    # the rows are the concatenation of 'groupIdx.portIdx'
    # split them into separate values
    my ( $groupIdx, $portIdx ) = split /\./, $row;

    # loop over all columns
    foreach my $column ( keys %{ $session->{$prefix}{poePortTbl} } ) {

      # rebuild in reverse order: result(row,column) = stash(column,row)
      # side effect: make a shallow copy for shallow values
      # side effect: entangle the row 'groupIdx.portIdx'

      $result->{$groupIdx}{$portIdx}{$column} = $session->{$prefix}{poePortTbl}{$column}{$row};
    }
  }

  return $result;
}

=head2 B<< OBJ->get_poe_main_table >>

Returns the PoE pethMainPseTable as a hash reference. The table is indexed by the pethMainPseGroupIndex:

  {
    group => INTEGER {
      power       => GAUGE,
      operStatus  => INTEGER,
      consumption => GAUGE,
      threshold   => INTEGER
    }
  }

=cut

sub get_poe_main_table {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # stash for return values
  my $result = {};

  # the MIB tables are stored in {column}{row}{value} order
  # but we return {row}{column}{value}
  #
  # grab all rows from one random choosen column
  my @rows = keys %{ $session->{$prefix}{poeMainTbl}{power} };

  foreach my $row (@rows) {

    # loop over all columns
    foreach my $column ( keys %{ $session->{$prefix}{poeMainTbl} } ) {

      # rebuild in reverse order: result(row,column) = stash(column,row)
      # side effect: make a shallow copy for shallow values

      $result->{$row}{$column} = $session->{$prefix}{poeMainTbl}{$column}{$row};
    }
  }

  return $result;
}

=head1 INITIALIZATION

=head2 B<< OBJ->_init($reload) >>

Fetch basic interface related snmp values from the host. Don't call this method direct!

=cut

#
# due to the asynchron nature, we don't know what init job is really the last, we decrement
# the value after each callback
#
use constant THIS_INIT_JOBS => 2;

sub _init {
  my ( $session, $reload ) = @_;
  my $agent = $session->hostname;

  die "$agent: $prefix already initialized and reload not forced.\n"
    if exists get_init_slot($session)->{$prefix}
    && get_init_slot($session)->{$prefix} == 0
    && not $reload;

  # set number of async init jobs for proper initialization
  get_init_slot($session)->{$prefix} = THIS_INIT_JOBS;

  # populate the object with needed mib values

  _fetch_poe_main_tbl($session);
  return if $session->error;

  _fetch_poe_port_tbl($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_poe_port_tbl($session) >>

Get selected MIB values from the poe_port_table

=cut

sub _fetch_poe_port_tbl {
  my $session = shift;
  my $result;

  # fetch poe_port_table
  $result = $session->get_table(
    -baseoid => POE_PORT_TABLE,

    # set maxrepetitions for != v1
    $session->version != 0 ? ( -maxrepetitions => 10 ) : (),

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_poe_port_tbl_cb ) : (),
  );

  unless ( defined $result ) {

    # Net::SNMP looses sometimes error messages in nonblocking
    # mode, so we save them in an extra buffer
    my $err_msg = $session->error;
    push_error( $session, "$prefix: $err_msg" ) if $err_msg;
    return;
  }

  # in nonblocking mode the callback will be called asynchronously
  return 1 if $session->nonblocking;

  # ok we are in synchronous mode, call the result mangling function
  # by hand
  _poe_port_tbl_cb($session);

}

=head2 B<< _poe_port_tbl_cb($session) >>

The callback for _poe_port_tbl_cb

=cut

sub _poe_port_tbl_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    my $err_msg = $session->error;
    push_error( $session, "$prefix: $err_msg" ) if $err_msg;
    return;
  }

  $session->{$prefix}{poePortTbl}{adminEnable}      = idx2val( $vbl, POE_PORT_ADMIN_ENABLE );
  $session->{$prefix}{poePortTbl}{powerPairsCtrl}   = idx2val( $vbl, POE_PORT_POWER_PAIRS_CTRL );
  $session->{$prefix}{poePortTbl}{powerPairs}       = idx2val( $vbl, POE_PORT_POWER_PAIRS );
  $session->{$prefix}{poePortTbl}{detectionStatus}  = idx2val( $vbl, POE_PORT_DETECTION_STATUS );
  $session->{$prefix}{poePortTbl}{priority}         = idx2val( $vbl, POE_PORT_POWER_PRIORITY );
  $session->{$prefix}{poePortTbl}{mpsAbsent}        = idx2val( $vbl, POE_PORT_MPS_ABSENT );
  $session->{$prefix}{poePortTbl}{type}             = idx2val( $vbl, POE_PORT_TYPE );
  $session->{$prefix}{poePortTbl}{powerClass}       = idx2val( $vbl, POE_PORT_POWER_CLASS );
  $session->{$prefix}{poePortTbl}{invalidSignature} = idx2val( $vbl, POE_PORT_INVALID_SIGNATURE );
  $session->{$prefix}{poePortTbl}{powerDenied}      = idx2val( $vbl, POE_PORT_POWER_DENIED );
  $session->{$prefix}{poePortTbl}{overload}         = idx2val( $vbl, POE_PORT_OVERLOAD );
  $session->{$prefix}{poePortTbl}{short}            = idx2val( $vbl, POE_PORT_SHORT );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head2 B<< _fetch_poe_main_tbl($session) >>

Get selected MIB values from the poe_main_table

=cut

sub _fetch_poe_main_tbl {
  my $session = shift;
  my $result;

  # fetch poe_port_table
  $result = $session->get_table(
    -baseoid => POE_MAIN_TABLE,

    # set maxrepetitions for != v1
    $session->version != 0 ? ( -maxrepetitions => 10 ) : (),

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_poe_main_tbl_cb ) : (),
  );

  unless ( defined $result ) {

    # Net::SNMP looses sometimes error messages in nonblocking
    # mode, so we save them in an extra buffer
    my $err_msg = $session->error;
    push_error( $session, "$prefix: $err_msg" ) if $err_msg;
    return;
  }

  # in nonblocking mode the callback will be called asynchronously
  return 1 if $session->nonblocking;

  # ok we are in synchronous mode, call the result mangling function
  # by hand
  _poe_main_tbl_cb($session);

}

=head2 B<< _poe_main_tbl_cb($session) >>

The callback for _poe_main_tbl_cb

=cut

sub _poe_main_tbl_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    my $err_msg = $session->error;
    push_error( $session, "$prefix: $err_msg" ) if $err_msg;
    return;
  }

  $session->{$prefix}{poeMainTbl}{power}       = idx2val( $vbl, POE_MAIN_POWER );
  $session->{$prefix}{poeMainTbl}{operStatus}  = idx2val( $vbl, POE_MAIN_OPER_STATUS );
  $session->{$prefix}{poeMainTbl}{consumption} = idx2val( $vbl, POE_MAIN_CONSUMPTION );
  $session->{$prefix}{poeMainTbl}{threshold}   = idx2val( $vbl, POE_MAIN_THRESHOLD );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a bug or are experiencing difficulties that are not explained within the POD documentation, please submit a bug. Fixes are dependant upon their severity and my availablity. Should a fix not be forthcoming, please feel free to (politely) remind me by sending an email.

=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2021-2024 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

unless ( caller() ) {
  print __PACKAGE__ . " compiles and initializes successful.\n";
}

1;

# vim: sw=2
