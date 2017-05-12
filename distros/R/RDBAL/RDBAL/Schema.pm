#
# This is a perl module to work with an SQL database
#
# new($DBconnection,$database)
#	create a new schema object
#
# Brian Dunford-Shore 1/6/98
#
package RDBAL::Schema;

require 5.000;

$VERSION = "1.2";
sub Version { $VERSION; }

use RDBAL::Config;
use strict;
use vars qw(@ISA @EXPORT $VERSION $DefaultClass $AutoloadClass);
use Exporter;
@ISA = qw();

@EXPORT = ( );

sub import {
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export 'RDBAL::Schema', $callpkg, @_;
}

# Default class for the SQL object to use when all else fails.
$DefaultClass = 'RDBAL::Schema' unless defined $RDBAL::Schema::DefaultClass;
# This is where to look for autoloaded routines.
$AutoloadClass = $DefaultClass unless defined $RDBAL::Schema::AutoloadClass;


#
# Method: new
# Get database information
#

sub new {
    my($class,$connection,$database,%options) = @_;
    my $self = {};
    my($cache_output);

    if (!defined($connection) || !defined($database)) {
	return undef;
    }
    $connection->UseDatabase($database);
#    ( $connection->UseDatabase($database) )
#        or (print "Unable to USE database $database\n" and 
#        die "Failed to use $database database");

    bless $self,ref $class || $class || $DefaultClass;
    $self->{'connection'} = $connection;
    $self->{'server'} = $options{'-server'};
    $self->{'user'} = $options{'-username'};
    $self->{'database'} = $database;
    $self->{'get_system'} = $options{'-get_system'};
    $self->{'server_type'} = $options{'-server_type'};

    if ($options{'-nocache'}) {
	$cache_output = $self->get_schema();
	$self->write_schema_cache($cache_output,1);
    } else {
	if (!$self->read_schema_cache()) {
	    $cache_output = $self->get_schema();
	    $self->write_schema_cache($cache_output);
	}
    }
    return $self;
}

sub get_schema {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($database) = $self->{'database'};
    my($cache_output);

    $connection->UseDatabase($database);
#    ( $connection->UseDatabase($database) )
#        or (print "Unable to USE database $database\n" and 
#        die "Failed to use $database database");

    $cache_output .= $self->get_schema_objects();

    $cache_output .= $self->get_pkeys('User Table',$self->User_Tables());
    $cache_output .= $self->get_fkeys('User Table',$self->User_Tables());
    $cache_output .= $self->get_index('User Table',$self->User_Tables());
    $cache_output .= $self->get_comments('User Table',$self->User_Tables());

    $cache_output .=
	$self->get_pkeys('System Table',$self->System_Tables());
    $cache_output .=
	$self->get_fkeys('System Table',$self->System_Tables());
    $cache_output .=
	$self->get_index('System Table',$self->System_Tables());
    $cache_output .=
	$self->get_comments('System Table',$self->System_Tables());

    $cache_output .= $self->get_comments('View',$self->Views());

    $cache_output .= $self->get_comments('Procedure',$self->Procedures());

    return $cache_output;
}

sub get_schema_objects {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($query);
    my($category);
    my(@row);
    my($cache_output);

    if ($self->{'get_system'}) {
	$category = "'P', 'S', 'U', 'V'";
    } else {
	$category = "'P', 'U', 'V'";
    }
    $query = <<"EndQuery";
select 'Table'=user_name(t.uid)+'.'+t.name, 'Object_Type'=t.type, 'Field'=c.name,
    'Type'=d.name, 'Length'=c.length, 'Precision'=c.prec, 'Scale'=c.scale,
    'Identity'=(c.status & 128), 'Null'=convert(bit,(c.status & 8))
    from sysobjects t, sysusers u, syscolumns c, systypes d
    where t.type in ( $category ) and u.uid=t.uid and t.id=c.id
    and d.name in ( 'tinyint', 'smallint', 'int', 'intn', 'numeric', 'decimal',
		   'numericn', 'decimaln',
                    'float', 'floatn', 'double', 'real',
		   'smallmoney', 'money', 'moneyn',
                    'smalldatetime', 'datetime', 'datetimn',
		   'timestamp',
                    'char', 'varchar', 'nchar', 'nvarchar',
                    'binary', 'varbinary', 'bit', 'text', 'image' )
    and c.type=d.type and d.name <> 'nvarchar'
--	and c.usertype=d.usertype
	order by t.type, t.name, c.colid
EndQuery
    if ($self->{'server_type'} eq 'oracle') {
	$query = "select user_catalog.table_name, table_type, column_name, data_type, data_length, data_precision, data_scale, 0, nullable from user_catalog, user_tab_columns where user_catalog.table_name=user_tab_columns.table_name and table_type != 'SYNONYM'";
    }
    if ($self->{'server_type'} eq 'Pg') {
	$cache_output .= pg_get_table_fields($connection,$self);
    } else {
	$connection->Sql($query);
	while(@row = $connection->NextRow()) {
	    if ($connection->Regular_Row()) {
		@row = trim_spaces(@row);
		$cache_output .= join("\t",('O', @row)) . "\n";
		$self->add_table_row(@row);
	    }
	}
	while ($connection->More_Results()) {}
    }
    $cache_output .= "\f\n";
    return $cache_output;
}

sub get_pkeys {
    my($self) = shift;
    my($object_type) = shift;
    my(@objects) = @_;
    my($connection) = $self->{'connection'};
    my($object);
    my(@row);
    my($sp_pkeys);
    my($owner,$kobject);
    my($cache_output);

    if ($self->{'server_type'} eq 'Pg') {
	$cache_output .= pg_get_primary_keys($connection,$self,$object_type,
					     $self->{'database'});
    } else {
	# Get primary keys and indexes of tables
	map {
	    $object = $_;
	    if (/\./) {
		($owner,$kobject) = /^([^\.]+)\.(.*)$/;
		$sp_pkeys = "execute sp_pkeys $kobject, $owner";
	    } else {
		$sp_pkeys = "execute sp_pkeys $_";
	    }
	    if ($self->{'server_type'} eq 'oracle') {
		$sp_pkeys = "select 'table_qualifier', all_constraints.owner,
 all_constraints.table_name, column_name, position
 from all_constraints, all_cons_columns
 where all_constraints.constraint_type='P'
 and all_constraints.constraint_name=all_cons_columns.constraint_name
 and all_constraints.owner=all_cons_columns.owner
 and all_constraints.table_name=all_cons_columns.table_name
 and all_constraints.table_name = '$_'";
	    }
	    $connection->Sql($sp_pkeys);
	    while(@row = $connection->NextRow()) {
		if ($connection->Regular_Row()) {
		    @row = trim_spaces(@row);
		    $cache_output .= join("\t",('PK',$object, $object_type, @row)) . "\n";
		    $self->add_pkey_row($object,$object_type,@row);
		}
	    }
	    while ($connection->More_Results()) {}
	} @objects;
    }
    $cache_output .= "\f\n";
    return $cache_output;
}

