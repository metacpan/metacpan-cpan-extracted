package MySQL::Util;
use Moose;
use namespace::autoclean;
use DBI;
use Carp;
use DBIx::DataFactory;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use MySQL::Util::Data::Cache;
use Smart::Args;

with 'MySQL::Util::Data::Create';

=head1 NAME

MySQL::Util - Utility functions for working with MySQL.

=head1 VERSION

Version 0.29

=cut

our $VERSION = '0.40';

=head1 SYNOPSIS

=for text
tmpdir/Testmysqlorm.pm
 my $util = MySQL::Util->new( dsn  => $ENV{DBI_DSN}, 
                              user => $ENV{DBI_USER} );

 my $util = MySQL::Util->new( dsn  => $ENV{DBI_DSN}, 
                              user => $ENV{DBI_USER},
                              span => 1); 

 my $util = MySQL::Util->new( dbh => $dbh );
                              
 my $aref = $util->describe_table('mytable');
 print "table: mytable\n";
 foreach my $href (@$aref) {
     print "\t", $href->{FIELD}, "\n";
 }

 my $href = $util->get_ak_constraints('mytable');
 my $href = $util->get_ak_indexes('mytable');
 my $href = $util->get_constraints('mytable');

 #
 # drop foreign keys example 1 
 # 
 
 my $fks_aref = $util->drop_fks();

 < do some work here - perhaps truncate tables >

 $util->apply_ddl($fks_aref);   # this will clear the cache for us.  see 
                                # clear_cache() for more info.

 # 
 #  drop foreign keys example 2 
 #
 
 my $fks_aref = $util->drop_fks();

 my $dbh = $util->clone_dbh;
 foreach my $stmt (@$fks_aref) {
     $dbh->do($stmt); 
 }

 $util->clear_cache;  # we modified the database ddl outside of the object so 
                      # we need to clear the object's internal cache.  see 
                      # clear_cache() for more info.

=cut 

#
# public variables
#

has 'dsn' => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has 'user' => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has 'pass' => (
	is       => 'ro',
	required => 0,
	default  => undef
);

has 'span' => (
	is       => 'ro',
	isa      => 'Int',
	required => 0,
	default  => 0
);

has 'dbh' => (
	is  => 'rw',
	isa => 'Object',
);

#
# private variables
#

has '_dbh' => (
	is       => 'ro',
	writer   => '_set_dbh',
	init_arg => undef,        # By setting the init_arg to undef, we make it
	     # impossible to set this attribute when creating a new object.
);

has '_index_cache' => (
	is       => 'rw',
	isa      => 'HashRef[MySQL::Util::Data::Cache]',
	init_arg => undef,
	default  => sub { {} }
);

has '_constraint_cache' => (
	is       => 'rw',
	isa      => 'HashRef[MySQL::Util::Data::Cache]',
	init_arg => undef,
	default  => sub { {} }
);

has '_depth_cache' => (
	is       => 'rw',
	isa      => 'HashRef',
	init_arg => undef,
	default  => sub { {} }
);

has '_describe_cache' => (
	is       => 'rw',
	isa      => 'HashRef',
	init_arg => undef,
	default  => sub { {} }
);

has '_schema' => (
	is       => 'rw',
	isa      => 'Str',
	required => 0,
	init_arg => undef,
);

has _verbose_funcs => (
	is       => 'rw',
	isa      => 'HashRef',
	required => 0,
	default  => sub { {} },
);

##############################################################################

sub BUILD {
	my $self = shift;

	if ( defined $ENV{VERBOSE_FUNCS} ) {
		my $vf = $self->_verbose_funcs;

		foreach my $func ( split /[,|:]/, $ENV{VERBOSE_FUNCS} ) {
			$vf->{$func} = 1;
		}

		$self->_verbose_funcs($vf);
	}

	my $dbh = $self->dbh;

	if ( !$dbh ) {

		$dbh = DBI->connect(
			$self->dsn,
			$self->user,
			$self->pass,
			{
				RaiseError       => 1,
				FetchHashKeyName => 'NAME_uc',
				AutoCommit       => 0,           # dbd::mysql workaround
				PrintError       => 0
			}
		);

		$dbh->{AutoCommit} = 1;                  # dbd::mysql workarounda
	}
	else {
		$dbh->{FetchHashKeyName} = 'NAME_uc';
	}
	
	my $schema = $dbh->selectrow_arrayref("select schema()")->[0];
	if ($schema) {
		$self->_schema($schema);
	}
	else {
		confess "unable to determine database name";		
	}
	
	$self->_set_dbh($dbh);
}

#################################################################
#################### PRIVATE METHODS ############################
#################################################################

