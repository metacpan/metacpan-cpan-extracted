package Statistics::Covid::Datum::IO;

use 5.006;
use strict;
use warnings;

# this class has all the functionality, like inserting to db etc.
# however, it expects that the 'dual' object which holds the data
# to insert into db (and also instantiate when selecting a db row)
# must adhere to some blueprint and have certain subs implemented,
# for example primary_key() or newer_than()

use parent 'Statistics::Covid::IO::Base';

use DateTime;

use Statistics::Covid::Utils;
use Statistics::Covid::Datum;
# this file contains the table schema
use Statistics::Covid::Datum::Table;
use Statistics::Covid::Schema;

our $VERSION = '0.23';

# new method inherited but here we will create one
# to be used as a factory
sub new {
	my ($class, $params) = @_;
	$params = {} unless defined $params;
	# anything to add to the params? do it here
	# $params->{'newthing'} = 123

	# now call our parent's constructor
	my $self = $class->SUPER::new(
		'Statistics::Covid::Schema',
		'Statistics::Covid::Datum',
		$params
	);
	if( ! defined $self ){ warn "error, call to ".$class."->SUPER::new() (parent was Statistics::Covid::IO::Base last time I checked) has failed."; return undef }
	# this will now be Datum/IO obj (not generic)
	return $self
}

1;
