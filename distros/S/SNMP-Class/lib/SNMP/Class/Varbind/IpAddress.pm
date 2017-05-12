package SNMP::Class::Varbind::IpAddress;

use warnings;
use strict;
use Carp qw(cluck carp croak confess);
use SNMP::Class::OID;
use Data::Dumper;
use Log::Log4perl qw(:easy);


use base qw(SNMP::Class::Varbind);


#we have to call the register_callback function in the INIT block to make sure
#that the SNMP::Class::Varbind module is actually loaded
INIT {
	SNMP::Class::Varbind::register_handler("syntax","IPADDR",__PACKAGE__);
	DEBUG "Handler for IpAddress registered";
}



1;
