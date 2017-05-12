# -*- perl -*-
#
#
#   SNMP::Monitor - a Perl package for monitoring remote hosts via SNMP
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#

use strict;


require Sys::Syslog;
require DBI;


package SNMP::Monitor::Event::IfLoad;

use vars qw(@ISA $VERSION $CREATE_QUERY $ITYPES);

$VERSION = '0.1000';
@ISA = qw(SNMP::Monitor::Event);

$CREATE_QUERY = <<'QUERY';
CREATE TABLE SNMPMON_IFLOAD (
  HOST VARCHAR(10) NOT NULL,
  INTERFACE SMALLINT NOT NULL,
  INTERVAL_END DATETIME NOT NULL,
  INOCTETS INT NOT NULL,
  OUTOCTETS INT NOT NULL,
  UTILIZATION REAL NOT NULL,
  ADMINSTATUS TINYINT NOT NULL,
  OPERSTATUS TINYINT NOT NULL,
  INDEX (HOST, INTERFACE, INTERVAL_END)
)
QUERY

$ITYPES = [
#   Interface type              Full-Duplex
    undef,
    [ 'other',                  0 ],
    [ 'regular1822',            1 ],
    [ 'hdh1822',                1 ],
    [ 'ddn-x25',                1 ],
    [ 'rfc877-x25',             1 ],
    [ 'ethernet-csmacd',        0 ],
    [ 'iso88023-csmacd',        0 ],
    [ 'iso88024-tokenBus',      0 ],
    [ 'iso88025-tokenRing',     0 ],
    [ 'iso88026-man',           0 ],
    [ 'starLan',                0 ],
    [ 'proteon-10Mbit',         0 ],
    [ 'proteon-80Mbit',         0 ],
    [ 'hyperchannel',           0 ],
    [ 'fddi',                   0 ],
    [ 'lapb',                   1 ],
    [ 'sdlc',                   1 ],
    [ 'ds1',                    1 ],
    [ 'e1',                     1 ],
    [ 'basicISDN',              1 ],
    [ 'primaryISDN',            1 ],
    [ 'propPointToPointSerial', 1 ],
    [ 'ppp',                    1 ],
    [ 'softwareLoopback',       0 ],
    [ 'eon',                    0 ],
    [ 'ethernet-3Mbit',         0 ],
    [ 'nsip',                   0 ],
    [ 'slip',                   1 ],
    [ 'ultra',                  0 ],
    [ 'ds3',                    1 ],
    [ 'sip',                    1 ],
    [ 'frame-relay',            1 ]
];


sub new ($$$) {
    my($proto, $session, $attr) = @_;
    my $self = $proto->SUPER::new($session, $attr);
    $self->{init_count} = 5;

    my $table = "interfaces.ifTable.ifEntry";
    my $num = $self->{'num'};
    $self->{vars} = [ SNMP::Varbind->new(["$table.ifDescr", $num]),
		      SNMP::Varbind->new(["$table.ifInOctets", $num]),
		      SNMP::Varbind->new(["$table.ifOutOctets", $num]),
		      SNMP::Varbind->new(["$table.ifSpeed", $num]),
		      SNMP::Varbind->new(["$table.ifType", $num]),
		      SNMP::Varbind->new(["$table.ifAdminStatus", $num]),
		      SNMP::Varbind->new(["$table.ifOperStatus", $num]) ];
    if ($self->{'combo'}) {
	foreach my $num (@{$self->{'combo'}}) {
	    push(@{$self->{'vars'}},
		 SNMP::Varbind->new(["$table.ifInOctets", $num]),
		 SNMP::Varbind->new(["$table.ifOutOctets", $num]),
		 SNMP::Varbind->new(["$table.ifSpeed", $num]));
	}
    }

    #
    #   Decide whether this is a full duplex interface; code borrowed
    #   from the 'ifload' script of the scotty package by Juergen
    #   Schoenwaelder
    #
    my $type = $self->{'type'};
    if ($type =~ /^(\d+)$/) {
	my $ref = $ITYPES->[$type];
	if (defined($ref)) {
	    $self->{full_duplex} = $ref->[1];
	}
    } else {
	my $ref;
	foreach $ref (@$ITYPES) {
	    if ($ref  &&  $ref->[0] eq $type) {
		$self->{full_duplex} = $ref->[1];
		last;
	    }
	}
    }

    if (!defined($self->{full_duplex})) {
	die "Unknown interface type: $type";
    }

    $self;
}


