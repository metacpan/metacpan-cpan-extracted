package MySQL::Util::Lite;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::Util::Lite::Schema;

extends 'MySQL::Util';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has 'dsn' => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has 'user' => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has 'pass' => (
	is       => 'ro',
	required => 0,
	default  => undef
);

has 'span' => (
	is       => 'ro',
	isa      => 'Int',
	required => 0,
	default  => 0
);

has 'dbh' => (
	is  => 'rw',
	isa => 'Object',
);

################################
###### PRIVATE_ATTRIBUTES ######
################################

has _util => (
	is      => 'ro',
	isa     => 'MySQL::Util',
	lazy    => 1,
	builder => '_build_util',
);

############################
###### PUBLIC METHODS ######
############################

method get_schema {

	return my $schema = MySQL::Util::Lite::Schema->new(
		name  => $self->_util->get_dbname,
		_util => $self->_util
	);
}

#############################
###### PRIVATE METHODS ######
#############################

method _build_util {

	my %new;
	$new{dsn}  = $self->dsn  if defined $self->dsn;
	$new{user} = $self->user if defined $self->user;
	$new{pass} = $self->pass if defined $self->pass;
	$new{span} = $self->span if defined $self->span;
	$new{dbh}  = $self->dbh  if defined $self->dbh;

	return MySQL::Util->new(%new);
}

1;
