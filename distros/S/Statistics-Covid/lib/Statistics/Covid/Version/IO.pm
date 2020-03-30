package Statistics::Covid::Version::IO;

use 5.006;
use strict;
use warnings;

# this class has all the functionality, like inserting to db etc.
# however, it expects that the 'dual' object which holds the data
# to insert into db (and also instantiate when selecting a db row)
# must adhere to some blueprint and have certain subs implemented,
# for example primary_key() or newer_than()
use parent 'Statistics::Covid::IO::Base';

use Statistics::Covid::Utils;
use Statistics::Covid::Version;
# this file contains the table schema
use Statistics::Covid::Version::Table;
use Statistics::Covid::Schema;

our $VERSION = '0.23';

# new method inherited but here we will create one
# to be used as a factory
sub new {
	my ($class, $params) = @_;
	$params = {} unless defined $params;
	# anything to add to the params? do it here
	# $params->{'newthing'} = xxx

	# now call our parent's constructor
	my $self = $class->SUPER::new(
		'Statistics::Covid::Schema',
		'Statistics::Covid::Version',
		$params
	);
	if( ! defined $self ){ warn "error, call to $class->new() has failed."; return undef }
	# this will now be Version/IO obj (not generic)
	return $self
}
1;
