package MySQL::Util::Lite::AlternateKey;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';

with 'MySQL::Util::Lite::Roles::NewColumn';

has name => (
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

method _build_columns {

	my $aref = $self->_util->get_constraint( name => $self->name );

	my @cols;
	foreach my $col (@$aref) {
		my $href = $self->_util->describe_column(
			table  => $col->{TABLE_NAME},
			column => $col->{COLUMN_NAME}
		);
		push @cols, $self->new_column($href);
	}

	return \@cols;
}

1;
