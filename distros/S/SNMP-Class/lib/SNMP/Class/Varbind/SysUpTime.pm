package SNMP::Class::Varbind::SysUpTime;

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
	SNMP::Class::Varbind::register_handler("label","sysUpTimeInstance",__PACKAGE__);
	DEBUG "Handler for ".__PACKAGE__." registered";
}

sub initialize_callback_object {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	my $uptime = $self->raw_value;
	my $time = time;
	my $absolute = $uptime + $time;
	$self->{absolute_time} = scalar localtime $absolute;
}

sub get_absolute {
	return $_[0]->{absolute_time};
}

1;
