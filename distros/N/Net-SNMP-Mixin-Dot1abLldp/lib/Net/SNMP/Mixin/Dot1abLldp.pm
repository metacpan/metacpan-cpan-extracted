package Net::SNMP::Mixin::Dot1abLldp;

use strict;
use warnings;

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
use Net::SNMP::Mixin::Util qw/normalize_mac idx2val push_error get_init_slot/;

#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (
    qw/
      get_lldp_local_system_data
      get_lldp_loc_port_table
      get_lldp_rem_table
      /
  );
}

use Sub::Exporter -setup => {
  exports   => [@mixin_methods],
  groups    => { default => [@mixin_methods], },
};

#
# SNMP oid constants used in this module
#
# from lldpMIB
use constant {
  LLDP_LOCAL_SYSTEM_DATA       => '1.0.8802.1.1.2.1.3',
  LLDP_LOCAL_CASSIS_ID_SUBTYPE => '1.0.8802.1.1.2.1.3.1.0',
  LLDP_LOCAL_CASSIS_ID         => '1.0.8802.1.1.2.1.3.2.0',
  LLDP_LOCAL_SYS_NAME          => '1.0.8802.1.1.2.1.3.3.0',
  LLDP_LOCAL_SYS_DESC          => '1.0.8802.1.1.2.1.3.4.0',
  LLDP_LOCAL_SYS_CAPA_SUP      => '1.0.8802.1.1.2.1.3.5.0',
  LLDP_LOCAL_SYS_CAPA_ENA      => '1.0.8802.1.1.2.1.3.6.0',

  LLDP_LOC_PORT_TABLE      => '1.0.8802.1.1.2.1.3.7',
  LLDP_LOC_PORT_NUM        => '1.0.8802.1.1.2.1.3.7.1.1',
  LLDP_LOC_PORT_ID_SUBTYPE => '1.0.8802.1.1.2.1.3.7.1.2',
  LLDP_LOC_PORT_ID         => '1.0.8802.1.1.2.1.3.7.1.3',
  LLDP_LOC_PORT_DESC       => '1.0.8802.1.1.2.1.3.7.1.4',

  LLDP_REM_TABLE             => '1.0.8802.1.1.2.1.4.1',
  LLDP_REM_LOCAL_PORT_NUM    => '1.0.8802.1.1.2.1.4.1.1.2',
  LLDP_REM_CASSIS_ID_SUBTYPE => '1.0.8802.1.1.2.1.4.1.1.4',
  LLDP_REM_CASSIS_ID         => '1.0.8802.1.1.2.1.4.1.1.5',
  LLDP_REM_PORT_ID_SUBTYPE   => '1.0.8802.1.1.2.1.4.1.1.6',
  LLDP_REM_PORT_ID           => '1.0.8802.1.1.2.1.4.1.1.7',
  LLDP_REM_PORT_DESC         => '1.0.8802.1.1.2.1.4.1.1.8',
  LLDP_REM_SYS_NAME          => '1.0.8802.1.1.2.1.4.1.1.9',
  LLDP_REM_SYS_DESC          => '1.0.8802.1.1.2.1.4.1.1.10',
  LLDP_REM_SYS_CAPA_SUP      => '1.0.8802.1.1.2.1.4.1.1.11',
  LLDP_REM_SYS_CAPA_ENA      => '1.0.8802.1.1.2.1.4.1.1.12',
};

=head1 NAME

Net::SNMP::Mixin::Dot1abLldp - mixin class for the Link Layer Discovery Protocol

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

A Net::SNMP mixin class for LLDP (Link Layer Discovery Protocol) based info.

  use Net::SNMP;
  use Net::SNMP::Mixin;

  #...

  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );

  $session->mixer('Net::SNMP::Mixin::Dot1abLldp');
  $session->init_mixins;
  snmp_dispatcher();
  $session->init_ok();
  die $session->errors if $session->errors;

  printf "Local ChassisID: %s\n",
    $session->get_lldp_local_system_data->{lldpLocChassisId};

  $lldp_loc_port_tbl = $session->get_lldp_loc_port_table;
  $lldp_rem_tbl      = $session->get_lldp_rem_table;

  foreach $lport ( keys %$lldp_rem_tbl ) {
    foreach $idx ( keys %{ $lldp_rem_tbl->{$lport} } ) {
      my $lldpRemSysName   = $lldp_rem_tbl->{$lport}{$idx}{lldpRemSysName};
      my $lldpRemPortId    = $lldp_rem_tbl->{$lport}{$idx}{lldpRemPortId};
      my $lldpRemPortDesc  = $lldp_rem_tbl->{$lport}{$idx}{lldpRemPortDesc};
      my $lldpRemChassisId = $lldp_rem_tbl->{$lport}{$idx}{lldpRemChassisId};
      my $ldesc            = $lldp_loc_port_tbl->{$lport}{lldpLocPortDesc};

      printf "$lport:$ldesc => $lldpRemSysName:$lldpRemPortId:$lldpRemPortDesc:$lldpRemChassisId\n";
    }
  }