sub get_fkeys {
    my($self) = shift;
    my($object_type) = shift;
    my(@objects) = @_;
    my($connection) = $self->{'connection'};
    my($object);
    my(@row);
    my($sp_fkeys);
    my($owner,$kobject);
    my($cache_output);

    if ($self->{'server_type'} eq 'Pg') {
	$cache_output .= pg_get_fk($connection,$self,$object_type,
				   ,$self->{'database'});
    } else {
	# Get relations
	map {
	    $object = $_;
	    if (/\./) {
		($owner,$kobject) = /^([^\.]+)\.(.*)$/;
		$sp_fkeys = "execute sp_fkeys $kobject, $owner";
	    } else {
		$sp_fkeys = "execute sp_fkeys $_";
	    }
	    if ($self->{'server_type'} eq 'oracle') {
		$sp_fkeys = "select 'tq' as pk_tq, a.owner as pk_owner, a.table_name as pk_table, a.column_name as pk_column,
 'tq', b.owner, b.table_name, b.column_name, a.position as pk_position, b.position
 from all_cons_columns a, all_cons_columns b, all_constraints ac
 where ac.constraint_type='R' and a.table_name='$_'
 and ac.r_constraint_name=a.constraint_name
 and ac.constraint_name=b.constraint_name";
	    }
	    $connection->Sql($sp_fkeys);
	    while(@row = $connection->NextRow()) {
		if ($connection->Regular_Row() &&
		    defined($row[2]) && $row[2] !~ /^\s*$/ &&
		    defined($row[3]) && $row[3] !~ /^\s*$/ &&
		    defined($row[6]) && $row[6] !~ /^\s*$/ &&
		    defined($row[7]) && $row[7] !~ /^\s*$/ ) {
		    @row = trim_spaces(@row);
		    $cache_output .= join("\t",('FK', $object_type, @row)) . "\n";
		    $self->add_fkey_row($object_type,@row);
		}
	    }
	    while ($connection->More_Results()) {}
	} @objects;
    }
    $cache_output .= "\f\n";
    return $cache_output;
}

sub get_index {
    my($self) = shift;
    my($object_type) = shift;
    my(@objects) = @_;
    my($connection) = $self->{'connection'};
    my($object);
    my(@row);
    my($sp_helpindex);
    my(@indexes);
    my($cache_output);
    my($last_index);
    my($last_string);
    my(@fields);
    my(@irow);

    if ($self->{'server_type'} eq 'Pg') {
	$cache_output .= pg_get_indexes($connection,$self,$object_type,
					$self->{'database'});
    } else {
	# Get index of table
	map {
	    $object = $_;
	    $sp_helpindex = "if exists (select id from sysindexes where id=object_id('$object') and indid > 0 and indid < 255) execute sp_helpindex '$object'";
	    if ($self->{'server_type'} eq 'oracle') {
		$sp_helpindex = "select a.index_name, uniqueness,
	column_name
	from all_indexes a, all_ind_columns b
	where owner=index_owner and a.index_name=b.index_name
        and a.table_name='$_'
	and a.table_owner=b.table_owner and a.table_name=b.table_name
	order by index_owner, a.index_name, a.table_owner, a.table_name, column_position";
	    }
	    $connection->Sql($sp_helpindex);
	    do {
		while(@row = $connection->NextRow()) {
		    if ($connection->Regular_Row()) {
			@row = trim_spaces(@row);
			if ($#row > 1) {
			    if ($row[0] ne $last_index) {
				if (defined($last_index)) {
				    @irow = ($last_index, $last_string,
					     join(', ',@fields));
				    $self->add_index_row($object,$object_type,
							 @irow);
				    $cache_output .= join("\t",('I',
								$object,
								$object_type,
								@irow)) . "\n";
				    push @indexes, join("\t",($irow[0], $irow[2],
							      $irow[1]));
				}
				undef @fields;
				$last_index = $row[0];
				$last_string = $row[1];
			    }
			    push @fields, ($row[2]);
			}
		    }
		}
	    } while ($connection->More_Results());
	    if (defined($last_index)) {
		@irow = ($last_index, $last_string,
			 join(', ',@fields));
		$self->add_index_row($object,$object_type,@irow);
		$cache_output .= join("\t",('I',
					    $object, $object_type,
					    @irow)) . "\n";
		push @indexes, join("\t",($irow[0], $irow[2],
					  $irow[1]));
	    }
	    if (defined(@indexes)) {
		$self->add_indexes($object,$object_type,@indexes);
	    }
	    undef @indexes;
	    undef $last_index;
	    undef @fields;
	    $cache_output .= "\n";
	} @objects;
    }
    $cache_output .= "\f\n";
    return $cache_output;
}

sub get_comments {
    my($self) = shift;
    my($object_type) = shift;
    my(@objects) = @_;
    my($connection) = $self->{'connection'};
    my($object);
    my($comment_query);
    my(@row);
    my($cache_output);

    map {
	$object = $_;
	my($comment_query) = <<"EndQuery";
	select text from syscomments
	    where id=object_id('$object') order by number
EndQuery
	if ($self->{'server_type'} eq 'oracle') {
	    $comment_query = "select text from all_views where view_name='$object'";
	} elsif ($self->{'server_type'} eq 'Pg') {
	    $comment_query = "SELECT definition FROM pg_views WHERE viewname='$object'";
	}
	$connection->Sql($comment_query);
	while(@row = $connection->NextRow()) {
	    if ($connection->Regular_Row()) {
		$row[0] =~ s/\r\n/\n/g;
		$row[0] =~ s/\n\r/\n/g;
		$row[0] =~ s/\n$//g;
		$row[0] =~ s/^\s*//g;
		$row[0] =~ s/\s*$//g;
		$row[0] =~ s/\t/     /g;
		if ($self->{'server_type'} eq 'Pg') {
		    $row[0] =~ s/\s*\;\s*$//;
		}		
		$self->{$object_type}->{$object}->{'comments'} .= $row[0];
		$row[0] =~ s/\n/\r/g;
		$cache_output .= join("\t",('C',$object,$object_type, $row[0] )) . "\n";
	    }
	}
	while ($connection->More_Results()) {}
    } @objects;
    $cache_output .= "\f\n";
    return $cache_output;
}


# Object destroy routine
sub DESTROY {
}

#
# $database = $schema->Database();
#

sub Database {
    my($self) = shift;
    return $self->{'database'};
}

#
# @user_tables = $schema->User_Tables();
#

sub User_Tables {
    my($self) = shift;
    return (keys %{$self->{'User Table'}});
}

#
# @views = $schema->Views();
#

sub Views {
    my($self) = shift;
    return (keys %{$self->{'View'}});
}

#
# @procedures = $schema->Procedures();
#

sub Procedures {
    my($self) = shift;
    return (keys %{$self->{'Procedure'}});
}

#
# @system_tables = $schema->System_Tables();
#

sub System_Tables {
    my($self) = shift;
    return (keys %{$self->{'System Table'}});
}

#
# @fields = $schema->Table_Fields($table);
#

sub Table_Fields {
    my($self) = shift;
    my($object) = shift;
    return $self->Fields($object,'User Table');
}

#
# @fields = $schema->System_Table_Fields($table);
#

sub System_Table_Fields {
    my($self) = shift;
    my($object) = shift;
    return $self->Fields($object,'System Table');
}

#
# @fields = $schema->View_Fields($view);
#

sub View_Fields {
    my($self) = shift;
    my($object) = shift;
    return $self->Fields($object,'View');
}

#
# @fields = $schema->Procedure_Parameters($procedure);
#

sub Procedure_Parameters {
    my($self) = shift;
    my($object) = shift;
    return $self->Fields($object,'Procedure');
}

#
# @fields = $schema->Fields($object,$object_type);
#

sub Fields {
    my($self) = shift;
    my($object) = shift;
    my($object_type) = shift;
    $object_type = (defined($object_type)) ? $object_type : 'User Table';
    if (defined($self->{$object_type}->{$object}->{'Fields'})) {
	return @{$self->{$object_type}->{$object}->{'Fields'}};
    } else {
	return ();
    }
}

