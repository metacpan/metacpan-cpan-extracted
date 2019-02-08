package MySQL::ORM::Generate::Class::ResultClassX;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::ORM::Generate::Class::ResultClass;

extends 'MySQL::ORM::Generate::Common';

##############################################################################
# required attributes
##############################################################################

has dir => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has table => (
	is       => 'ro',
	isa      => 'MySQL::Util::Lite::Table',
	required => 1,
);

has table_class_name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has extends => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

##############################################################################
# optional attributes
##############################################################################

##############################################################################
# private attributes
##############################################################################

##############################################################################
# methods
##############################################################################

method generate {

	$self->trace;

	my @attr;
	my %seen;
	my @columns = $self->table->get_columns;

	foreach my $col (@columns) {
		$seen{ $col->name }++;
	}

	foreach my $table ( $self->table->get_parent_tables ) {

		foreach my $col ( $table->get_columns ) {

			next if $seen{ $col->name };

			push @attr,
			  $self->attribute_maker->make_attribute(
				name     => $col->name,
				comments => $self->get_column_attribute_comments($col),
				is       => 'rw',
				isa      => $col->get_moose_type,
				trigger  => $self->get_column_trigger($col),
			  );

			$seen{ $col->name } = 1;
		}
	}

	$self->writer->write_class(
		file_name  => $self->get_module_path,
		class_name => $self->get_class_name,
		use        => [
			'Modern::Perl',         'Moose',
			'namespace::autoclean', 'Method::Signatures',
			"Data::Printer alias => 'pdump'"
		],
		extends => [$self->extends],
		attribs => \@attr,
	);
	
	$self->trace('exit');
}

method get_class_name {

	my @ns;
	push @ns, $self->table_class_name;
	push @ns, 'ResultClassX';
	return join( '::', @ns );
}

method get_module_path {

	my @tmp;
	push @tmp, $self->dir if $self->dir;

	my $class_name = $self->get_class_name;
	push @tmp, split( /::/, $class_name );

	return sprintf( '%s.pm', File::Spec->catdir(@tmp) );
}

##############################################################################
# private methods
##############################################################################

1;
