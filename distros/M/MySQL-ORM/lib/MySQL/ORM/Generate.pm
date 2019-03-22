package MySQL::ORM::Generate;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use MySQL::Util::Lite;
use MySQL::ORM::Generate::Class::Db;

extends 'MySQL::ORM::Generate::Common';

##############################################################################
## required attributes
##############################################################################

has dbh => (
	is       => 'rw',
	isa      => 'Object',
	required => 1,
);

##############################################################################
## optional attributes
##############################################################################

has dir => (
	is      => 'ro',
	isa     => 'Str',
	default => '.',
);

has namespace => (
	is  => 'ro',
	isa => 'Str',
);

has ignore_tables => (
	is      => 'ro',
	isa     => 'ArrayRef',
	default => sub { [] },
);

has only_tables => (
	is      => 'ro',
	isa     => 'ArrayRef',
	default => sub { [] },
);

##############################################################################
## private attributes
##############################################################################

has _lite => (
	is      => 'rw',
	isa     => 'MySQL::Util::Lite',
	lazy    => 1,
	builder => '_build_lite'
);

##############################################################################
## methods
##############################################################################

method generate {

	$self->trace;

	my $schema = $self->_lite->get_schema;
	my @tables = $schema->get_tables;
	@tables = $self->_prune_tables( \@tables );

	my %new;
	$new{tables}    = \@tables;
	$new{namespace} = $self->namespace if $self->namespace;
	$new{dir}       = $self->dir;
	$new{dbname}    = $schema->name;
	$new{schema}    = $schema;

	my $db = MySQL::ORM::Generate::Class::Db->new(%new);
	$db->generate;

	$self->trace('exit');
}

##############################################################################
# private methods
##############################################################################

method _get_ignore_tables_hash {

	my %ignore;

	foreach my $t ( @{ $self->ignore_tables } ) {
		$ignore{$t} = 1;
	}

	return %ignore;
}

method _get_only_tables_hash {

	my %only;

	foreach my $t ( @{ $self->only_tables } ) {
		$only{$t} = 1;
	}

	return %only;
}

method _prune_tables (ArrayRef $tables) {

	my @pruned;

	if ( @{ $self->only_tables } > 0 ) {
		my %prune = $self->_get_only_tables_hash;
		foreach my $t (@$tables) {
			if ( $prune{ $t->name } ) {
				push @pruned, $t;
			}
		}
	}
	else {
		my %prune = $self->_get_ignore_tables_hash;
		foreach my $t (@$tables) {
			if ( !$prune{ $t->name } ) {
				push @pruned, $t;
			}
		}
	}

	return @pruned;
}

method _build_lite {

	return MySQL::Util::Lite->new( dbh => $self->dbh, span => 1 );
}

1;