=cut

=head1 DESCRIPTION

With this mixin it's simple to explore the Layer-2 topologie of the network.

The LLDP (Link Layer Discovery Protocol) is an IEEE (Draft?) standard for vendor-independent Layer-2 discovery, similar to the proprietary CDP (Cisco Discovery Protocol) from Cisco. It's defined in the IEEE 802.1AB documents, therefore the name of this module.

This mixin reads data from the B<< lldpLocalSystemData >>, B<< lldpLocPortTable >>  and the B<< lldpRemTable >> out of the LLDP-MIB. At least these values are in the mandatory set of the LLDP-MIB.

=head1 MIXIN METHODS

=head2 B<< OBJ->get_lldp_local_system_data() >>

Returns the LLDP lldpLocalSystemData group as a hash reference:

  {
    lldpLocChassisIdSubtype => Integer,
    lldpLocChassisId        => OCTET_STRING,
    lldpLocSysName          => OCTET_STRING,
    lldpLocSysDesc          => OCTET_STRING,
    lldpLocSysCapSupported  => BITS,
    lldpLocSysCapEnabled    => BITS,
  }

=cut

sub get_lldp_local_system_data {
  my $session = shift;
  my $agent = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # just a shallow copy for shallow values
  my $result = { %{ $session->{$prefix}{locSysData} } };

  # if the chassisIdSubtype has the enumeration 'macAddress(4)'
  # we normalize the MacAddress
  $result->{lldpLocChassisId} = normalize_mac( $result->{lldpLocChassisId} )
    if defined $result->{lldpLocChassisIdSubtype} && $result->{lldpLocChassisIdSubtype} == 4;

  return $result;
}

=head2 B<< OBJ->get_lldp_loc_port_table() >>

Returns the LLDP lldp_loc_port_table as a hash reference. The table is indexed by the LLDP local port numbers:

  {
     lldpLocPortNum => {
	lldpLocPortIdSubtype => INTEGER,
	lldpLocPortId        => OCTET_STRING,
	lldpLocPortDesc      => OCTET_STRING,
     }
  }

The LLDP portnumber isn't necessarily the ifIndex of the switch. See the TEXTUAL-CONVENTION from the LLDP-MIB:

  "A port number has no mandatory relationship to an
  InterfaceIndex object (of the interfaces MIB, IETF RFC 2863).
  If the LLDP agent is a IEEE 802.1D, IEEE 802.1Q bridge, the
  LldpPortNumber will have the same value as the dot1dBasePort
  object (defined in IETF RFC 1493) associated corresponding
  bridge port.  If the system hosting LLDP agent is not an
  IEEE 802.1D or an IEEE 802.1Q bridge, the LldpPortNumber
  will have the same value as the corresponding interface's
  InterfaceIndex object."

See also the L<< Net::SNMP::Mixin::Dot1dBase >> for a mixin to get the mapping between the ifIndexes and the dot1dBasePorts if needed.

=cut


sub get_lldp_loc_port_table {
  my $session = shift;
  my $agent = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # stash for return values
  my $result = {};

  #
  # the MIB tables are stored in {column}{row}{value} order
  # but we return {row}{column}{value}
  #
  # grab all rows from one choosen column
  my @rows = keys %{ $session->{$prefix}{lldpLocPortTbl}{lldpLocPortId} };

  foreach my $row (@rows) {

    # loop over all columns
    foreach my $column ( keys %{ $session->{$prefix}{lldpLocPortTbl} } ) {

      # rebuild in reverse order: result(row,column) = stash(column,row)
      # side effect: make a shallow copy for shallow values

      $result->{$row}{$column} =
        $session->{$prefix}{lldpLocPortTbl}{$column}{$row};
    }

  }

  return $result;
}

=head2 B<< OBJ->get_lldp_rem_table() >>

Returns the LLDP lldp_rem_table as a hash reference. The table is indexed by the LLDP local port numbers on which the remote system information is received and an index for multiple neighbors on one port:

  {
    lldpRemLocalPortNum => {
      lldpRemIndex => {
        lldpRemChassisIdSubtype => INTEGER,
        lldpRemChassisId        => OCTET_STRING,
        lldpRemPortIdSubtype    => INTEGER,
        lldpRemPortId           => OCTET_STRING,
        lldpRemPortDesc         => OCTET_STRING,
        lldpRemSysName          => OCTET_STRING,
        lldpRemSysDesc          => OCTET_STRING,
        lldpRemSysCapSupported  => BITS,
        lldpRemSysCapEnabled    => BITS,
      }
    }
  }

=cut

