package MySQL::Util::Lite::ForeignKey;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::Util::Lite::ColumnConstraint;

has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has column_constraints => (
	is => 'rw',
	isa => 'ArrayRef[MySQL::Util::Lite::ColumnConstraint]',
	lazy => 1,
	builder => '_build_column_constraints',	
);

has _util => (
	is => 'ro',
	isa => 'MySQL::Util',
	required => 1,
);

method get_column_constraints {

	return @{ $self->column_constraints };	
}

method _build_column_constraints {

	my $aref = $self->_util->get_constraint(
		name  => $self->name
	);

	my @cols;

	foreach my $col (@$aref) {
		push @cols, MySQL::Util::Lite::ColumnConstraint->new(
			column_name => $col->{COLUMN_NAME},
			table_name  => $col->{TABLE_NAME},
			schema_name => $col->{CONSTRAINT_SCHEMA},
			parent_column_name => $col->{REFERENCED_COLUMN_NAME},
			parent_table_name  => $col->{REFERENCED_TABLE_NAME},
			parent_schema_name => $col->{REFERENCED_TABLE_SCHEMA},
		);

	}

	return \@cols;
}

1;
