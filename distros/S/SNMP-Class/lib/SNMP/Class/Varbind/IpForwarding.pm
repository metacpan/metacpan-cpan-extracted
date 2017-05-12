package SNMP::Class::Varbind::IpForwarding;

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
	SNMP::Class::Varbind::register_handler("label","ipForwarding",__PACKAGE__);
	DEBUG "Handler for ".__PACKAGE__." registered";
}

#sub initialize_callback_object {
#	my $self = shift(@_);
#	croak "self appears to be undefined" unless ref $self;
#	my $forwarding = $self->raw_value;
#	DEBUG "raw_value is $forwarding";
#	$self->{value} = SNMP::Class::Value::IpForwarding->new($self->raw_value);
#}

sub value {
	return SNMP::Class::Value::IpForwarding->new(shift(@_)->raw_value);
}


1;

package SNMP::Class::Value::IpForwarding;

use Carp qw(cluck carp croak confess);
use warnings;
use strict;
use Data::Dumper;
use Log::Log4perl qw(:easy);

use overload 
	'""' => \&str_forwarding,
	'bool' => \&bool_forwarding,
	'0+' => \&num_forwarding,
	'<=>' => \&equals,
	'cmp' => \&equals
;

sub new {
	defined ( my $class = shift(@_) ) or confess "Incorrect call to new";
	defined ( my $raw_value = shift(@_) ) or confess "missing argument to new";
	return bless { raw_value => $raw_value },$class;
}

sub is_forwarding {
	defined ( my $self = shift(@_) ) or confess "Incorrect call";
	if ($self->{raw_value} == 1) {
		return 1;
	}
	return;
}


sub str_forwarding {
	defined ( my $self = shift(@_) ) or confess "Incorrect call";
	return "forwarding" if ($self->{raw_value} == 1);
	return "not forwarding";
}


sub bool_forwarding {
	defined ( my $self = shift(@_) ) or confess "Incorrect call";
	return 1 if ($self->{raw_value} == 1);
	return;
}

sub num_forwarding {
	defined ( my $self = shift(@_) ) or confess "Incorrect call";
	return 1 if ($self->{raw_value} == 1);
	return 2;
}

sub equals {
	defined ( my $self = shift(@_) ) or confess "Incorrect call";
	defined ( my $item = shift(@_) ) or confess "Incorrect call";
	if (
		($item =~ /^forwarding$/i) 
		||
		($item == 1)
		||
		($item =~ /^true$/i)
		||
		($item =~ /^yes$/i)
	) {
		return 1;
	}
	return 0;
}
	

1;