sub get_lldp_rem_table {
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
  my @rows = keys %{ $session->{$prefix}{lldpRemTbl}{lldpRemPortId} };

  foreach my $row (@rows) {

    # the rows are the concatenation of 'lldpRemLocalPortNum.lldpRemIndex'
    # split them into separate values
    my ( $lldpRemLocalPortNum, $lldpRemIndex ) = split /\./, $row;

    # loop over all columns
    foreach my $column ( keys %{ $session->{$prefix}{lldpRemTbl} } ) {

      # rebuild in reverse order: result(row,column) = stash(column,row)
      # side effect: make a shallow copy for shallow values
      # side effect: entangle the row 'lldpRemLocalPortNum.lldpRemIndex'

      $result->{$lldpRemLocalPortNum}{$lldpRemIndex}{$column} =
        $session->{$prefix}{lldpRemTbl}{$column}{$row};
    }

    # if the chassisIdSubtype has the enumeration 'macAddress(4)'
    # we normalize the MacAddress
    my $chassisIdSubtype =
      $result->{$lldpRemLocalPortNum}{$lldpRemIndex}{lldpRemChassisIdSubtype};

    if ( defined $chassisIdSubtype && $chassisIdSubtype == 4 ) {
      $result->{$lldpRemLocalPortNum}{$lldpRemIndex}{lldpRemChassisId} =
        normalize_mac( $result->{$lldpRemLocalPortNum}{$lldpRemIndex}{lldpRemChassisId} );
    }

  }

  return $result;
}

=head1 INITIALIZATION

=head2 B<< OBJ->_init($reload) >>

Fetch the LLDP related snmp values from the host. Don't call this method direct!

=cut

#
# due to the asynchron nature, we don't know what init job is really the last, we decrement
# the value after each callback
#
use constant THIS_INIT_JOBS => 3;