#sub _get_ak_constraint_arrayref {
#	args
#		 my $self => 'Object',
#		 my $table => 'Str',
#		 my $name => 'Str';
#
#    my $href = $self->get_ak_constraints($table);
#
#	if (defined $href->{$name}) {
#		return $href->{$name};
#	}
#
#	confess "can't find ak constraint: $name";
#}

sub _get_fk_column {
	my $self = shift;
	my %a    = @_;

	my $table  = $a{table}  || confess "missing table arg";
	my $column = $a{column} || confess "missing column arg";

	my $fks_href = $self->get_fk_constraints($table);

	foreach my $fk_name ( keys %$fks_href ) {

		foreach my $fk_href ( @{ $fks_href->{$fk_name} } ) {

			if ( $fk_href->{COLUMN_NAME} eq $column ) {
				return $fk_href;
			}
		}
	}

	confess "couldn't find where $table.$column is part of an fk?";
}

sub _get_indexes_arrayref {
	my $self  = shift;
	my $table = shift;

	my $cache = '_index_cache';

	if ( defined( $self->$cache->{$table} ) ) {
		return $self->$cache->{$table}->data;
	}

	my $dbh = $self->_dbh;
	my $sth = $dbh->prepare("show indexes in $table");
	$sth->execute;

	my $aref = [];
	while ( my $href = $sth->fetchrow_hashref ) {
		push( @$aref, {%$href} );
	}

	$self->$cache->{$table} = MySQL::Util::Data::Cache->new( data => $aref );
	return $aref;
}

sub _fq {
	args

	  # required
	  my $self  => 'Object',
	  my $table => 'Str',

	  # optional
	  my $fq     => { isa => 'Int',       optional => 1, default => 1 },
	  my $schema => { isa => 'Str|Undef', optional => 1 };

	if ($fq) {
		if ( $table =~ /\w\.\w/ ) {
			return $table;
		}
		elsif ($schema) {
			return "$schema.$table";
		}

		return $self->_schema . ".$table";
	}

	if ( $table =~ /^(\w+)\.(\w+)$/ ) {
		my $curr = $self->_schema;

		confess "can't remove schema name from table name $table because we "
		  . "are not in the same db context (incoming fq table = $table, "
		  . "current schema = $curr"
		  if $curr ne $1;

		return $2;
	}

	return $table;
}

sub _un_fq {
	args_pos

	  # required
	  my $self  => 'Object',
	  my $table => 'Str';

	if ( $table =~ /^(\w+)\.(\w+)$/ ) {
		return ( $1, $2 );
	}

	return ( $self->_schema, $table );
}

sub _get_fk_ddl {
	my $self  = shift;
	my $table = shift;
	my $fk    = shift;

	my $sql = "show create table $table";
	my $sth = $self->_dbh->prepare($sql);
	$sth->execute;

	while ( my @a = $sth->fetchrow_array ) {

		foreach my $data (@a) {
			my @b = split( /\n/, $data );

			foreach my $item (@b) {
				if ( $item =~ /CONSTRAINT `$fk` FOREIGN KEY/ ) {
					$item =~ s/^\s*//;    # remove leading ws
					$item =~ s/\s*//;     # remove trailing ws
					$item =~ s/,$//;      # remove trailing comma

					return "alter table $table add $item";
				}
			}
		}
	}
}

sub _column_exists {
	my $self = shift;
	my %a    = @_;

	my $table  = $a{table}  or confess "missing table arg";
	my $column = $a{column} or confess "missing column arg";

	my $desc_aref = $self->describe_table($table);

	foreach my $col_href (@$desc_aref) {

		if ( $col_href->{FIELD} eq $column ) {
			return 1;
		}
	}

	return 0;
}

sub _verbose {
	args_pos

	  # required
	  my $self => 'Object',
	  my $msg  => 'Str',

	  # optional
	  my $func_counter => { isa => 'Str', default => 0, optional => 1 };

	my $caller_func = ( caller(1) )[3];
	my $caller_line = ( caller(0) )[2];

	my @caller_func = split( /\::/, $caller_func );
	my $key = pop @caller_func;

	if ( $self->_verbose_funcs->{$key} ) {
		print STDERR "[VERBOSE] $caller_func ($caller_line) ";
		print STDERR "[cnt=$func_counter]" if $func_counter;
		print STDERR "\n";

		chomp $msg;
		foreach my $nl ( split /\n/, $msg ) {
			print STDERR "\t$nl\n";
		}
	}
}

sub _verbose_sql {
	args_pos

	  # required
	  my $self => 'Object',
	  my $sql  => 'Str',

	  # optional
	  my $func_counter => { isa => 'Int', default => 0, optional => 1 };

	my $caller_func = ( caller(1) )[3];
	my $caller_line = ( caller(0) )[2];

	my @caller_func = split( /\::/, $caller_func );
	my $key = pop @caller_func;

	if ( $self->_verbose_funcs->{$key} ) {
		print STDERR "[VERBOSE] $caller_func ($caller_line) ";
		print STDERR "[cnt=$func_counter]" if $func_counter;
		print STDERR "\n";

		$sql = SQL::Beautify->new( query => $sql )->beautify;
		foreach my $l ( split /\n/, $sql ) {
			print STDERR "\t$l\n";
		}
	}
}