#
# $field_info = $schema->Field_Info($object,$field,$object_type,$info_type);
#

sub Field_Info {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    my($info_type) = shift;
    $object_type = (defined($object_type)) ? $object_type : 'User Table';
    $info_type = (defined($info_type)) ? $info_type : 'Type';
    return $self->{$object_type}->{$object}->{'Field'}->{$field}->{$info_type};
}

#
# $primary_key_number = $schema->Primary_Key($object,$field,$object_type);
#

sub Primary_Key {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    return $self->Field_Info($object,$field,$object_type,'Primary_Key');
}

#
# $field_type = $schema->Field_Type($object,$field,$object_type);
#

sub Field_Type {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    return $self->Field_Info($object,$field,$object_type,'Type');
}

#
# $field_length = $schema->Field_Length($object,$field,$object_type);
#

sub Field_Length {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    return $self->Field_Info($object,$field,$object_type,'Length');
}

#
# $field_width = $schema->Field_Width($object,$field,$object_type);
#

sub Field_Width {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    my($type) = $self->Field_Type($object,$field,$object_type);
    my($length) = $self->Field_Length($object,$field,$object_type);;
    my(%numeric_length) = ( 1 => 3,
			   2 => 5,
			   4 => 10 );
    my($width);

    if ($type =~ /char/ ||
	$type =~ /decimal/ ||
	$type =~ /numeric/ ) {
	$width = $length;
    } elsif ($type =~ /text/ ) {
	$width = 255;		# Not a real good answer for this one
    } elsif ($type =~ /int/) {
	$width = $numeric_length{$length};
    } elsif ($type =~ /float/ || $type =~ /real/ ) {
	$width = 15;		# this might vary
    } elsif ($type eq 'smallmoney' ) {
	$width = 14;
    } elsif ($type =~ /money/ ) {
	$width = 26;
    } elsif ($type =~ /date/ ) {
	$width = 26;		# Not a real good answer for this one
    } elsif ($type eq 'bit' ) {
	$width = 1;
    } else {
	$width = $length;
    }
    
    return $width;
}

#
# $field_precision = $schema->Field_Precision($object,$field,$object_type);
#

sub Field_Precision {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    return $self->Field_Info($object,$field,$object_type,'Precision');
}

#
# $field_scale = $schema->Field_Scale($object,$field,$object_type);
#

sub Field_Scale {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    return $self->Field_Info($object,$field,$object_type,'Scale');
}

#
# $field_identity = $schema->Field_Identity($object,$field,$object_type);
#

sub Field_Identity {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    return $self->Field_Info($object,$field,$object_type,'Identity');
}

#
# $field_null = $schema->Field_Null($object,$field,$object_type);
#

sub Field_Null {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($object_type) = shift;
    return $self->Field_Info($object,$field,$object_type,'Null');
}

#
# @indexes = $schema->Indexes($table,$object_type);
#

sub Indexes {
    my($self) = shift;
    my($table) = shift;
    my($object_type) = shift;

    $object_type = (defined($object_type)) ? $object_type : 'User Table';
    return split("\n",$self->{$object_type}->{$table}->{'indexes'});
}

#
# @primary_keys = $schema->Primary_Keys($table,$object_type);
#

sub Primary_Keys {
    my($self) = shift;
    my($table) = shift;
    my($object_type) = shift;

    $object_type = (defined($object_type)) ? $object_type : 'User Table';
    if (defined($self->{$object_type}->{$table}->{'primary_keys'})) {
	return @{$self->{$object_type}->{$table}->{'primary_keys'}};
    } else {
	return ();
    }
}


#
# @keys = $schema->Keys($table,$object_type);
#

sub Keys {
    my($self) = shift;
    my($table) = shift;
    my($object_type) = shift;

    $object_type = (defined($object_type)) ? $object_type : 'User Table';
    if (defined($self->{$object_type}->{$table}->{'index_keys'})) {
	return @{$self->{$object_type}->{$table}->{'index_keys'}};
    } else {
	return ();
    }
}

#
# @children_tables = $schema->Children($table);
#

sub Children {
    my($self) = shift;
    my($object) = shift;
    my($object_type) = 'User Table';

    if (defined($self->{$object_type}->{$object}->{'children'})) {
	return @{$self->{$object_type}->{$object}->{'children'}};
    } else {
	return ();
    }
}

#
# @parent_tables = $schema->Parents($table);
#

sub Parents {
    my($self) = shift;
    my($object) = shift;
    my($object_type) = 'User Table';

    if (defined($self->{$object_type}->{$object}->{'parents'})) {
	return @{$self->{$object_type}->{$object}->{'parents'}};
    } else {
	return ();
    }
}

#
# @field_equivalences = $schema->Relation($parent,$child);
#

sub Relation {
    my($self) = shift;
    my($parent) = shift;
    my($child) = shift;
    my($object_type) = 'User Table';

    if (defined($self->{'Relation'}->{"$parent\t$child"})) {
	return @{$self->{'Relation'}->{"$parent\t$child"}};
    } else {
	return ();
    }
}



#
# Get comments (views' and procedures' definitions)
#
# $comments = $schema->Comments($object,$object_type)
#

sub Comments {
    my($self) = shift;
    my($object) = shift;
    my($object_type) = shift;

    $object_type = (defined($object_type)) ? $object_type : 'Procedure';
    return $self->{$object_type}->{$object}->{'comments'};
}

#
# Get view's tables
#
# @tables = $schema->View_Tables($view)
#

sub View_Tables {
    my($self) = shift;
    my($object) = shift;
    my(@tables);
    my($view_query);
    my(%hash_table);

    $view_query = $self->Comments($object,'View');
    # See if object is a table
    if (!defined($view_query) || $view_query eq '') {
	push @tables, ($object);
    } else {
	$view_query =~ s/\n/ /g;
	$view_query =~ s/^.*\s+[Ff][Rr][Oo][Mm]\s+//;
	$view_query =~ s/[Ww][Hh][Ee][Rr][Ee]\s+.*$//;
	$view_query =~ s/\(//g;
	$view_query =~ s/\)//g;
	$view_query =~ s/[Jj][Oo][Ii][Nn]/,/g;
	map {
	    s/^\s*//g;
	    s/\s*$//g;
	    s/^(\S+)\s+.*$/$1/;
	    if (!defined($hash_table{$_}) ) {
		$hash_table{$_} = 1;
	    }
	} split(',',$view_query);
	@tables = keys %hash_table;
    }
    return @tables;
}

#
# $quoted_field = $schema->Quote_Field($object,$field,$value,$object_type);
#

sub Quote_Field {
    my($self) = shift;
    my($object) = shift;
    my($field) = shift;
    my($value) = shift;
    my($object_type) = shift;
    my($type) = $self->Field_Info($object,$field,$object_type,'Type');
    my($length) = $self->Field_Length($object,$field,$object_type);
    my($quoted);

    $type =~ tr/[A-Z]/[a-z]/;
    if ($type =~ /char/ ||
	$type =~ /text/ ||
	$type =~ /date/ ) {
	$quoted = 1;
    }
    if ($quoted) {
	$value =~ s/\'/\'\'/g;	# Quote quotes
	if (length($value) > $length &&
	    $type !~ /date/ && 
	    $type !~ /text/) {
	    $value = substr($value,0,$length);
	}
	$value = "'$value'";
    }
    if ($type =~ /date/ &&
	$self->{'server_type'} eq 'oracle') {
	$value = "TO_DATE($value, 'YYYY-MM-DD HH24:MI:SS')";
    }
    return $value;
}


