=head1 NAME

Mon::SNMP - decode SNMP trap

=head1 SYNOPSIS

    use Mon::SNMP;

    $trap = new Mon::SNMP;

    $trap->buffer($snmptrap);

    %traphash = $trap->decode;

    $error = $trap->error;


=head1 DESCRIPTION

Mon::SNMP provides methods to decode SNMP trap PDUs. It is based on
Graham Barr's Convert::BER module, and its purpose is to provide
SNMP trap handling to "mon".

=head1 METHODS

=over 4

=item B<new>

creates a new Mon::SNMP object.

=item B<buffer> ( buffer )

Assigns a raw SNMP trap message to the object.

=item B<decode>

Decodes a SNMP trap message, and returns a hash of the variable
assignments for the SNMP header and trap protocol data unit of the
associated message. The hash consists of the following members:

        version         =>      SNMP version (1)
        community       =>      community string
        ent_OID         =>      enterprise OID of originating agent
        agentaddr       =>      IP address of originating agent
        generic_trap    =>      /COLDSTART|WARMSTART|LINKDOWN|LINKUP|AUTHFAIL|EGPNEIGHBORLOSS|ENTERPRISESPECIFIC/
        specific_trap   =>      specific trap type (integer)
        timeticks       =>      timeticks (integer)
        varbindlist     =>      { oid1 => value, oid2 => value, ... }

=back

=head1 ERRORS

All methods return a hash with no elements upon errors which they detect,
and the detail of the error is available from the 

=head1 EXAMPLES

    use Mon::SNMP;

    $trap = new Mon::SNMP;

    $trap->buffer($snmptrap);

    %traphash = $trap->decode;

    foreach $oid (keys $traphash{"varbindlist"}) {
	$val = $traphash{"varbindlist"}{$oid};
    	print "oid($oid) = val($val)\n";
    }

=head1 ENVIRONMENT

None.

=head1 SEE ALSO

Graham Barr's Convert::BER module.

=head1 NOTES

=head1 CAVEATS

Mon::SNMP depends upon Convert::BER to do the real work.

=cut

#
#
# $Id: SNMP.pm 1.3 Thu, 11 Jan 2001 08:42:17 -0800 trockij $
#
# Copyright (C) 1998 Jim Trocki
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

package Mon::SNMP;

require Exporter;
require 5.004;

use Convert::BER;
use Convert::BER qw(/^(\$|BER_)/);
use Socket;

@ISA = qw(Exporter);
@EXPORT_OK = qw(@traptypes @ASN_DEFS $VERSION);

$VERSION = "0.11";

@traptypes = ("COLDSTART", "WARMSTART", "LINKDOWN", "LINKUP", "AUTHFAIL",
	"EGPNEIGHBORLOSS", "ENTERPRISESPECIFIC");

@ASN_DEFS = (
	[ Trap_PDU              => $SEQUENCE,      BER_CONTEXT | BER_CONSTRUCTOR     | 0x04 ],
	[ IpAddress             => $STRING,        BER_APPLICATION                   | 0x00 ],
	[ Counter               => $INTEGER,       BER_APPLICATION                   | 0x01 ],
	[ Gauge                 => $INTEGER,       BER_APPLICATION                   | 0x02 ],
	[ TimeTicks             => $INTEGER,       BER_APPLICATION                   | 0x03 ],
	[ Opaque                => undef,          BER_APPLICATION                   | 0x04 ],
);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

    $self->{"ERROR"} = undef;
    $self->{"version"} = undef;
    $self->{"community"} = undef;
    $self->{"ent_OID"} = undef;
    $self->{"agentaddr"} = undef;
    $self->{"generic_trap"} = undef;
    $self->{"specific_trap"} = undef;
    $self->{"timeticks"} = undef;
    %{$self->{"varbindlist"}} = ();
    $self->{"ber_varbindlist"} = undef;

    $self->{"BER"} = Convert::BER->new;
    $self->{"BER"}->define(@ASN_DEFS);

    bless ($self, $class);
    return $self;
}


sub error {
    my $self = shift;

    return $self->{"ERROR"};
}


sub buffer {
    my $self = shift;
    my $buf = shift;

    $self->{"ERROR"} = undef;

    $self->{"BER"}->buffer($buf);
}


sub decode {
    my $self = shift;
    my ($oid, $val);

    $self->{"ERROR"} = undef;

    if (! $self->{"BER"}->decode (
		SEQUENCE => [
		    INTEGER => \$self->{"version"},
		    STRING => \$self->{"community"},
		    Trap_PDU => [
			OBJECT_ID => \$self->{"ent_OID"},
			IpAddress => \$self->{"agentaddr"},
			INTEGER => \$self->{"generic_trap"},
			INTEGER => \$self->{"specific_trap"},
			TimeTicks => \$self->{"timeticks"},
			SEQUENCE => [
			    ANY => \$self->{"ber_varbindlist"},
			],
		    ],
		],
	    )) {
	
	$self->{"ERROR"} = "problem decoding BER";
	return ();
    }


   while ($self->{"ber_varbindlist"}->decode (
		SEQUENCE => [
			OBJECT_ID => \$oid,
			ANY => \$val,
		]
				)) {

	$self->{"varbindlist"}->{$oid} = $val;
   }

   return (
   	version		=>	$self->{"version"},
	community	=>	$self->{"community"},
	ent_OID		=>	$self->{"ent_OID"},
	agentaddr	=>	inet_aton ($self->{"agentaddr"}),
	generic_trap	=>	$traptypes[$self->{"generic_trap"}],
	specific_trap	=>	$self->{"specific_trap"},
	timeticks	=>	$self->{"timeticks"},
	varbindlist	=>	$self->{"varbindlist"},
   );
}


sub dump {
    my $self = shift;

    $self->{"BER"}->dump;
}

