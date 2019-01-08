package MySQL::Util::Lite::Table;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::Util::Lite::ForeignKey;
use MySQL::Util::Lite::PrimaryKey;
use MySQL::Util::Lite::AlternateKey;

with 'MySQL::Util::Lite::Roles::NewColumn';

has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has columns => (
	is => 'rw',
	isa => 'ArrayRef[MySQL::Util::Lite::Column]',
	lazy => 1,
	builder => '_build_columns',
);

has _util => (
	is       => 'ro',
	isa      => 'MySQL::Util',
	required => 1,
);

method get_parent_tables {

	my %seen;
	my @ret;
	my @fks = $self->get_foreign_keys;

	foreach my $fk (@fks) {
		foreach my $col ( @{ $fk->column_constraints } ) {
			
			my $fq_table_name = sprintf( "%s.%s",
				$col->parent_schema_name, $col->parent_table_name );

			if ( !$seen{$fq_table_name} ) {
				push @ret,
				  MySQL::Util::Lite::Table->new(
					name        => $col->parent_table_name,
					schema_name => $col->parent_schema_name,
					_util       => $self->_util
				  );
			}

			$seen{$fq_table_name}++;
		}
	}

	return @ret;
}

method get_foreign_keys {

	my $fks_href = $self->_util->get_fk_constraints( $self->name );
	my @fks;

	foreach my $fk_name ( keys %$fks_href ) {
		push @fks,
		  MySQL::Util::Lite::ForeignKey->new(
			name        => $fk_name,
			_util => $self->_util,
		  );
	}

	return @fks;
}

method has_parents {

	my @parents = $self->get_parent_tables;
	if (@parents) {
		return 1;
	}

	return 0;
}

method get_column (Str :$name) {

	my $cols = $self->columns;
	foreach my $col (@$cols) {
		if ( $col->name eq $name ) {
			return $col;
		}
	}
}

method get_primary_key () {

	my $pk_name = $self->_util->get_pk_name($self->name);
	if ($pk_name) {
		return MySQL::Util::Lite::PrimaryKey->new(
			name => $pk_name,
			_util => $self->_util,
			);			
	}	

	return;	
}

method get_alternate_keys() {

	my $href = $self->_util->get_ak_constraints($self->name);
	my @aks;

	foreach my $ak_name ( keys %$href ) {
		push @aks,
		  MySQL::Util::Lite::AlternateKey->new(
			name        => $ak_name,
			_util => $self->_util,
		  );
	}

	return @aks;
}

method get_columns {
	return @{ $self->columns };
}

method _build_columns{

	my @cols;
	my $aref = $self->_util->describe_table( $self->name );
	foreach my $col (@$aref) {

		push @cols, $self->new_column($col);
	}

	return \@cols;
}

1;