sub read_schema_cache {
    my($self) = shift;
    my($database) = $self->{'database'};
    my($server) = $self->{'server'};
    my($user) = $self->{'user'};
    my($line_type);
    my(@row);
    my($object, $object_type);
    my(@indexes);
    my($cache);

    $cache = "$RDBAL::Config::cache_directory/$server$database$user.cache";
    if (-e $cache && -r $cache) {
	open(CACHE,"$cache");
	while(<CACHE>) {
	    chomp;
	    ($line_type, @row) = split("\t");
	    if ($line_type eq 'O') {
		$self->add_table_row(@row);
	    } elsif ($line_type eq 'PK') {
		$self->add_pkey_row(@row);
	    } elsif ($line_type eq 'FK') {
		$self->add_fkey_row(@row);
	    } elsif ($line_type eq 'I') {
		$self->add_index_row(@row);
		$object = $row[0];
		$object_type = $row[1];
		push @indexes, join("\t",($row[2], $row[4], $row[3]));
	    } elsif ($line_type eq 'C') {
		$row[2] =~ s/\r/\n/g;
		$self->{$row[1]}->{$row[0]}->{'comments'} .= $row[2];
	    } elsif ($line_type =~ /^$/) {
		if (defined($object) && defined($object_type)) {
		    $self->add_indexes($object,$object_type,@indexes);
		}
		undef $object;
		undef $object_type;
		undef @indexes;
	    }
	}
	close(CACHE);
	return 1;
    } else {
	return 0;
    } 
}

sub write_schema_cache {
    my($self) = shift;
    my($cache_output) = shift;
    my($nocache) = shift;
    my($database) = $self->{'database'};
    my($server) = $self->{'server'};
    my($user) = $self->{'user'};
    my($cache);

    $cache = "$RDBAL::Config::cache_directory/$server$database$user.cache";
    if (-e $RDBAL::Config::cache_directory &&
	($nocache || !-e $cache)) {
	open(CACHE,">$cache");
	print CACHE $cache_output;
	close(CACHE);
	return 1;
    } else {
	return 0;
    } 
}

sub trim_spaces {
    my($item);
    foreach $item (@_) {
	$item =~ s/^\s*//g;
	$item =~ s/\s*$//g;
	$item =~ s/\t/ /g;
    }
    return @_;
}


sub add_table_row {
    my($self) = shift;
    my($object,
       $object_type,
       $field,
       $type,
       $length,
       $precision,
       $scale,
       $identity,
       $null) = @_;
    my(%otype_name) = ( 'S' => 'System Table',
			'U' => 'User Table',
			'V' => 'View',
			'P' => 'Procedure',
			'TABLE' => 'User Table',
			'VIEW' => 'View',
			'PROCEDURE' => 'Procedure'
			);
    my($objref);

    $object =~ s/^dbo\.//;
    $objref = $self->{$otype_name{$object_type}}->{$object};
    if ($identity) {
	$objref->{'Identity_Column'} = $field;
    }
    $objref->{'Field'}->{$field} =
    {
	'Type' => $type,
	'Length' => $length,
	'Precision' => $precision,
	'Scale' => $scale,
	'Identity' => $identity,
	'Null' => $null
	};
    push @{$objref->{'Fields'}}, ($field);
    $self->{$otype_name{$object_type}}->{$object} = $objref;
    return $self;
}

sub add_pkey_row {
    my($self) = shift;
    my($object) = shift;
    my($object_type) = shift;
    my(@row) = @_;

    if (!defined($self->{$object_type}->{$object}->{'primary_keys'})) {
	$self->{$object_type}->{$object}->{'primary_keys'} = [];
    }
    push @{$self->{$object_type}->{$object}->{'primary_keys'}}, ($row[3]);
    $self->{$object_type}->{$object}->{'Field'}->{$row[3]}->{'Primary_Key'} =
	$row[4];
    return $self;
}

sub add_index_row {
    my($self) = shift;
    my($table) = shift;
    my($object_type) = shift;
    my(@row) = @_;
    if (!defined($self->{$object_type}->{$table}->{'index_keys'})) {
	$self->{$object_type}->{$table}->{'index_keys'} = [];
    }
    push @{$self->{$object_type}->{$table}->{'index_keys'}}, ($row[2]);
}

sub add_indexes {
    my($self) = shift;
    my($table) = shift;
    my($object_type) = shift;
    my(@indexes) = @_;

    $self->{$object_type}->{$table}->{'indexes'} = join("\n",@indexes);
    return $self;
}


sub add_fkey_row {
    my($self) = shift;
    my($object_type) = shift;
    my(@row) = @_;
    my($object);

    $object = $row[2];
    if (!defined($self->{$object_type}->{$object}->{'children'})) {
#	$self->{$object_type}->{$object}->{'children'} = [];
    }
    if (!defined($self->{$object_type}->{$object}->{'parents'})) {
	$self->{$object_type}->{$object}->{'parents'} = [];
    }
    if (!defined($self->{'Relation'}->{"$object\t$row[6]"})) {
	$self->{'Relation'}->{"$object\t$row[6]"} = [];
    }
    push @{$self->{'Relation'}->{"$object\t$row[6]"}}, ("$row[3]=$row[7]");
    if (!defined($self->{'children'}->{"$object\t$row[6]"})) {
	$self->{'children'}->{"$object\t$row[6]"} = 1;
	push @{$self->{$object_type}->{$object}->{'children'}}, ($row[6]);
	push @{$self->{$object_type}->{$row[6]}->{'parents'}}, ($object);
    }
    return $self;
}