#################################################################
##################### PUBLIC METHODS ############################
#################################################################

=head1 METHODS

All methods croak in the event of failure unless otherwise noted.

=over 

=item new( dsn  => $dsn, 
           user => $user, 
          [pass => $pass], 
          [span => $span]);

constructor
 * dsn  - standard DBI stuff
 * user - db username
 * pass - db password
 * span - follow references that span databases (default 0)

=cut

=item apply_ddl( [ ... ]) 

Runs arbitrary ddl commands passed in via an array ref.

The advantage of this is it allows you to make ddl changes to the db without
having to worry about the object's internal cache (see clear_cache()).

=cut

sub apply_ddl {
	args_pos

	  # required
	  my $self       => 'Object',
	  my $stmts_aref => 'ArrayRef';

	foreach my $stmt (@$stmts_aref) {
		$self->_dbh->do($stmt);
	}

	$self->clear_cache;
}

=item describe_column(table => $table, column => $column)

Returns a hashref for the requested column.

Hash elements for each column:

    DEFAULT
    EXTRA
    FIELD
    KEY
    NULL
    TYPE
           
See MySQL documentation for more info on "describe <table>".
 
=cut

sub describe_column {
	args

	  # required
	  my $self   => 'Object',
	  my $table  => 'Str',
	  my $column => 'Str';

	if ( !$self->_column_exists( table => $table, column => $column ) ) {
		confess "column $column does not exist in table $table";
	}

	my $col_aref = $self->describe_table($table);

	foreach my $col_href (@$col_aref) {
		if ( $col_href->{FIELD} =~ /^$column$/i ) {
			return $col_href;
		}
	}
}

=item describe_table($table)

Returns an arrayref of column info for a given table. 

The structure of the returned data is:

$arrayref->[ { col1 }, { col2 } ]

Hash elements for each column:

    DEFAULT
    EXTRA
    FIELD
    KEY
    NULL
    TYPE
           
See MySQL documentation for more info on "describe <table>".
 
=cut

sub describe_table {
	my $self  = shift;
	my $table = shift;

	$table = $self->_fq( table => $table, fq => 1 );

	my $cache = '_describe_cache';

	if ( defined( $self->$cache->{$table} ) ) {
		return $self->$cache->{$table}->data;
	}

	my $sql = qq{
        describe $table
    };

	my $dbh = $self->_dbh;
	my $sth = $dbh->prepare($sql);
	$sth->execute;

	my @cols;
	while ( my $row = $sth->fetchrow_hashref ) {
		push( @cols, {%$row} );
	}

	$self->$cache->{$table} = MySQL::Util::Data::Cache->new( data => \@cols );
	return \@cols;
}

=item drop_fks([$table])

Drops foreign keys for a given table or the entire database if no table is 
provided.

Returns an array ref of alter table statements to rebuild the dropped foreign 
keys on success.  Returns an empty array ref if no foreign keys were found.

=cut

sub drop_fks {
	my $self  = shift;
	my $table = shift;

	my @tables;
	if ( !defined($table) ) {
		my $tables_aref = $self->get_tables;
		return [] if !defined($tables_aref);

		@tables = @$tables_aref;
	}
	else {
		push( @tables, $table );
	}

	my @ret;
	foreach my $table (@tables) {

		my $fqtn     = $self->_schema . ".$table";
		my $fks_href = $self->get_fk_constraints($table);

		foreach my $fk ( keys %$fks_href ) {

			push( @ret, $self->_get_fk_ddl( $table, $fk ) );

			my $sql = qq{
                alter table $table
                drop foreign key $fk
            };
			$self->_dbh->do($sql);

			$self->_constraint_cache->{$fqtn} = undef;
		}
	}

	return [@ret];
}

=item get_ak_constraints($table)

Returns a hashref of the alternate key constraints for a given table.  Returns
an empty hashref if none were found.  The primary key is excluded from the
returned data.  

The structure of the returned data is:

$hashref->{constraint_name}->[ { col1 }, { col2 } ]

See "get_constraints" for a list of the hash elements in each column.

=cut

sub get_ak_constraints {
	my $self = shift;
	my $table = shift or confess "missing table arg";

	$table = $self->_fq( table => $table, fq => 1 );

	my $cons = $self->get_constraints($table);

	my $ret;
	foreach my $con_name ( keys(%$cons) ) {
		if ( $cons->{$con_name}->[0]->{CONSTRAINT_TYPE} eq 'UNIQUE' ) {
			$ret->{$con_name} = $cons->{$con_name};
		}
	}

	return $ret;
}

