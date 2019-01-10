package MySQL::Util::Lite::Schema;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::Util::Lite::Table;

has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has tables => (
	is => 'rw',
	isa => 'ArrayRef[MySQL::Util::Lite::Table]',
	lazy => 1,
	builder => '_build_tables',
);

has _util => (
	is       => 'ro',
	isa      => 'MySQL::Util',
	required => 1,
);

method get_table (Str $name) {

	my @tables = $self->get_tables;
	foreach my $t (@tables) {
		if ( $t->name eq $name ) {
			return $t;
		}
	}
}

method get_tables {
	
	return @{ $self->tables };	
}

method _build_tables {

	my $aref = $self->_util->get_tables;

	my @ret;
	foreach my $table (@$aref) {
		push @ret,
		  MySQL::Util::Lite::Table->new(
			name        => $table,
			schema_name => $self->name,
			_util       => $self->_util
		  );
	}

	return \@ret;
}

1;