sub pg_get_table_fields {
    my($X) = shift;
    my($self) = shift;
    my($view_query) = 'SELECT viewname from pg_views';
    # Table Fields:
    my($query) = "SELECT c.relname as \"object\", 'U' as \"objecttype\",
		a.attname as \"fieldname\", t.typname as \"typename\",
		a.attlen as \"typelength\", a.atttypmod as \"fieldlength\",
		0 as \"identity\", a.attnotnull as \"nullable\"
	FROM pg_class c, pg_attribute a, pg_user u, pg_type t 
	WHERE c.relkind = 'r' and
		a.attnum > 0 and a.attrelid = c.oid and
		c.relowner=u.usesysid and a.atttypid = t.oid
	ORDER BY c.relname, attnum";
    my(@row);
    my($result);
    my($status);
    my($cache_output);

    $result = $X->Sql($view_query);
    my($view);
    my(%VIEW);
    do {
	while(@row = $X->NextRow()) {
	    if ($X->Regular_Row()) {
		$view = $row[0];
		$VIEW{$view} = 1;
	    }
	}
    } while ($X->More_Results());

    $result = $X->Sql($query);
    my($object, $objecttype, $fieldname, $typename, $typelength, $attlength,
       $identity, $nullable);
    do {
	while(@row = $X->NextRow()) {
	    if ($X->Regular_Row()) {
		($object, $objecttype, $fieldname, $typename,
		 $typelength, $attlength,
		 $identity, $nullable) = @row;
		my($fieldlength, $precision, $scale);
		my(%TYPEMAP) = (
				'abstime' => 'datetime',
				'aclitem' => 'binary',
				'bool' => 'bit',
				'box' => 'binary',
				'bpchar' => 'char',
				'bytea' => 'tinyint',
				'cid' => 'binary',
				'cidr' => 'binary',
				'circle' => 'binary',
				'date' => 'datetime',
				'filename' => 'varchar',
				'float4' => 'float',
				'float8' => 'double',
				'inet' => 'binary',
				'int2' => 'smallint',
				'int4' => 'int',
				'int8' => 'int',
				'line' => 'binary',
				'lseg' => 'binary',
				'macaddr' => 'binary',
				'name' => 'varchar',
				'oid' => 'int',
				'oid8' => 'int',
				'path' => 'varchar',
				'point' => 'binary',
				'polygon' => 'binary',
				'regproc' => 'binary',
				'reltime' => 'datetime',
				'smgr' => 'binary',
				'tid' => 'int',
				'time' => 'datetime',
				'timespan' => 'datetime',
				'tinterval' => 'datetime',
				'unknown' => 'binary',
				'xid' => 'int'
				);
		
		if (defined($TYPEMAP{$typename})) {
		    $typename = $TYPEMAP{$typename};
		}
		
		if ($typelength > 0) {
		    $fieldlength = $typelength;
		    undef $precision;
		    undef $scale;
		} else {
		    if ($typename =~ /[Nn][Uu][Mm][Ee][Rr][Ii][Cc]/) {
			$precision = ($attlength - 4) >> 16;
			$scale = ($attlength - 4) & 0xffff;
			$fieldlength = $precision;
		    } else {
			$fieldlength = $attlength - 4;
			undef $precision;
			undef $scale;
		    }
		}
		$nullable = ($nullable =~ /[Tt]/) ? 0 : 1;
		$objecttype = (defined($VIEW{$object})) ? 
		    ( ($object =~ /^pg_/) ? 'SV' : 'V') :
			( ($object =~ /^pg_/) ? 'S' : 'U') ;
		@row = ($object, $objecttype, $fieldname,
				     $typename, $fieldlength,
				     $precision, $scale,
				     $identity, $nullable);
		$cache_output .= join("\t",('O', @row)) . "\n";
		$self->add_table_row(@row);
	    }
	}
    } while ($X->More_Results());
    return $cache_output;
}


sub pg_get_primary_keys {
    my($X) = shift;
    my($self) = shift;
    my($ob_type) = shift;
    my($database) = shift;
    my($cache_output);

    # Primary Key
    my($query) = "SELECT t.relname as \"object\",
		'User Table' as \"objecttype\",
		'$database' as \"database\", ' ' as \"owner\",
		t.relname as \"object\",
		a.attname as \"fieldname\", a.attnum as \"position\",
		c.relname as \"primary_key\"
	FROM pg_class c, pg_class t, pg_index i, pg_attribute a
	WHERE a.attnum > 0 and a.attrelid=c.oid and t.oid=i.indrelid
	and c.oid=i.indexrelid and i.indisunique='t'
	ORDER BY t.relname, attnum";
    my(@row);
    my($result);
    my($status);

    $result = $X->Sql($query);
    do {
	while(@row = $X->NextRow()) {
	    if ($X->Regular_Row()) {
		if (($ob_type eq 'User Table' && $row[0] !~ '^pg_') ||
		    ($ob_type eq 'System Table' && $row[0] =~ '^pg_')) {
			$cache_output .= join("\t",('PK',@row)) . "\n";
			$self->add_pkey_row(@row);
		}
	    }
	}
    } while ($X->More_Results());
    return $cache_output;
}

sub pg_get_fk {
    my($X) = shift;
    my($self) = shift;
    my($ob_type) = shift;
    my($database) = shift;
    my($cache_output);

    # Rules
    my($query) = "SELECT tablename, rulename, definition FROM pg_rules";
    my(@row);
    my($result);
    my($status);

    $result = $X->Sql($query);
    my($object, $rulename, $definition);
    my($rule, $ptable, $where);
    do {
	while(@row = $X->NextRow()) {
	    if ($X->Regular_Row()) {
		($object, $rulename, $definition) = @row;
		if ($rulename =~ /^fk_/ &&
		    $definition =~ /^\s*CREATE\s+RULE\s+(\S+)\s+AS\s+ON\s+INSERT\s+TO\s+(\S+)\s+WHERE\s+(.*)\s*DO\s+INSTEAD\s+NOTHING\s*/i) {
		    ($rule, $ptable, $where) = $definition =~ /^\s*CREATE\s+RULE\s+(\S+)\s+AS\s+ON\s+INSERT\s+TO\s+(\S+)\s+WHERE\s+(.*)\s*DO\s+INSTEAD\s+NOTHING\s*/i;
		    $rule =~ s/\"//g;
		    $ptable =~ s/\"//g;
		    if (($ob_type eq 'User Table' && $ptable !~ '^pg_') ||
			($ob_type eq 'System Table' && $ptable =~ '^pg_')) {
			$cache_output .= pg_parse_for_fkey($self,
							   $database,$ptable,
							   $rulename,$where);
		    }
		}
	    }
	}
    } while ($X->More_Results());
    return $cache_output;
}

sub pg_parse_for_fkey {
    my($self) = shift;
    my($database) = shift;
    my($table) = shift;
    my($rulename) = shift;
    my($where) = shift;
    my($relation_ref) = shift;
    my($cache_output) = shift;
    my($conjunction);
    my($first,$operator,$second);
    my($primary, $foreign);
    my($ptable, $ftable, $pfield, $ffield);
    my($object_type) = ($table =~ /^pg_/) ? 'System Table' : 'User Table';
    my($key_seq);
    my(@row);

    if (!defined($relation_ref)) {
	$relation_ref = {};
    }
    if ($where =~ /^\s*$/) {
	return $cache_output;
    }
    ($conjunction) = $where =~ s/^\s*(OR|AND)\s+//i;
    $where =~ s/^\s*(OR|AND)\s+//i;
    $where =~ s/^\(+//;
    ($first,$operator,$second) = $where =~ /^(\S+)\s+(\S+)\s+(\S+)/;
    $second =~ s/\)+//g;
    if ($first =~ /new\./) {
	$primary = $second;
	$foreign = $first;
    } else {
	$primary = $first;
	$foreign = $second;
    }
    $foreign =~ s/new\./$table./;
    $foreign =~ s/\"//g;
    $primary =~ s/\"//g;
    $where =~ s/^\S+\s+\S+\s+\S+//;
    $where =~ s/^\s*\)+\s*//;
    ($ptable, $pfield) = split('\.',$primary);
    ($ftable, $ffield) = split('\.',$foreign);
    $key_seq = $relation_ref->{"$ftable\t$ptable"}; # key sequence position
    $key_seq++;
    $relation_ref->{"$ftable\t$ptable"} = $key_seq;
    @row = ($database, undef, $ptable, $pfield, $database, undef, $ftable,
	    $ffield, $key_seq, 1, 1, $rulename);
    $cache_output .= join("\t",('FK', $object_type, @row)) . "\n";
    $self->add_fkey_row($object_type,@row);
    return pg_parse_for_fkey($self,$database,$table,$rulename,$where,
			     $relation_ref,$cache_output);
}