=item get_ak_indexes($table)

Returns a hashref of the alternate key indexes for a given table.  Returns
an empty hashref if one was not found.

The structure of the returned data is:

$href->{index_name}->[ { col1 }, { col2 } ]

See get_indexes for a list of hash elements in each column.
    
=cut

sub get_ak_indexs {

	# for backwards compatibility
	my $self = shift;
	return $self->get_ak_indexes(@_);
}

sub get_ak_indexes {
	args_pos my $self => 'Object',
	  my $table       => 'Str';

	if ( $table !~ /\./ ) {
		$table = $self->_schema . ".$table";
	}

	my $href    = {};
	my $indexes = $self->get_indexes($table);

	foreach my $index ( keys(%$indexes) ) {
		if ( $indexes->{$index}->[0]->{NON_UNIQUE} == 0 ) {
			$href->{$index} = $indexes->{$index};
		}
	}

	return $href;
}

=item get_ak_names($table)

Returns an arrayref of alternate key constraints.  Returns undef if none
were found.

=cut

sub get_ak_names {
	my $self = shift;
	my $table = shift || confess "missing table arg";

	if ( $self->has_ak($table) ) {
		my $href = $self->get_ak_constraints($table);
		return ( keys %$href );
	}

	return;
}

=item get_constraint(table => $table, name => $constraint_name)

Returns an arrayref for the requested constraints on a given table.  Throws
an error if the constraint is not found.

The structure of the returned data is:

$arrayref->[ { col1 }, { col2 } ]

Hash elements for each column:

    see get_constraints()

=cut

sub get_constraint {
	args

	  # required
	  my $self => 'Object',
	  my $name => 'Str',

	  # optional
	  my $schema => { isa => 'Str', optional => 1 },
	  my $table  => { isa => 'Str', optional => 1 };

	my ( $unfq_schema, $unfq_table, $fq_table );

	if ( defined $table ) {
		( $unfq_schema, $unfq_table ) = $self->_un_fq($table);
		if ($schema) {
			if ( $unfq_schema ne $schema ) {
				confess "schema arg $schema does not match table $table";
			}
		}

		$fq_table = $self->_fq(
			table  => $unfq_table,
			fq     => 1,
			schema => $unfq_schema
		);
	}

	if ( defined $fq_table ) {
		my $cons_href = $self->get_constraints($fq_table);

		foreach my $cons_name ( keys %$cons_href ) {
			if ( $cons_name eq $name ) {
				return $cons_href->{$cons_name};
			}
		}

		confess "failed to find constraint $name for table $fq_table";
	}

	$schema = $self->_schema if !$schema;

	#
	# search cache for the constraint name across tables
	#
	my $cache = '_constraint_cache';

	foreach my $t ( keys %{ $self->$cache } ) {

		if ( defined( $self->$cache->{$t} ) ) {
			my $data_href = $self->$cache->{$t}->data;

			foreach my $cons_name ( keys %$data_href ) {
				if ( $cons_name eq $name ) {

					return $data_href->{$cons_name};
				}
			}
		}
	}

	my $sql = qq{
        select distinct tc.table_name
        from information_schema.table_constraints tc
        where  tc.constraint_schema = '$schema'
    };

	if ( !$self->span ) {
		$sql .= qq{
          and (referenced_table_schema = '$schema' or referenced_table_schema is null)
        };
	}

	my $dbh = $self->_dbh;
	my $sth = $dbh->prepare($sql);
	$sth->execute;

	while ( my ($t) = $sth->fetchrow_array ) {
		my $cons_href = $self->get_constraints( table => $t );

		foreach my $cons_name ( keys %$cons_href ) {
			if ( $cons_name eq $name ) {
				$sth->finish;
				return $cons_href->{$cons_name};
			}
		}
	}

	confess "failed to find constraint name $name";
}

=item get_constraints($table)

Returns a hashref of the constraints for a given table.  Returns
an empty hashref if none were found.

The structure of the returned data is:

$hashref->{constraint_name}->[ { col1 }, { col2 } ]

Hash elements for each column:

    CONSTRAINT_NAME
    TABLE_NAME
    CONSTRAINT_SCHEMA
    CONSTRAINT_TYPE
    COLUMN_NAME
    ORDINAL_POSITION
    POSITION_IN_UNIQUE_CONSTRAINT
    REFERENCED_COLUMN_NAME
    REFERENCED_TABLE_SCHEMA
    REFERENCED_TABLE_NAME
        
=cut