sub GetVars ($) {
    my $self = shift;
    my $session = $self->{'session'};
    my $vr_session = $session->{'vars_registered'};
    my $vr_self = $self->{'vars_registered'};

    # The following list corresponds to the list in the 'new' method.
    # This is important when calculating the index $i in $vr_self->[$i].
    my %v;
    my $i = 0;
    $v{'ifDescr'}       = $vr_session->[$vr_self->[$i++]]->[0]->[2];
    $v{'ifInOctets'}    = $vr_session->[$vr_self->[$i++]]->[0]->[2];
    $v{'ifOutOctets'}   = $vr_session->[$vr_self->[$i++]]->[0]->[2];
    $v{'ifSpeed'}       = $vr_session->[$vr_self->[$i++]]->[0]->[2]
	|| $self->{'speed'};
    $v{'ifType'}        = $vr_session->[$vr_self->[$i++]]->[0]->[2];
    $v{'ifAdminStatus'} = $vr_session->[$vr_self->[$i++]]->[0]->[2];
    $v{'ifOperStatus'}  = $vr_session->[$vr_self->[$i++]]->[0]->[2];

    if ($self->{'combo'}) {
	$v{'ifUtilSpeed'} = $v{'ifSpeed'};
	foreach my $num (@{$self->{'combo'}}) {
	    $v{'ifInOctets'} += $vr_session->[$vr_self->[$i++]]->[0]->[2];
	    $v{'ifOutOctets'} += $vr_session->[$vr_self->[$i++]]->[0]->[2];
	    $v{'ifUtilSpeed'} += $vr_session->[$vr_self->[$i++]]->[0]->[2];
	}
    }

    return wantarray ? (\%v, $i) : \%v;
}


sub Verify ($$) {
    my $self = shift; my $v = shift;

    my $num = $self->{'num'};
    if ($self->{'description'} ne $v->{'ifDescr'}  ||
	$self->{'speed'}       ne $v->{'ifSpeed'}  ||
	$self->{'type'}        ne $v->{'ifType'}) {
	if (!$self->{'err_msg_mismatch'}) {
	    $self->{'err_msg_mismatch'} =
		$self->Message(subject => 'Router config mismatch',
			       body => <<"MSG");

The configuration of interface $num doesn't match the detected parameters.
The configured parameters are:

    Interface description:  $self->{'description'}
    Interface speed:        $self->{'speed'}
    Interface type:         $self->{'type'}

The detected parameters are:

    Interface description:  $v->{'ifDescr'}
    Interface speed:        $v->{'ifSpeed'}
    Interface type:         $v->{'ifType'}

I won't send further messages until the configured parameters match or
the SNMP::Monitor is restarted.

MSG
        }
    } else {
	if ($self->{'err_msg_mismatch'}) {
	    $self->{err_msg_mismatch} =
		!$self->Message(subject => 'Router config mismatch is gone',
				body => <<"MSG");

The configuration of interface $num didn't match the detected parameters.
This seems to be the case no longer. The detected parameters are:

    Interface description:  $self->{'description'}
    Interface speed:        $self->{'speed'}
    Interface type:         $self->{'type'}

MSG
	}
    }
}