sub pg_get_indexes {
    my($X) = shift;
    my($self) = shift;
    my($ob_type) = shift;
    my($database) = shift;
    my($cache_output);
    # Indexes
    my($query) = "SELECT t.relname as \"tablename\",
		'User Table' as \"objecttype\",
		c.relname as \"indexname\", a.attname as \"fieldname\",
		i.indisunique, i.indisclustered
	FROM pg_class c, pg_class t, pg_index i, pg_attribute a
	WHERE a.attnum > 0 and a.attrelid=c.oid and t.oid=i.indrelid and
	c.oid=i.indexrelid'
	ORDER BY t.relname, attnum";
    my(@row);
    my($result);
    my($status);
    my($object, $object_type, $indexname, $fieldname, $isunique, $isclustered);
    my($last_index);
    my($last_object, $last_indexname);
    my(@fields);
    my($indexdescription);
    my(@indexdescription);
    my(@irow);
    my(@indexes);

    $result = $X->Sql($query);
    do {
	while(@row = $X->NextRow()) {
	    if ($X->Regular_Row()) {
		($object, $object_type, $indexname, $fieldname,
		 $isunique, $isclustered) = @row;
		if ($last_index ne "$object\t$object_type\t$indexname" &&
		    defined($last_index)) {
		    @irow = ($last_indexname, $indexdescription,
			     join(', ',@fields));
		    if (($ob_type eq 'User Table' && $object !~ '^pg_') ||
			($ob_type eq 'System Table' && $object =~ '^pg_')) {
			$self->add_index_row($last_object,$object_type,
					     @irow);
			$cache_output .= join("\t",('I',
						    $last_object,
						    $object_type,
						    @irow)) . "\n";
			push @indexes, join("\t",($irow[0], $irow[2],
						  $irow[1]));
			if (defined(@indexes)) {
			    $self->add_indexes($last_object,$object_type,
					       @indexes);
			}
			undef @indexes;
		    }
		    undef @fields;
		    if ($last_object ne $object && defined($last_object)) {
			$cache_output .= "\n";
		    }
		}
		$last_object = $object;
		$last_indexname = $indexname;
		undef @indexdescription;
		if ($isunique =~ /[Tt]/) {
		    push @indexdescription, ('unique');
		}
		if ($isclustered =~ /[Tt]/) {
		    push @indexdescription, ('clustered');
		}
		$indexdescription = join(', ',@indexdescription);
		$last_index = "$object\t$object_type\t$indexname";
		push @fields, ($fieldname);
	    }
	}
    } while ($X->More_Results());
    return $cache_output;
}



1;


__END__

=head1 NAME

RDBAL::Schema - RDBAL Schema information object

=head1 SYNOPSIS

  use RDBAL;
  use RDBAL::Schema;
  $X = RDBAL::Connect('username', 'password', 'server');
  $schema = new($X,$database);
  $database = $schema->Database();
  @user_tables = $schema->User_Tables();
  @views = $schema->Views();
  @procedures = $schema->Procedures();
  @system_tables = $schema->System_Tables();
  @fields = $schema->Table_Fields($table);
  @fields = $schema->System_Table_Fields($table);
  @fields = $schema->View_Fields($view);
  @fields = $schema->Procedure_Parameters($procedure);
  @fields = $schema->Fields($object,$object_type);
  $field_info = $schema->Field_Info($object,$field,$object_type,$info_type);
  $primary_key_number = $schema->Primary_Key($object,$field,$object_type);
  $field_type = $schema->Field_Type($object,$field,$object_type);
  $field_length = $schema->Field_Length($object,$field,$object_type);
  $field_width = $schema->Field_Width($object,$field,$object_type);
  $field_precision = $schema->Field_Precision($object,$field,$object_type);
  $field_scale = $schema->Field_Scale($object,$field,$object_type);
  $field_identity = $schema->Field_Identity($object,$field,$object_type);
  $field_null = $schema->Field_Null($object,$field,$object_type);
  @indexes = $schema->Indexes($table,$object_type);
  @primary_keys = $schema->Primary_Keys($table,$object_type);
  @keys = $schema->Keys($table,$object_type);
  @children_tables = $schema->Children($table);
  @parent_tables = $schema->Parents($table);
  @field_equivalences = $schema->Relation($parent,$child);
  # Get comments (views' and procedures' definitions)
  $comments = $schema->Comments($object,$object_type)
  # Get view's tables
  @tables = $schema->View_Tables($view)

=head1 ABSTRACT

This perl library uses perl5 objects to make it easy to retrieve
information about a particular PostgreSQL, Sybase, MS SQL, or Oracle
databases's schema.

=head1 INSTALLATION:

If you wish to change the location of the schema cache directory from the default value of '/usr/local/schema_cache', edit Config.pm.

To install this package, just change to the directory in which this file is
found and type the following: 

        perl Makefile.PL
        make
        make test
        make install

and to create the schema cache directory:

	make schema_cache

=head2 Installation of pg_schema.pl

An example script for converting a DDL in Transact SQL format to
PostgreSQL format with foreign key relational integrity enforced and
remembered by PostgreSQL rules is included and must be manually
installed (change the first line from #!/usr/local/bin/perl if your
perl lives elsewhere).  See pg_schema.pl below for more.

=head1 DESCRIPTION

The schema information available includes:

=over 4

=item Objects:     tables, views, and procedures

=item Objects' fields (or parameters)

=item Objects' fields' properties:
          type, length, precision, scale, identity column, nullable

=item Tables' indexes and primary keys

=item Parent => child relations between tables including primary key/foreign key equivalences.  

=item Views' and Procedures' definitions (Comments).

=item A view's underlying tables.

=back

The database connection is cached in the schema object.  Objects
and their fields properties and index information are retrieved when
the schema object is created.  Table relationship information is
retrieved for all tables when the first relationship information is
requested.

=head2 pg_schema.pl

The rules this script creates are necessary for RDBAL to have foreign
key relation information.  It translates a foreign key reference into
PostgreSQL rules:

FROM:

    alter table table2
        add foreign key  (field1, field2)
           references table1 (field1, field2)
    go

TO:

Insert RI:

	create rule fk_table2_insert as on insert to table2
	where new.field1 <> table1.field1 and new.field2 <> table1.field1
        do instead nothing;

Update RI:

	create rule fk_table2_update as on update to table2
	where new.field1 <> table1.field1 and new.field2 <> table1.field2
        do instead nothing;

	create rule pk_table1_update as on update to table1
	where old.field1 = table2.field1 and old.field2 = table2.field2
        do instead nothing;

NOTE: the pk_update rule must list all children!

Delete RI:

	create rule pk_table1_delete as on delete to table1
	where old.field1 = table2.field1 and old.field2 = table2.field2
        do instead nothing;

NOTE: the delete rule must list all children!

This script also maps datatypes:

=over 4

=item smalldatetime to datetime

=item tinyint to int

=item float4 or float8 to float

=back

pg_schema.pl reads the input DDL on standard input and writes the
output DDL to standard output.

=head2 CREATING A NEW RDBAL::Schema OBJECT:

     $query = new RDBAL::Schema($connection,$database);

     OR

     $query = new RDBAL::Schema($connection,$database, -option => value);

Options are passed as: -option => value, where -option is one of:

     -server         Database server name.  This is used to differentiate
                     between databases when caching.
     -server_type    Database server type.  This is used to differentiate
                     how to retrieve the schema.  The default is Transact-SQL
                     or a hand-crafted schema cache file.  Currently, the
                     only correct values for this are I<undef>, I<pg>,
                     I<oracle>, I<dbi:Sybase>, or I<dbi:Oracle>.
     -get_system     1 or undef.  A true value for this option causes retrieval
                     (and caching) of schema for system tables.
     -nocache        1 or undef.  A true value causes the cached schema to not
                     be used and a new cache to be written.
     -username       Database username.  This is used to differentiate
                     between different users views of a database when caching.