sub get_constraints {
	my $self = shift;
	my $table = shift || confess "missing table arg";

	$table = $self->_fq( table => $table, fq => 1 );

	my ( $schema, $table_no_schema ) = split( /\./, $table );

	my $cache = '_constraint_cache';

	if ( defined( $self->$cache->{$table} ) ) {
		return $self->$cache->{$table}->data;
	}

	confess "table '$table' does not exist: " if !$self->table_exists($table);

	my $sql = qq{
        select kcu.constraint_name, tc.constraint_type, column_name, 
          ordinal_position, position_in_unique_constraint, referenced_table_schema,
          referenced_table_name, referenced_column_name, tc.constraint_schema
        from information_schema.table_constraints tc, 
          information_schema.key_column_usage kcu 
        where tc.table_name = '$table_no_schema'
          and tc.table_name = kcu.table_name 
          and tc.constraint_name = kcu.constraint_name 
          and tc.constraint_schema = '$schema'
          and kcu.constraint_schema = tc.constraint_schema 
    };

	if ( !$self->span ) {
		$sql .= qq{
          and (referenced_table_schema = '$schema' or referenced_table_schema is null)
        };
	}

	$sql .= qq{ order by constraint_name, ordinal_position };

	my $dbh = $self->_dbh;
	my $sth = $dbh->prepare($sql);
	$sth->execute;

	my $href = {};
	while ( my $row = $sth->fetchrow_hashref ) {

		my $name = $row->{CONSTRAINT_NAME};
		if ( !defined( $href->{$name} ) ) { $href->{$name} = [] }

		$row->{TABLE_NAME} = $self->_fq( table => $table, fq => 0 );

		push( @{ $href->{$name} }, {%$row} );
	}

	$self->$cache->{$table} = MySQL::Util::Data::Cache->new( data => $href );
	return $href;
}

=item get_dbname()

Returns the name of the current schema/database.

=cut

sub get_dbname {
	my $self = shift;
	confess "get_dbname does not take any parameters" if @_;

	return $self->_schema;
}

=item get_depth($table)

Returns the table depth within the data model hierarchy.  The depth is 
zero based. 

For example:

=for text

 -----------       -----------
 | table A |------<| table B |
 -----------       -----------


Table A has a depth of 0 and table B has a depth of 1.  In other
words, table B is one level down in the model hierarchy.

If a table has multiple parents, the parent with the highest depth wins.

=cut

sub get_depth {
	my $self = shift;
	my $table = shift or confess "missing table arg";

	if ( $table !~ /\./ ) {
		$table = $self->_schema . ".$table";
	}

	my $cache = '_depth_cache';

	if ( defined( $self->{$cache}->{$table} ) ) {
		return $self->{$cache}->{$table};
	}

	my $dbh = $self->_dbh;

	my $fk_cons = $self->get_fk_constraints($table);

	my $depth = 0;

	foreach my $fk_name ( keys(%$fk_cons) ) {
		my $parent_table =
		    $fk_cons->{$fk_name}->[0]->{REFERENCED_TABLE_SCHEMA} . '.'
		  . $fk_cons->{$fk_name}->[0]->{REFERENCED_TABLE_NAME};

		if ( $parent_table eq $table ) { next }    # self referencing table

		my $parent_depth = $self->get_depth($parent_table);
		if ( $parent_depth >= $depth ) { $depth = $parent_depth + 1 }
	}

	$self->{$cache}->{$table} = $depth;

	return $depth;
}

=item get_fk_column_names(table => $table, [name => $constraint_name])

If name is specified, returns an array of columns that participate in the
foreign key constraint.  If name is not specified, returns an array of columns
that participate an any foreign key constraint on the table.

=cut

sub get_fk_column_names {
	args

	  # required
	  my $self  => 'Object',
	  my $table => 'Str',

	  # optional
	  my $name => { isa => 'Str', optional => 1 };

	$table = $self->_fq( table => $table, fq => 1 );

	my @columns;

	my $fks_href = $self->get_fk_constraints($table);

	foreach my $fk_name ( keys %$fks_href ) {

		next if ( $name and $name ne $fk_name );

		foreach my $fk_href ( @{ $fks_href->{$fk_name} } ) {

			my $col = $fk_href->{COLUMN_NAME};
			push( @columns, $col );
		}
	}

	return @columns;
}

=item get_fk_constraints([$table])

Returns the foreign keys for a table or the entire database.

Returns a hashref of the foreign key constraints on success.  Returns
an empty hashref if none were found.

The structure of the returned data is:

$hashref->{constraint_name}->[ { col1 }, { col2 } ]

See "get_constraints" for a list of the hash elements in each column.

=cut

sub get_fk_constraints {
	args_pos

	  # required
	  my $self => 'Object',

	  # optional
	  my $table => { isa => 'Str', optional => 1 };

	if ( defined($table) and $table !~ /\./ ) {
		$table = $self->_schema . ".$table";
	}

	my @tables;
	if ( !defined($table) ) {
		my $tables_aref = $self->get_tables;
		return {} if !defined($tables_aref);

		@tables = @$tables_aref;
	}
	else {
		push( @tables, $table );
	}

	my $href = {};

	foreach my $table (@tables) {

		my $cons_href = $self->get_constraints($table);
		foreach my $cons_name ( keys(%$cons_href) ) {

			my $cons_aref = $cons_href->{$cons_name};
			foreach my $col_href (@$cons_aref) {

				my $type = $col_href->{CONSTRAINT_TYPE};

				if ( $type eq 'FOREIGN KEY' ) {
					$href->{$cons_name} = [@$cons_aref];
				}
			}
		}
	}

	return $href;
}

