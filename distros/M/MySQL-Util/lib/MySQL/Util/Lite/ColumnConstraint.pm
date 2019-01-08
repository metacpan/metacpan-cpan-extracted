package MySQL::Util::Lite::ColumnConstraint;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';

has column_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has table_name => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has schema_name => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has parent_column_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has parent_table_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,

);

has parent_schema_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

1;