This will create a new schema object for the database.  This must be given
an open connection to a RDBAL database server object:

  use RDBAL;
  $connection = RDBAL::Connect('username', 'password', 'server');

=head2 Fetching the database from the schema object:

     $database = $schema->Database();

The database may be retrieved from the database schema object.

=head2 Fetching the user tables from the schema:

     @user_tables = $schema->User_Tables();

The user tables may be retrieved from the database schema.

=head2 Fetching the views from the schema:

     @views = $schema->Views();

The views may be retrieved from the database schema.

=head2 Fetching the procedures from the schema:

     @procedures = $schema->Procedures();

The procedures may be retrieved from the database schema.

=head2 Fetching the system tables from the schema:

     @system_tables = $schema->System_Tables();

The system tables may be retrieved from the database schema if the -get_system
option was given when the schema object (or its cache) was created.

=head2 Fetching the fields from the schema for a user table:

     @fields = $schema->Table_Fields($table);

A user table's fields may be retrieved from the database schema.

=head2 Fetching the fields from the schema for a system table:

     @fields = $schema->System_Table_Fields($table);

A system table's fields may be retrieved from the database schema if the -get_system
option was given when the schema object (or its cache) was created.

=head2 Fetching the fields from the schema for a view:

     @fields = $schema->View_Fields($view);

A view's fields may be retrieved from the database schema.

=head2 Fetching the parameters from the schema for a procedure:

     @parameters = $schema->Procedure_Parameters($procedure);

A procedure's parameters may be retrieved from the database schema.