=item get_fk_indexes($table)

Returns a hashref of the foreign key indexes for a given table.  Returns
an empty hashref if none were found.  In order to qualify as a fk index, 
it must have a corresponding fk constraint.  

The structure of the returned data is:

$hashref->{index_name}->[ { col1 }, { col2 } ]

See "get_indexes" for a list of the hash elements in each column.

=cut

sub get_fk_indexes {
	args_pos my $self => 'Object',
	  my $table       => 'Str';

	if ( $table !~ /\./ ) {
		$table = $self->_schema . ".$table";
	}

	my $href    = {};
	my $cons    = $self->get_fk_constraints($table);
	my $indexes = $self->get_indexes($table);

	foreach my $con_name ( keys(%$cons) ) {
		my @con_cols = @{ $cons->{$con_name} };

		foreach my $index_name ( keys(%$indexes) ) {
			my @index_cols = @{ $indexes->{$index_name} };

			if ( scalar(@con_cols) == scalar(@index_cols) ) {

				my $match = 1;
				for ( my $i = 0 ; $i < scalar(@con_cols) ; $i++ ) {
					if ( $index_cols[$i]->{COLUMN_NAME} ne
						$con_cols[$i]->{COLUMN_NAME} )
					{
						$match = 0;
						last;
					}
				}

				if ($match) {
					$href->{$index_name} = $indexes->{$index_name};
					last;
				}
			}
		}
	}

	return $href;
}

=item get_indexes($table)

Returns a hashref of the indexes for a given table.  Returns
an empty hashref if none were found.

The structure of the returned data is:

$href->{index_name}->[ { col1 }, { col2 } ]

Hash elements for each column:

    CARDINALITY
    COLLATION
    COLUMN_NAME
    COMMENT
    INDEX_TYPE
    KEY_NAME
    NON_UNIQUE
    NULL
    PACKED
    SEQ_IN_INDEX
    SUB_PART
    TABLE
    
=cut

sub get_indexes {
	my $self = shift;
	my $table = shift or confess "missing table arg";

	if ( $table !~ /\./ ) {
		$table = $self->_schema . ".$table";
	}

	my %h       = ();
	my $indexes = $self->_get_indexes_arrayref($table);

	foreach my $index (@$indexes) {
		my $key_name = $index->{KEY_NAME};
		my $seq      = $index->{SEQ_IN_INDEX};

		if ( !exists( $h{$key_name} ) ) { $h{$key_name} = [] }

		$h{$key_name}->[ $seq - 1 ] = $index;
	}

	return \%h;
}

=item get_max_depth()

Returns the max table depth for all tables in the database.

See "get_depth" for additional info.

=cut

sub get_max_depth {
	my $self = shift;

	my $dbh = $self->_dbh;

	my $tables = $self->get_tables();

	my $max = 0;
	foreach my $table (@$tables) {
		my $depth = $self->get_depth($table);
		if ( $depth > $max ) { $max = $depth }
	}

	return $max;
}

=item get_other_constraints($table)

Returns a hashref of the constraints that are not pk, ak, or fk  
for a given table.  Returns an empty hashref if none were found.

The structure of the returned data is:

$hashref->{constraint_name}->[ { col1 }, { col2 } ]

See "get_constraints" for a list of the hash elements in each column.

=cut

sub get_other_constraints {
	args_pos my $self => 'Object',
	  my $table       => 'Str';

	if ( $table !~ /\./ ) {
		$table = $self->_schema . ".$table";
	}

	my $fk = $self->get_fk_constraints($table);
	my $ak = $self->get_ak_constraints($table);

	my $href = {};
	my $cons = $self->get_constraints($table);

	foreach my $con_name ( keys(%$cons) ) {
		my $type = $cons->{$con_name}->[0]->{CONSTRAINT_TYPE};

		next if $type eq 'PRIMARY KEY';
		next if $type eq 'FOREIGN KEY';
		next if $type eq 'UNIQUE';

		$href->{$con_name} = $cons->{$con_name};
	}

	return $href;
}

=item get_other_indexes($table)

Returns a hashref of the indexes that are not pk, ak, or fk  
for a given table.  Returns an empty hashref if none were found.

The structure of the returned data is:

$hashref->{index_name}->[ { col1 }, { col2 } ]

See "get_indexes" for a list of the hash elements in each column.

=cut

