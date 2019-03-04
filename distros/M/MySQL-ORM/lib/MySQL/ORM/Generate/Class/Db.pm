package MySQL::ORM::Generate::Class::Db;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::Util::Lite;
use MySQL::ORM::Generate::Class::Table;
use MySQL::ORM::Generate::AttributeMaker;
use MySQL::ORM::Generate::MethodMaker;
use MySQL::ORM::Generate::Writer;

extends 'MySQL::ORM::Generate::Common';

##############################################################################
# required attributes
##############################################################################

has dir => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has tables => (
	is       => 'ro',
	isa      => 'ArrayRef',
	required => 1,
);

has schema => (
	is       => 'rw',
	isa      => 'MySQL::Util::Lite::Schema',
	required => 1,
);

##############################################################################
# optional attributes
##############################################################################

has namespace => (
	is      => 'ro',
	isa     => 'Str',
	default => '',
);

##############################################################################
# private attributes
##############################################################################

has _db_name => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_build_db_name',
);

##############################################################################
# methods
##############################################################################

method generate {

	$self->trace;
	
	my @attr;
	push @attr,
	  $self->attribute_maker->make_attribute(
		name        => 'db_name',
		is          => 'rw',
		isa         => 'Str',
		no_init_arg => 1,
		default     => sprintf( "'%s'", $self->_db_name ),
	  );

	foreach my $table ( @{ $self->tables } ) {

		my $t = MySQL::ORM::Generate::Class::Table->new(
			table         => $table,
			db_class_name => $self->get_class_name,
			schema        => $self->schema,
			dir           => $self->dir,
			namespace     => $self->namespace,
		);
		$t->generate;

		push @attr,
		  $self->attribute_maker->make_attribute(
			name        => $self->camelize($table->name),
			is          => 'rw',
			isa         => $t->get_class_name,
			no_init_arg => 1,
			lazy        => 1,
			builder     => '_build_table',
		  );
	}

	my @methods;
	push @methods,
	  $self->method_maker->make_method(
		name => '_build_table',
		body => $self->_get_build_table_body
	  );

	$self->writer->write_class(
		file_name  => $self->get_module_path,
		class_name => $self->get_class_name,
		use        => [
			'Modern::Perl',                   'Moose',
			'namespace::autoclean',           'Method::Signatures',
			"Data::Printer alias => 'pdump'", 'Module::Load'
		],
		extends => ['MySQL::ORM'],
		attribs => \@attr,
		methods => \@methods,
		overwrite => 1,
	);
	
	$self->trace('exit');
}

method get_class_name {

	my @ns;
	push @ns, $self->namespace if $self->namespace;
	push @ns, $self->camelize( $self->_db_name );

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

method _get_build_table_body {

	my $body = '
	    my $want_class = (caller(1))[3];
	    
	    if ($want_class =~ /__ANON__/) {
   			my @a = split(/\s+/, $want_class);
   			$want_class =  $a[1];	
    	}
    
    	load $want_class;
    	return $want_class->new(dbh => $self->dbh, schema_name => $self->db_name);
	';

	return $body;
}

method _build_db_name {

	return $self->schema->name;
}

1;