=head2 Fetching the fields from the schema:

     @fields = $schema->Fields($object,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The fields may be retrieved from the database schema for B<$object_type>'s of:

=over 4

=item 'User Table'

=item 'System Table'

=item 'View'

=item 'Procedure'

=back

=head2 Fetching the primary key number from the schema for a field:

     $primary_key_number = $schema->Primary_Key($object,$field,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The primary key number may be retrieved from the database schema for a field.
I<undef> is returned if the field is not a primary key.

=head2 Fetching the field type from the schema:

     $field_type = $schema->Field_Type($object,$field,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The field type may be retrieved from the database schema.

=head2 Fetching the field length from the schema:

     $field_length = $schema->Field_Length($object,$field,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The field length may be retrieved from the database schema.

=head2 Fetching the field width from the schema:

     $field_width = $schema->Field_Width($object,$field,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

A value for the character string width of a field may be retrieved from the database schema.

=head2 Fetching the field precision from the schema:

     $field_precision = $schema->Field_Precision($object,$field,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The field precision may be retrieved from the database schema.

=head2 Fetching the field scale from the schema:

     $field_scale = $schema->Field_Scale($object,$field,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The field scale may be retrieved from the database schema.
If the field datatype does not have a scale, the value is I<undef>.

=head2 Fetching the field's identity column status from the schema:

     $field_identity = $schema->Field_Identity($object,$field,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The field's identity column status may be retrieved from the database schema.
Nonzero implies the field is an identity column.

=head2 Fetching the field nullable from the schema:

     $field_null = $schema->Field_Null($object,$field,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

Whether a field is nullable may be retrieved from the database schema.
It is a I<1> if the field is nullable.

=head2 Fetching a field's (or parameter's) information from the schema:

     $field_info = $schema->Field_Info($object,$field,$object_type,$info_type);

B<$object_type> is optional and defaults to B<'User Table'>.
B<$info_type> is optional and defaults to B<'Type'>.

A field's information may be retrieved from the database schema for
B<$object_type>'s of:

=over 4

=item 'User Table'

=item 'System Table'

=item 'View'

=item 'Procedure'

=back

and B<$info_type>'s of:

=over 4

=item 'Primary_Key'

=item 'Type'

=item 'Length'

=item 'Precision'

=item 'Scale'

=item 'Identity'

=item 'Null'

=back

=over 4

=item The primary key number may be retrieved from the database schema for a field.
     I<undef> is returned if the field is not a primary key.

=item The field type may be retrieved from the database schema.

=item The field length may be retrieved from the database schema.

=item The field precision may be retrieved from the database schema.

=item The field scale may be retrieved from the database schema.

=item The field's identity column status may be retrieved from the database schema.
     Nonzero implies the field is an identity column.

=item Whether a field is nullable may be retrieved from the database schema.
     It is a I<1> if the field is nullable.

=back

=head2 Fetching the indexes from the schema:

     @indexes = $schema->Indexes($table,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The indexes may be retrieved from the database schema.  Each index is
reported as (each item seperated by tabs):

    index_name	index_description	comma_seperated_index_field_list

Example:

     PK_STS	clustered, unique located on default	chromosome, arm, id_number

=head2 Fetching the primary key fields from the schema:

     @primary_keys = $schema->Primary_Keys($table,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

The primary key fields may be retrieved from the database schema.

=head2 Fetching all index keys from the schema:

     @keys = $schema->Keys($table,$object_type);

B<$object_type> is optional and defaults to B<'User Table'>.

All of the index keys may be retrieved from the database schema.
Each array element is a comma delimited list of the index's keys.

=head2 Fetching the children tables from the schema:

     @children_tables = $schema->Children($table);

A table's children tables may be retrieved from the database schema.

=head2 Fetching the parent tables from the schema:

     @parent_tables = $schema->Parents($table);

A table's parent tables may be retrieved from the database schema.

=head2 Fetching the field equivalences from the schema:

     @field_equivalences = $schema->Relation($parent,$child);

The key field equivalences may be retrieved from the database schema.
Each key field equivalence array element is given as:
     parent_key_field=child_key_field

=head2 Fetching the comments (views' and procedures' definitions) from the schema:

     $comments = $schema->Comments($object,$object_type)

B<$object_type> is optional and defaults to B<'Procedure'>.

The comments (views' and procedures' definitions) may be retrieved from
the database schema.

=head2 Getting a view's underlying tables from the schema:

     @tables = $schema->View_Tables($view)

A view's underlying tables may be retrieved from the database schema.

=head2 Quote a field's value if necessary

     $quoted_field = $schema->Quote_Field($object,$field,$value,$object_type);

Appropriately put quote marks around a field's value.
Single quote marks get doubled, example: dont't  ==> "don''t".

=head1 Schema Cache File Format

The schema cache file contains individual lines which describe some
part of a schema (a descriptor).  Each descriptor is a tab delimited
line with the first element on the line specifying what is being
described (the type).  Carriage returns (not newlines) may be embedded
in the comment (definition) descriptor elements.  Blank lines follow
each group of index descriptors for a table.  Line feeds seperate
different types of descriptors.

=head2 Object Descriptor

An object descriptor describes the fields or parameters of a system or
user table, a view, or a procedure.  It contains the following (tab
delimited) elements:

=over 4

=item Type = 'O'

=item Object = owner.object (owner defaults to 'dbo')

=item Object type:

       S => 'System Table'
       U => 'User Table'
       V => 'View'
       P => 'Procedure'
       TABLE => 'User Table'
       VIEW => 'View'
       PROCEDURE => 'Procedure'

=item Field name

=item Field type

=item Field length

=item Field precision

=item Field scale

=item Identity field (1 if true)

=item Nullable field (1 if true)

=back

=head2 Primary Key Descriptor

A primary key descriptor lists the primary key for a table and the
fields which comprise the primary key.  It contains the following (tab
delimited) elements:

=over 4

=item Type = 'PK'

=item Name of object having primary key

=item Object type ('User Table' or 'System Table')

=item Database

=item Owner (default is 'dbo')

=item Object (table)

=item Primary Key field

=item Position in primary key

=item Primary Key name (optional)

=head2 Foreign Key Descriptor

A foreign key descriptor lists the foreign key relationships for a
table.  Each descriptor pairs a primary key field name of one table
with the corresponding foreign key field name of another table.  It
also gives the position each of those fields within the primary and
foreign key tuples.  It contains the following (tab delimited)
elements:

=over 4

=item Type = 'FK'

=item Object type ('User Table' or 'System Table')

=item Database

=item Owner (default is 'dbo')

=item Primary Key Object (table)

=item Primary Key field

=item Database

=item Owner (default is 'dbo')

=item Foreign Key Object (table)

=item Foreign Key field

=item Foreign key field position in tuple

=item Update rule number -- always 1, if present

=item Delete rule number -- always 1, if present

=item Foreign Key name (Optional)

=item Primary Key name (Optional)

=back

=head2 Index Descriptors

An index descriptor lists the indexes for a table and the
fields which comprise that index.  It contains the following (tab
delimited) elements (blank lines follow each set of indexes for a table):

=over 4

=item Type = 'I'

=item Index Object (table)

=item Index Object type ('User Table' or 'System Table')

=item Index Name

=item Index description

=item Comma seperated, ordered index field list

=back

=head2 Comments (and stored procedure definitions) Descriptors

A comment (or definition) descriptor contains the following (tab delimited) elements:

=over 4

=item Type = 'C'

=item Object

=item Object Type is one of: 'User Table', 'System Table', 'View', 'Procedure'

=item Comment or definition (carriage returns replace newlines and tabs are replaced by five spaces

=back

=head1 Example Script

  #!/usr/local/bin/perl
  
  use RDBAL
  use RDBAL::Schema;
  
  $server   = shift;
  $database = shift;
  $username = shift;
  $password = shift;
  
  # Check to see if we want to use a different name for the server
  if ($RDBAL::Layer{'SybaseDBlib'} || $RDBAL::Layer{'ApacheSybaseDBlib'}) {
      $server = 'sybase_sql';
  } else {
      $server = 'odbc_sql';
  }
  if (!defined($server) ||
      !defined($database) ||
      !defined($username) ||
      !defined($password)) {
      die "Usage is: get_schema.pl server database username password\n";
  }
  
  # Get connnection to database server
  ( $X = RDBAL::Connect($username,$password,$server)
   or (die "Failed to connect to $server $username"));
  
  $schema = new RDBAL::Schema($X,$database, -get_system => 1);
  
  $, = "\t";
  print "Info for database: " . $schema->Database() . "\n";
  print "User Tables:\n";
  map {
      $table = $_;
      print "\tTable: $table\n";
      map {
  	print "\t\t". $_ . (($schema->Primary_Key($table,$_)) ? '*' : ''),
  	$schema->Field_Type($table,$_),
  	$schema->Field_Length($table,$_),
  	$schema->Field_Precision($table,$_),
  	$schema->Field_Scale($table,$_),
  	(($schema->Field_Identity($table,$_)) ? 'Identity' : ''),
  	(($schema->Field_Null($table,$_)) ? 'NULL' : 'NONNULL')
  	  . "\n";
      } $schema->Table_Fields($table);
      print "\t\tPrimary keys:", $schema->Primary_Keys($table,'User Table'),"\n";
      map {
  	@keys = split(',',$_);
  	print "\t\tIndex keys:", @keys ,"\n";
      } $schema->Keys($table,'User Table');
      map {
  	($index_name, $index_description, $keys) = split("\t",$_);
  	print "\t\tIndexes:\t$index_name\t$keys\t$index_description\n";
      } $schema->Indexes($table,'User Table');
      print "\t\tComments:", $schema->Comments($table,'User Table'), "\n";
      map {
  	print "\t\tParents: $_ (Reverse)", $schema->Relation($_,$table),"\n";
      } $schema->Parents($table);
      map {
  	print "\t\tChildren: $_", $schema->Relation($table,$_),"\n";
      } $schema->Children($table);
  } $schema->User_Tables();
  
  print "System Tables:\n";
  map {
      $table = $_;
      print "\tTable: $table\n";
      map {
  	print "\t\t". $_ . (($schema->Primary_Key($table,$_,'System Table')) ? '*' : ''),
  	$schema->Field_Type($table,$_,'System Table'),
  	$schema->Field_Length($table,$_,'System Table'),
  	$schema->Field_Precision($table,$_,'System Table'),
  	$schema->Field_Scale($table,$_,'System Table'),
  	(($schema->Field_Identity($table,$_,'System Table')) ? 'Identity' : ''),
  	(($schema->Field_Null($table,$_,'System Table')) ? 'NULL' : 'NONNULL')
  	    . "\n";
      } $schema->System_Table_Fields($table);
      print "\t\tComments:", $schema->Comments($table,'System Table'), "\n";
  } $schema->System_Tables();
  
  print "Views:\n";
  map {
      $table = $_;
      print "\tView: $table (Tables:", $schema->View_Tables($_), ")\n";
      map {
  	print "\t\t". $_,
  	$schema->Field_Type($table,$_,'View'),
  	$schema->Field_Length($table,$_,'View'),
  	$schema->Field_Precision($table,$_,'View'),
  	$schema->Field_Scale($table,$_,'View'),
  	(($schema->Field_Null($table,$_,'View')) ? 'NULL' : 'NONNULL')
  	  . "\n";
      } $schema->View_Fields($table);
      print "\tComments:", $schema->Comments($table,'View'), "\n";
  } $schema->Views();
  
  print "Procedures:\n";
  map {
      $table = $_;
      print "\tProcedure: $table\n";
      map {
  	print "\t\t". $_,
  	$schema->Field_Type($table,$_,'Procedure'),
  	$schema->Field_Length($table,$_,'Procedure'),
  	$schema->Field_Precision($table,$_,'Procedure'),
  	$schema->Field_Scale($table,$_,'Procedure'),
  	(($schema->Field_Null($table,$_,'Procedure')) ? 'NULL' : 'NONNULL')
  	 . "\n";
      } $schema->Procedure_Parameters($table);
      print "\tComments:", $schema->Comments($table,'Procedure'), "\n";
  } $schema->Procedures();


=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.

A small script which yields the problem will probably be of help.  If you
cannot include a small script then please include a Debug trace from a
run of your program which does yield the problem.

=head1 AUTHOR INFORMATION

Brian H. Dunford-Shore   brian@ibc.wustl.edu

Copyright 1998, Washington University School of Medicine,
Institute for Biomedical Computing.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

Address bug reports and comments to:
www@ibc.wustl.edu

=head1 TODO

These are features that would be nice to have and might even happen someday (especially if YOU write it).

=over 4

=item Other types of database servers:

(mSQL, mySQL, etc.).

=back

=head1 SEE ALSO

B<RDBAL> -- http://www.ibc.wustl.edu/perl5/other/RDBAL.html

B<Sybase::DBlib> -- http://www.ibc.wustl.edu/perl5/other/sybperl.html

B<Win32::odbc> -- http://www.ibc.wustl.edu/perl5/other/Win32/odbc.html

=head1 CREDITS

Thanks very much to:

B<David J. States> (states@ibc.wustl.edu)

     for suggestions and bug fixes.

=head1 BUGS

You really mean 'extra' features ;).  None known.

=head1 COPYRIGHT

Copyright (c) 1997, 1998, 1999 Washington University, St. Louis,
Missouri. All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