sub get_other_indexes {
	args_pos

	  # required
	  my $self  => 'Object',
	  my $table => 'Str';

	if ( $table !~ /\./ ) {
		$table = $self->_schema . ".$table";
	}

	my $ak = $self->get_ak_indexes($table);
	my $fk = $self->get_fk_indexes($table);

	my $href    = {};
	my $indexes = $self->get_indexes($table);

	foreach my $name ( keys %$indexes ) {
		next if $name eq 'PRIMARY';
		next if defined( $ak->{$name} );
		next if defined( $fk->{$name} );

		$href->{$name} = $indexes->{$name};
	}

	return $href;
}

=item get_pk_constraint($table)

Returns an arrayref of the primary key constraint for a given table.  Returns
an empty arrayref if none were found.

The structure of the returned data is:

$aref->[ { col1 }, { col2 }, ... ]

See "get_constraints" for a list of hash elements in each column.

=cut

sub get_pk_constraint {
	my $self  = shift;
	my $table = shift;

	if ( $table !~ /\./ ) {
		$table = $self->_schema . ".$table";
	}

	my $cons = $self->get_constraints($table);

	foreach my $con_name ( keys(%$cons) ) {
		if ( $cons->{$con_name}->[0]->{CONSTRAINT_TYPE} eq 'PRIMARY KEY' ) {
			return $cons->{$con_name};
		}
	}

	return [];
}

=item get_pk_index($table)

Returns an arrayref of the primary key index for a given table. Returns
an empty arrayref if none were found.

The structure of the returned data is:

$aref->[ { col1 }, { col2 }, ... ]

See "get_indexes" for a list of the hash elements in each column.

=cut

sub get_pk_index {
	my $self  = shift;
	my $table = shift;

	#	if ($table !~ /\./) {
	#		$table = $self->_schema . ".$table";
	#	}

	my $href = $self->get_indexes($table);

	foreach my $name ( keys(%$href) ) {
		if ( $name eq 'PRIMARY' )    # mysql forces this naming convention
		{
			return $href->{$name};
		}
	}

	return [];
}

=item get_pk_name($table)

Returns the primary key constraint name for a given table.  Returns undef
if one does not exist.

=cut

sub get_pk_name {
	my $self = shift;
	my $table = shift || confess "missing table arg";

	if ( $self->has_pk($table) ) {
		return 'PRIMARY';    # mysql default
	}

	return;
}

=item get_tables( )

Returns an arrayref of tables in the current database.  Returns undef
if no tables were found.

=cut

sub get_tables {
	my $self = shift;

	my $dbh = $self->_dbh;

	my $tables = undef;
	my $sth = $dbh->prepare("show full tables where Table_Type = 'BASE TABLE'");
	$sth->execute;

	while ( my ($table) = $sth->fetchrow_array ) {
		push( @$tables, $table );
	}

	return $tables;
}

=item has_ak($table)

Returns true if the table has an alternate key or false if not.

=cut

sub has_ak {
	my $self = shift;
	my $table = shift || confess "missing table arg";

	my $aks_href = $self->get_ak_constraints($table);

	return scalar keys %$aks_href;
}

=item has_fks($table)
    
Returns true if the table has foreign keys or false if not. 
    
=cut

sub has_fks {
	my $self = shift;
	my $table = shift || confess "missing table arg";

	my $fks_href = $self->get_fk_constraints($table);

	return scalar keys %$fks_href;
}

=item has_pk($table)

Returns true if the table has a primary key or false if it does not.

=cut

sub has_pk {
	my $self = shift;
	my $table = shift || confess "missing table arg";

	my $pk_aref = $self->get_pk_constraint($table);

	return scalar @$pk_aref;
}

=item is_pk_auto_inc($table)

Returns true if the primary key is using the auto-increment feature or false
if it does not.

=cut

sub is_pk_auto_inc {
	my $self = shift;
	my $table = shift || confess "missing table arg";

	if ( $self->has_pk($table) ) {
		my $pk_aref = $self->get_pk_constraint($table);

		foreach my $col_href (@$pk_aref) {

			my $col_name      = $col_href->{COLUMN_NAME};
			my $col_desc_href = $self->describe_column(
				table  => $table,
				column => $col_name
			);

			if ( $col_desc_href->{EXTRA} =~ /auto/ ) {
				return 1;
			}
		}
	}

	return 0;
}

=item is_column_nullable(table => $table, column => $column)

Returns true if column is nullable or false if it is not.

=cut

sub is_column_nullable {
	args

	  # required
	  my $self   => 'Object',
	  my $table  => 'Str',
	  my $column => 'Str';

	my $desc = $self->describe_column( table => $table, column => $column );

	if ( $desc->{NULL} eq 'YES' ) {
		return 1;
	}

	return 0;
}

=item is_fk_column(table => $table, column => $column)

