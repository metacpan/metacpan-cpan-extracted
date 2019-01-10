package MySQL::Util::Lite::PrimaryKey;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::Util::Lite::Column;

with 'MySQL::Util::Lite::Roles::NewColumn';

has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has table_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has columns => (
	is      => 'rw',
	isa     => 'ArrayRef[MySQL::Util::Lite::Column]',
	lazy    => 1,
	builder => '_build_columns',
);

has _util => (
	is       => 'ro',
	isa      => 'MySQL::Util',
	required => 1,
);

method get_columns {
	
	return @{ $self->columns };	
}

=head2 is_autoinc

Checks if the primary key is a single column and it has autoinc.  

Returns: Bool
 
=cut

method is_autoinc {

	my @cols = $self->get_columns();
	if (@cols == 1) {
		my $col = shift @cols;
		if ($col->is_autoinc) {
			return 1;	
		}	
	}	
	
	return 0;
}

method _build_columns {

	my $aref = $self->_util->get_constraint( name => $self->name );
	
	my @cols;
	foreach my $col (@$aref) {
		my $href = $self->_util->describe_column(
			table  => $col->{TABLE_NAME},
			column => $col->{COLUMN_NAME}
		);
		my $new = $self->new_column($href);
		push @cols, $new;
	}

	return \@cols;
}

1;
