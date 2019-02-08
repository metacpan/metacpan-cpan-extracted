package MySQL::ORM::Generate::Class::CustomRole;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';

extends 'MySQL::ORM::Generate::Common';

##############################################################################
# required attributes
##############################################################################

has dir => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has table_class_name => (
	is       => 'ro',
	isa      => 'Str',
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
	
	#
	# do not overwrite existing CustomRole.pm!
	#

	if ( !-f $self->get_module_path ) {

		$self->writer->write_class(
			file_name  => $self->get_module_path,
			class_name => $self->get_role_name,
			use        => [
				'Modern::Perl', 'Moose::Role',
				'Method::Signatures',
				"Data::Printer alias => 'pdump'"
			],
		);
	}
	else {
		say "skipping "
		  . $self->get_module_path
		  . " (already exists)";
	}
	
	$self->trace('exit');
}

method get_role_name {

	my @ns;
	push @ns, $self->table_class_name;
	push @ns, 'CustomRole';
	return join( '::', @ns );
}

method get_module_path {

	my @tmp;
	push @tmp, $self->dir if $self->dir;

	my $role_name = $self->get_role_name;
	push @tmp, split( /::/, $role_name );

	return sprintf( '%s.pm', File::Spec->catdir(@tmp) );
}

##############################################################################
# private methods
##############################################################################

1;