Returns true if column participates in a foreign key or false if it does not.

=cut

sub is_fk_column {
	my $self = shift;
	my %a    = @_;

	my $table  = $a{table}  || confess "missing table arg";
	my $column = $a{column} || confess "missing column arg";

	my $fks_href = $self->get_fk_constraints($table);

	foreach my $fk_name ( keys %$fks_href ) {

		foreach my $fk_href ( @{ $fks_href->{$fk_name} } ) {

			if ( $fk_href->{COLUMN_NAME} eq $column ) {
				return 1;
			}
		}
	}

	return 0;
}

=item is_self_referencing($table, [$name => $constraint_name])

Returns true if the specified table has a self-referencing foreign key or
false if it does not.  If a constraint name is passed, it will only check
the constraint provided.

=cut

sub is_self_referencing {
	args

	  # required
	  my $self  => 'Object',
	  my $table => 'Str',

	  # optional
	  my $name => { isa => 'Str', optional => 1 };

	my $fq_table = $self->_fq( table => $table, fq => 1 );

	my $fks_href = $self->get_fk_constraints($table);

	foreach my $con_name (%$fks_href) {
		next if $name and $name ne $con_name;

		#$hashref->{constraint_name}->[ { col1 }, { col2 } ]
		#
		#Hash elements for each column:
		#
		#    CONSTRAINT_SCHEMA
		#    CONSTRAINT_TYPE
		#    COLUMN_NAME
		#    ORDINAL_POSITION
		#    POSITION_IN_UNIQUE_CONSTRAINT
		#    REFERENCED_COLUMN_NAME
		#    REFERENCED_TABLE_SCHEMA
		#    REFERENCED_TABLE_NAME

		foreach my $pos_href ( @{ $fks_href->{$con_name} } ) {

			my $ref_table  = $pos_href->{REFERENCED_TABLE_NAME};
			my $ref_schema = $pos_href->{REFERENCED_TABLE_SCHEMA};

			my $ref_fq_table = $self->_fq(
				table  => $ref_table,
				fq     => 1,
				schema => $ref_schema
			);

			if ( $ref_fq_table eq $fq_table ) {
				return 1;
			}
		}
	}

	return 0;
}

=item table_exists($table)

Returns true if table exists.  Otherwise returns false.

=cut

sub table_exists {
	my $self = shift;
	my $table = shift or confess "missing table arg";

	my $fq_table = $table;
	if ( $table !~ /\./ ) {
		$fq_table = $self->_schema . ".$table";
	}

	my $dbh = $self->_dbh;

	my ( $schema, $nofq_table ) = split( /\./, $fq_table );
	if ( $schema ne $self->_schema ) {

		# quietly change the schema so "show tables like ..." works
		$dbh->do("use $schema");
	}

	my $sql = qq{show tables like '$nofq_table'};
	my $sth = $dbh->prepare($sql);
	$sth->execute;

	my $cnt = 0;
	while ( $sth->fetchrow_array ) {
		$cnt++;
	}

	if ( $schema ne $self->_schema ) {

		# quietly change schema back
		$dbh->do( "use " . $self->_schema );
	}

	return $cnt;
}

=item use_db($dbname)

Used for switching database context.  Returns true on success.

=cut

sub use_db {
	my $self   = shift;
	my $dbname = shift;

	$self->_dbh->do("use $dbname");
	$self->_schema($dbname);
	$self->clear_cache;

	return 1;
}

=back

=head1 ADDITIONAL METHODS

=over 

=item clear_cache()

Clears the object's internal cache.

If you modify the database ddl without going through the object, then you need 
to clear the internal cache so any future object calls don't return stale 
information.

=cut

sub clear_cache {
	my $self = shift;

	$self->_index_cache(      {} );
	$self->_constraint_cache( {} );
	$self->_depth_cache(      {} );
	$self->_describe_cache(   {} );
}

=item clone_dbh()

Returns a cloned copy of the internal database handle per the DBI::clone 
method.  Beware that the database context will be the same as the object's. 
For example, if you called "use_db" and switched context along the way, the 
returned dbh will also be in that same context.

=cut

sub clone_dbh {
	my $self = shift;

	my $dbh =
	  $self->_dbh->clone( { AutoCommit => 0 } );    # workaround dbd:mysql bug
	$dbh->{AutoCommit} = 1;                         # workaround dbd:mysql bug
	$dbh->do( "use " . $self->_schema );

	return $dbh;
}

=back

=head1 SEE ALSO

MySQL::Util::Data::Create

=head1 AUTHOR

John Gravatt, C<< <gravattj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mysql-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MySQL-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MySQL::Util


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MySQL-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MySQL-Util>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MySQL-Util>

=item * Search CPAN

L<http://search.cpan.org/dist/MySQL-Util/>

=back

=cut

#=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011 John Gravatt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable;    # moose stuff

1;