sub Calculate ($$) {
    my $self = shift; my $v = shift;
    my $session = $self->{'session'};
    my $time = $session->{'time'};
    my $oldTime = $self->{'time'};
    $self->{'time'} = $time;

    my $ifInOctets = $v->{'ifInOctets'};
    my $oldIfInOctets = $self->{'ifInOctets'};
    $self->{'ifInOctets'} = $ifInOctets;
    if (defined($oldIfInOctets)) {
	$ifInOctets -= $oldIfInOctets;
    } else {
	$ifInOctets = 0;
    }

    my $ifOutOctets = $v->{'ifOutOctets'};
    my $oldIfOutOctets = $self->{'ifOutOctets'};
    $self->{'ifOutOctets'} = $ifOutOctets;
    if (defined($oldIfOutOctets)) {
	$ifOutOctets -= $oldIfOutOctets;
    } else {
	$ifOutOctets = 0;
    }

    my $utilization;
    if ($ifInOctets > 0  ||  $ifOutOctets > 0) {
	my $delta;
		if ($self->{'full_duplex'}) {
	    $delta = ($ifInOctets > $ifOutOctets) ? $ifInOctets : $ifOutOctets;
	} else {
	    $delta = $ifInOctets + $ifOutOctets;
	}
	my $divisor = ($time - $oldTime) * 
	    ($v->{'ifUtilSpeed'} || $v->{'ifSpeed'});
	if ($divisor) {
	    $utilization = ($delta * 8 * 100.0) / $divisor;
	} else {
	  Sys::Syslog::syslog('err',
			      sprintf("IfLoad: Divisor is zero (utilspeed ="
				      . " %s, speed = %s, time = %s, oldTime = %s\n",
				      $v->{'ifUtilSpeed'},
				      $v->{'ifSpeed'},
				      $time,
				      $oldTime));
	}
    } else {
	$utilization = 0.0;
    }

    $v->{'ifInOctets'} = $ifInOctets;
    $v->{'oldIfInOctets'} = $oldIfInOctets;
    $v->{'ifOutOctets'} = $ifOutOctets;
    $v->{'oldIfOutOctets'} = $oldIfOutOctets;
    $v->{'utilization'} = $utilization;
}


sub _FromUnixTime {
    my($sec, $min, $hour, $mday, $mon, $year) = localtime(shift);
    sprintf('%04d-%02d-%02d %02d:%02d:%02d',
	    $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

sub Query {
    my($self, $session, $v) = @_;
    my $dbh = $session->{config}->{dbh};

    my $name = $session->{'name'};
    my $num = $self->{'num'};
    my $ifInOctets = $v->{'ifInOctets'} || 0;
    $ifInOctets = 0 if $ifInOctets < 0;
    my $oldIfInOctets = $v->{'oldIfInOctets'};
    my $ifOutOctets = $v->{'ifOutOctets'} || 0;
    $ifOutOctets = 0 if $ifOutOctets < 0;
    my $oldIfOutOctets = $v->{'oldIfOutOctets'};

    if ($session->{'config'}->{'debug'}) {
        Sys::Syslog::syslog
	    ('debug',
	     "IfLoad: Host %s, interface %d: InOctets %s => %d,"
	     . " OutOctets %s => %d",
	     $name, $num,
	     defined($oldIfInOctets) ? $oldIfInOctets : "undef",
	     $ifInOctets, defined($oldIfOutOctets) ? $oldIfOutOctets : "undef",
	     $ifOutOctets);
    }

    $dbh->do("INSERT INTO SNMPMON_IFLOAD VALUES (?, ?, ?,"
	     . " ?, ?, ?, ?, ?)",
	     undef, $name, $num, _FromUnixTime($session->{'time'}),
	     $ifInOctets,
	     $ifOutOctets,
	     $v->{'utilization'} || 0.0,
	     ($v->{'ifAdminStatus'} || 0),
	     ($v->{'ifOperStatus'} || 0));
}


sub Log {
    my $self = shift; my $v = shift;
    my $session = $self->{session};

    if (!$self->Query($session, $v)) {
	my $dbh = $session->{'config'}->{'dbh'};
	my $errmsg = $dbh->errstr();
	my $host = $session->{'name'};

	$self->Message(subject => 'Database error',
		       body => <<"MSG")

A database error occurred, while logging the following values:

    Host name:         $host
    Interface number:  $self->{'num'}
    Time:              $session->{'time'}
    InOctets:          $v->{'ifInOctets'}
    OutOctets:         $v->{'ifOutOctets'}
    Utilization:       $v->{'utilization'}
    AdminStatus:       $v->{'ifAdminStatus'}
    OperStatus:        $v->{'ifOperStatus'}

The database error message was:

$errmsg

I will send another message for any following database error, so that you
can add the entry later.

MSG
    }
}


sub Process ($) {
    my $self = shift;
    my $session = $self->{session};
    my $v = $self->GetVars();

    $self->Verify($v);
    $self->Calculate($v);
    $self->Log($v);
}


1;