sub _init {
  my ($session, $reload) = @_;
  my $agent = $session->hostname;

  die "$agent: $prefix already initialized and reload not forced.\n"
    if exists get_init_slot($session)->{$prefix}
      && get_init_slot($session)->{$prefix} == 0
      && not $reload;

  # set number of async init jobs for proper initialization
  get_init_slot($session)->{$prefix} = THIS_INIT_JOBS;

  # populate the object with needed mib values
  #
  # initialize the object for LLDP infos
  _fetch_lldp_local_system_data($session);
  return if $session->error;

  _fetch_lldp_loc_port_tbl($session);
  return if $session->error;

  _fetch_lldp_rem_tbl($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_lldp_local_system_data($session) >>

Fetch the local system data from the lldpMIB once during object initialization.

=cut

sub _fetch_lldp_local_system_data {
  my $session = shift;
  my $result;

  # use get_entries instead of get_request since the
  # result will be true in case of missing values
  # the values are just noSuchObject
  # with get_entries() we get error messages for free
    
  $result = $session->get_entries(
    -columns    => [ LLDP_LOCAL_SYSTEM_DATA, ],
    -endindex   => '6.0', # LLDP_LOCAL_SYS_CAPA_ENA

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_lldp_local_system_data_cb ) : (),

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
  _lldp_local_system_data_cb($session);
}

=head2 B<< _lldp_local_system_data_cb($session) >>

The callback for _fetch_lldp_local_system_data.

=cut

sub _lldp_local_system_data_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless (defined $vbl) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  $session->{$prefix}{locSysData}{lldpLocChassisIdSubtype} =
    $vbl->{ LLDP_LOCAL_CASSIS_ID_SUBTYPE() };

  $session->{$prefix}{locSysData}{lldpLocChassisId} =
    $vbl->{ LLDP_LOCAL_CASSIS_ID() };

  $session->{$prefix}{locSysData}{lldpLocSysName} =
    $vbl->{ LLDP_LOCAL_SYS_NAME() };

  $session->{$prefix}{locSysData}{lldpLocSysDesc} =
    $vbl->{ LLDP_LOCAL_SYS_DESC() };

  $session->{$prefix}{locSysData}{lldpLocSysCapSupported} =
    $vbl->{ LLDP_LOCAL_SYS_CAPA_SUP() };

  $session->{$prefix}{locSysData}{lldpLocSysCapEnabled} =
    $vbl->{ LLDP_LOCAL_SYS_CAPA_ENA() };

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head2 B<< _fetch_lldp_loc_port_tbl($session) >>

Fetch the lldpLocPortTable once during object initialization.

=cut

sub _fetch_lldp_loc_port_tbl {
  my $session = shift;
  my $result;

  # fetch the lldpLocPortTable
  $result = $session->get_table(
    -baseoid => LLDP_LOC_PORT_TABLE,

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_lldp_loc_port_tbl_cb ) : (),
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
  _lldp_loc_port_tbl_cb($session);

}

=head2 B<< _lldp_loc_port_tbl_cb($session) >>

The callback for _fetch_lldp_loc_port_tbl_cb().

=cut

sub _lldp_loc_port_tbl_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;


  unless (defined $vbl) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  # mangle result table to get plain idx->value

  $session->{$prefix}{lldpLocPortTbl}{lldpLocPortIdSubtype} =
    idx2val( $vbl, LLDP_LOC_PORT_ID_SUBTYPE );

  $session->{$prefix}{lldpLocPortTbl}{lldpLocPortId} =
    idx2val( $vbl, LLDP_LOC_PORT_ID );

  $session->{$prefix}{lldpLocPortTbl}{lldpLocPortDesc} =
    idx2val( $vbl, LLDP_LOC_PORT_DESC );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head2 B<< _fetch_lldp_rem_tbl($session) >>

Fetch the lldpRemTable once during object initialization.

=cut

sub _fetch_lldp_rem_tbl {
  my $session = shift;
  my $result;

  # fetch the lldpRemTable
  $result = $session->get_table(
    -baseoid => LLDP_REM_TABLE,

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_lldp_rem_tbl_cb ) : (),
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
  _lldp_rem_tbl_cb($session);

}

=head2 B<< _lldp_rem_tbl_cb($session) >>

The callback for _fetch_lldp_rem_tbl_cb().

=cut

sub _lldp_rem_tbl_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless (defined $vbl) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    }
    return;
  }

  # mangle result table to get plain idx->value
  #---------------------------------------------------------------
  # the tableIndex is a little bit tricky, please see the LLDP-MIB
  #---------------------------------------------------------------
  #
  # .1.0.8802.1.1.2.1.4.1.1.11[.0.20.1]
  #                             ^  ^ ^
  #                             |  | |
  #           lldpRemTimeMark---/  | |
  #                                | |
  #           lldpRemLocalPortNum--/ |
  #                                  |
  #           lldpRemIndex-----------/
  #
  #---------------------------------------------------------------
  # lldpRemEntry OBJECT-TYPE
  #    SYNTAX          LldpRemEntry
  #    MAX-ACCESS      not-accessible
  #    STATUS          current
  #    DESCRIPTION
  #        "Information about a particular physical network connection.
  #        Entries may be created and deleted in this table by the agent,
  #        if a physical topology discovery process is active."
  #    INDEX           {
  #                        lldpRemTimeMark,
  #                        lldpRemLocalPortNum,
  #                        lldpRemIndex
  #                    }
  #    ::= { lldpRemTable 1 }
  # -----------------------------------------------

  # mangle result table to get plain idx->value
  # cut off the variable lldpRemTimeMark as pre
  #
  # result hashes: lldpRemLocalPortNum.lldpRemIndex => values
  #

  $session->{$prefix}{lldpRemTbl}{lldpRemChassisIdSubtype} =
    idx2val( $vbl, LLDP_REM_CASSIS_ID_SUBTYPE, 1, undef, );

  $session->{$prefix}{lldpRemTbl}{lldpRemChassisId} =
    idx2val( $vbl, LLDP_REM_CASSIS_ID, 1, undef, );

  $session->{$prefix}{lldpRemTbl}{lldpRemPortIdSubtype} =
    idx2val( $vbl, LLDP_REM_PORT_ID_SUBTYPE, 1, undef, );

  $session->{$prefix}{lldpRemTbl}{lldpRemPortId} =
    idx2val( $vbl, LLDP_REM_PORT_ID, 1, undef, );

  $session->{$prefix}{lldpRemTbl}{lldpRemPortDesc} =
    idx2val( $vbl, LLDP_REM_PORT_DESC, 1, undef, );

  $session->{$prefix}{lldpRemTbl}{lldpRemSysName} =
    idx2val( $vbl, LLDP_REM_SYS_NAME, 1, undef, );

  $session->{$prefix}{lldpRemTbl}{lldpRemSysDesc} =
    idx2val( $vbl, LLDP_REM_SYS_DESC, 1, undef, );

  $session->{$prefix}{lldpRemTbl}{lldpRemSysCapSupported} =
    idx2val( $vbl, LLDP_REM_SYS_CAPA_SUP, 1, undef, );

  $session->{$prefix}{lldpRemTbl}{lldpRemSysCapEnabled} =
    idx2val( $vbl, LLDP_REM_SYS_CAPA_ENA, 1, undef, );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

unless ( caller() ) {
  print "$prefix compiles and initializes successful.\n";
}

=head1 SEE ALSO

L<< Net::SNMP::Mixin::Dot1dBase >>

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a bug or are experiencing difficulties that are not explained within the POD documentation, please submit a bug to the RT system (see link below). However, it would help greatly if you are able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not be forthcoming, please feel free to (politely) remind me by sending an email to gaissmai@cpan.org .

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin-Dot1abLldp


=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2016 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

# vim: sw=2
