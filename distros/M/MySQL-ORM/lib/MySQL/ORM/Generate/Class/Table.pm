package MySQL::ORM::Generate::Class::Table;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use List::MoreUtils qw(uniq);
use MySQL::Util::Lite;
use MySQL::ORM::Generate::Class::ResultClass;
use MySQL::ORM::Generate::Class::ResultClassX;
use MySQL::ORM::Generate::Class::CustomRole;
use SQL::Beautify;
use Text::Trim 'trim';

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

has db_class_name => (
	is       => 'ro',
	isa      => 'Str',
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
# optional attributes
##############################################################################

##############################################################################
# private attributes
##############################################################################

has _result_class => (
	is      => 'rw',
	isa     => 'MySQL::ORM::Generate::Class::ResultClass',
	lazy    => 1,
	builder => '_build_result_class',
);

has _result_class_x => (
	is      => 'rw',
	isa     => 'MySQL::ORM::Generate::Class::ResultClassX',
	lazy    => 1,
	builder => '_build_result_class_x',
);

has _custom_role => (
	is      => 'rw',
	isa     => 'MySQL::ORM::Generate::Class::CustomRole',
	lazy    => 1,
	builder => '_build_custom_role',
);

##############################################################################
# methods
##############################################################################

method generate {

	$self->trace;

	my @attr;
	push @attr,
	  my $text = $self->attribute_maker->make_attribute(
		name        => 'table_name',
		is          => 'ro',
		isa         => 'Str',
		no_init_arg => 1,
		default     => sprintf( "'%s'", $self->table->name ),
	  );

	$self->writer->write_class(
		file_name  => $self->get_module_path,
		class_name => $self->get_class_name,
		attribs    => \@attr,
		use        => $self->_get_use_modules,
		extends    => ['MySQL::ORM'],
		with       => [ $self->_custom_role->get_role_name ],
		methods    => $self->_get_methods,
	);

	$self->_result_class->generate;
	$self->_result_class_x->generate;
	$self->_custom_role->generate;
}

method get_class_name {

	my @ns;
	push @ns, $self->db_class_name;
	push @ns, $self->camelize( $self->table->name );

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

method _get_use_modules {

	my @use = (
		'Modern::Perl',         'Moose',
		'namespace::autoclean', 'Method::Signatures',
		"Data::Printer alias => 'pdump'"
	);

	push @use, $self->_result_class->get_class_name;

	if ( $self->table->has_parents ) {
		push @use, $self->_result_class_x->get_class_name;
	}

	return \@use;
}

method _get_methods {

	my @methods;
	push @methods, $self->_get_method_select;
	push @methods, $self->_get_method_select_one;
	push @methods, $self->_get_method_selectx;
	push @methods, $self->_get_method_selectx_one;
	push @methods, $self->_get_method_get_id;
	push @methods, $self->_get_method_insert;
	push @methods, $self->_get_method_update;
	push @methods, $self->_get_method_upsert;
	push @methods, $self->_get_method_delete;
	push @methods, $self->_get_method_is_pk_autoinc;

	return \@methods;
}

method _get_method_is_pk_autoinc {

	my $bool = 0;

	my $pk = $self->table->get_primary_key;
	if ( $pk and $pk->is_autoinc ) {
		$bool = 1;
	}

	my $body = "return $bool;";

	return $self->method_maker->make_method(
		name => 'is_primary_key_autoinc',
		body => $body
	);
}

method _get_method_delete {

	my $body .= q{
    	my %a = @_;
    	my %w;

    	foreach my $arg (keys %a) {
       		$w{$arg} = $a{$arg}; 
    	}
	    
    	my $ret = $self->SUPER::delete(
    		table  => $self->table_name,
    		where => \%w
    	);
    	
    	if (defined $ret) {
    		# convert 0E0 to zero if necessary	
    		return int($ret);
    	}
    	
    	return;
	};

	return $self->method_maker->make_method(
		name => 'delete',
		sig  => $self->_get_method_sig,
		body => $body
	);
}

method _get_method_upsert {

	my $body .= q{
    	my %a = @_;
    	my %v;

    	foreach my $arg (keys %a) {
       		$v{$arg} = $a{$arg}; 
    	}
	    
    	my $ret = $self->SUPER::upsert(
    		table  => $self->table_name,
    		values => \%v
    	);
    	
    	if (defined $ret) {
    		# convert 0E0 to zero if necessary	
    		return int($ret);
    	}
    	
    	return;
	};

	return $self->method_maker->make_method(
		name => 'upsert',
		sig  => $self->_get_method_sig( exclude_autoinc => 1 ),
		body => $body
	);
}

method _get_method_update {

	my $sig = sprintf( '%s :$set,', $self->_result_class->get_class_name );
	$sig .= "\n";
	$sig .= $self->_get_method_sig;

	my $body .= q{
    	my %a = @_;
    	my %where;

    	foreach my $arg (keys %a) {
    	   	next if $arg eq 'set';
       		$where{$arg} = $a{$arg}; 
    	}
	    
	    my %values;
    	my @attrs = $set->get_touched_attributes;
    	foreach my $attr (@attrs) {
        	$values{$attr} = $set->$attr;
    	}
    	
    	my $ret = $self->SUPER::update(
    		table  => $self->table_name,
    		values => \%values,
    		where  => \%where
    	);
    	
    	if (defined $ret) {
    		# convert 0E0 to zero if necessary	
    		return int($ret);
    	}
    	
    	return;
	};

	return $self->method_maker->make_method(
		name => 'update',
		sig  => $sig,
		body => $body
	);
}

method _get_method_insert {

	my $body .= q{
    	my %a = @_;
    	my %v;

    	foreach my $arg (keys %a) {
       		$v{$arg} = $a{$arg}; 
    	}
	    
    	my $ret = $self->SUPER::insert(
    		table  => $self->table_name,
    		values => \%v
    	);
    	
    	if (defined $ret) {
    		# convert 0E0 to zero if necessary	
    		return int($ret);
    	}
    	
    	return;
	};

	return $self->method_maker->make_method(
		name => 'insert',
		sig  => $self->_get_method_sig( exclude_autoinc => 1 ),
		body => $body
	);
}

method _get_method_selectx_one {

	if ( !$self->table->has_parents ) {
		return '';
	}

	my $body = q{
		my @rows = $self->selectx(@_);	
		if (@rows) {
			return shift @rows;			
		}
			
		return;
	};

	return $self->method_maker->make_method(
		name => 'selectx_one',
		sig  => $self->_get_method_sigx,
		body => $body
	);
}

method _merge_sig_types (ArrayRef :$sig!) {

	# for cases where you have nullable foreign keys in one table, but they 
	# are required fields in the parent table
	
	# example:
	#   Num|HashRef|Undef :$foo_id,
    #   Num|HashRef       :$foo_id,
   	
   	my %cols;
   	 
	foreach my $param (@$sig) {
		$param = trim $param;
		my ($type, $colname) = split(/\s+/, $param);	
		
		my @types = split(/\|/, $type);	
		push @{ $cols{$colname} }, @types;
	}		
	
	my @sig;
		
	foreach my $col (sort keys %cols) {
		my @types = @{ $cols{$col} };
		my @uniq_types = uniq @types;		
		push @sig, sprintf("    %s %s", join('|', sort @uniq_types), $col);
	}	
	
	return @sig;
}

method _sort_sig (ArrayRef :$sig!) {

	# sort signature
	
	# example:
	#   Num|HashRef|Undef :$foo_id,
    #   Num|HashRef       :$foo_id,
   	
   	sub _by_param {
   	    $a =~ /:\$(\w+)/;
   	    my $left_param = $1;
   	    
   	    $b =~ /:\$(\w+)/;
   	    my $right_param = $1;
   	    
   	    $left_param cmp $right_param;
   	}
   	
   	@$sig = sort _by_param @$sig;
   	
   	return @$sig;
}

method _get_method_sigx (Bool :$exclude_autoinc = 0,
						 Bool :$want_order_by = 0) {

	my @sig = $self->_get_method_sig_array(
		exclude_autoinc => $exclude_autoinc,
		want_order_by   => 0
	);

	foreach my $table ( $self->table->get_parent_tables ) {
		push @sig,
		  $self->_get_method_sig_array(
			table           => $table,
			exclude_autoinc => $exclude_autoinc
		  );
	}

	@sig = uniq @sig;
	@sig = $self->_merge_sig_types(sig => \@sig);
	@sig = $self->_sort_sig(sig => \@sig);
	
	my $left_join = sprintf '    %s :%s%s', 'Bool', '$', 'left_join';
	push @sig, $left_join;

	if ($want_order_by) {
		my $line = sprintf '    %s :%s%s', 'ArrayRef', '$', 'order_by';
		push @sig, $line;
	}

	return join( ",\n", @sig );
}

method _get_table2alias_map {

	my $num = 1;

	my %map;

	$map{ $self->table->get_fq_name } = 't' . $num;
	#$map{ $self->table->name } = 't' . $num;
	$num++;

	foreach my $t ( $self->table->get_parent_tables ) {

		$map{ $t->get_fq_name } = 't' . $num;
		#$map{ $t->name } = 't' . $num;

		$num++;
	}

	return %map;
}

method _get_method_selectx {

	if ( !$self->table->has_parents ) {
		return '';
	}

	my %table2alias = $self->_get_table2alias_map;

	my @select;
	my %arg2table;

	foreach my $col ( $self->table->get_columns ) {
		push @select, sprintf( "t1.%s", $col->name );
		$arg2table{ $col->name } = $self->table->get_fq_name;
	}

	foreach my $t ( $self->table->get_parent_tables ) {
		foreach my $c ( $t->get_columns ) {
			if ( !$arg2table{ $c->name } ) {
				push @select, sprintf("%s.%s", $table2alias{$t->get_fq_name}, $c->name);
				$arg2table{ $c->name } = $t->get_fq_name;
			}
		}
	}

	my @from = ( sprintf( '%s %s', $self->table->get_fq_name, 't1' ) );
	#my @from = ( sprintf( '%s %s', $self->table->name, 't1' ) );

	foreach my $fk ( $self->table->get_foreign_keys ) {
		foreach my $con ( $fk->get_column_constraints ) {
		    
		    my $con_parent_fq = $con->parent_schema_name . "." .$con->parent_table_name;

			push @from, 'left join';
			push @from,
			  sprintf(
				"%s %s on (t1.%s = %s.%s)",
				$con_parent_fq,
				$table2alias{ $con_parent_fq },
				$con->column_name,
				$table2alias{ $con_parent_fq },
				$con->parent_column_name,
			  );
		}
	}

	my @body;
	push @body, 'my %table2alias = (';
	foreach my $t ( keys %table2alias ) {
		push @body, sprintf( "'%s' => '%s',", $t, $table2alias{$t} );
	}

	push @body, ');', "\n";

	push @body, 'my %arg2table = (';
	foreach my $key ( sort keys %arg2table ) {
		push @body, sprintf( "%s => '%s',", $key, $arg2table{$key} );
	}

	push @body, ');', "\n";

	my @sql = ( 'select', join( ', ', @select ), 'from', join( "\n", @from ) );

	push @body, 'my $sql = qq{';
	push @body, $self->_sql_beautify( \@sql );
	push @body, '    };';    # perltidy isn't indenting this for some reason

	push @body, q{
			my %a = $self->prune_ddl_args([ @_ ]);
			
			my %where;

			foreach my $arg (keys %a) {
				my $table = $arg2table{$arg};
				my $alias = $table2alias{$table};
				my $col = "$alias.$arg";
				   $where{$col} = $a{$arg}; 
			}		

			my ($where, @bind) = $self->make_where_clause(where => \%where);	
			$sql .= $where;

			if ($order_by) { 
				my @order;
				foreach my $col (@$order_by) {
					my $table = $arg2table{$col};
					my $alias = $table2alias{$table};
					push @order, "$alias.$col";
				}
				$sql.= "order by " . join(', ', @order);
			}
		
			my $sth = $self->dbh->prepare($sql);
			$sth->execute(@bind);

			my @obj;	
	};
	push @body, 'while(my $row = $sth->fetchrow_hashref) {';
	push @body,
	  sprintf( 'push @obj, %s->new(%s);',
		$self->_result_class_x->get_class_name, '%$row' );
	push @body, "}\n";
	push @body, 'return @obj;';

	return $self->method_maker->make_method(
		name => 'selectx',
		sig  => $self->_get_method_sigx( want_order_by => 1 ),
		body => join( "\n", @body )
	);
}

method _sql_beautify (ArrayRef $sql) {

	my $b = SQL::Beautify->new( query => join( "\n", @$sql ) );
	my $pretty = $b->beautify;

	my @indented;
	foreach my $line ( split( /\n/, $pretty ) ) {
		push @indented, "        " . $line;
	}

	return join( "\n", @indented );
}

method _get_method_get_id {

	my $pk = $self->table->get_primary_key;
	if ( $pk and $pk->is_autoinc ) {

		my ($pk_col) = $pk->get_columns;
		if ( $pk_col->name =~ /id$/ ) {

			foreach my $ak ( $self->table->get_alternate_keys ) {

				my %ak_cols;
				foreach my $ak_col ( $ak->get_columns ) {
					$ak_cols{ $ak_col->name } = $ak_col;
				}

				my @ak_cols;
				foreach my $col_name ( keys %ak_cols ) {
					push @ak_cols, $ak_cols{$col_name};
				}

				my $sig = $self->_get_method_sig(
					columns         => \@ak_cols,
					exclude_autoinc => 1
				);

				my $body .= q{
				    	my %a = @_;
				    	my %where;
				
				    	foreach my $arg (keys %a) {
				       		$where{$arg} = $a{$arg}; 
				    	}
					    
				    	my $rows = $self->SUPER::select(
				    		table  => $self->table_name,
				    		where  => \%where
				    	);
				    	
					};
				$body .= 'if (@$rows == 1) {' . "\n";
				$body .= '   my $row = shift @$rows;' . "\n";
				$body .= sprintf 'return $row->{%s};%s', $pk_col->name, "\n";
				$body .= "}\n\n";
				$body .=
				  'confess "too many rows returned" if @$rows > 1;' . "\n\n";
				$body .= 'return;';

				return $self->method_maker->make_method(
					name => 'get_id',
					sig  => $sig,
					body => $body
				);
			}
		}
	}

	return '';
}

method _get_method_sig_array (ArrayRef :$columns = [],
					     	  Bool :$exclude_autoinc = 0, 
						 	  Bool :$want_order_by = 0,
						 	  MySQL::Util::Lite::Table :$table) {

	if ( !$table ) {
		$table = $self->table;
	}

	if ( !@$columns ) {

		foreach my $col ( $table->get_columns ) {
			if ($exclude_autoinc) {
				if ( $col->is_autoinc ) {
					next;
				}
			}

			push @$columns, $col;
		}
	}

	my @sig;
	foreach my $col (@$columns) {

		my $line = sprintf '    %s :%s%s', $col->get_moose_type, '$',
		  $col->name;
		push @sig, $line;
	}
	
	@sig = $self->_sort_sig(sig => \@sig);

	if ($want_order_by) {
		my $line = sprintf '    %s :%s%s', 'ArrayRef', '$', 'order_by';
		push @sig, $line;
	}

	return @sig;
}

method _get_method_sig ( ArrayRef :$columns = [],
					     Bool :$exclude_autoinc = 0, 
						 Bool :$want_order_by = 0) {

	return join( ",\n", $self->_get_method_sig_array(@_) );
}

method _get_method_select {

	my $sig = $self->_get_method_sig( want_order_by => 1 );

	my $body .= q{
    	my %a = @_;
    	my %where;

    	foreach my $arg (keys %a) {
    		next if $arg eq 'order_by';
       		$where{$arg} = $a{$arg}; 
    	}
	   
	    my %s;
	    $s{table} = $self->table_name;
	    $s{where} = \%where;
	    $s{order_by} = $order_by if $order_by;
	     
    	my $rows = $self->SUPER::select(%s);

    	my @obj;
    	foreach my $row (@$rows)
	};
	$body .= '{';
	$body .= sprintf(
		'push @obj, %s->new(%s);%s',
		$self->_result_class->get_class_name,
		'%$row', "\n"
	);
	$body .= "}\n";
	$body .= q{	
    	return @obj;	
	};

	return $self->method_maker->make_method(
		name => 'select',
		sig  => $sig,
		body => $body
	);
}

method _get_method_select_one {

	my $sig = $self->_get_method_sig;

	my $body .= q{
    	my %a = @_;
    	my %where;

    	foreach my $arg (keys %a) {
       		$where{$arg} = $a{$arg}; 
    	}
	    
    	my $row = $self->SUPER::select_one(
    		table  => $self->table_name,
    		where  => \%where
    	);
	};
	$body .= 'if ($row) {';
	$body .= sprintf(
		'return %s->new(%s);%s',
		$self->_result_class->get_class_name,
		'%$row', "\n"
	);
	$body .= "}\n";
	$body .= q{	
    	return;
	};

	return $self->method_maker->make_method(
		name => 'select_one',
		sig  => $sig,
		body => $body
	);
}

method _build_result_class {

	return MySQL::ORM::Generate::Class::ResultClass->new(
		table            => $self->table,
		table_class_name => $self->get_class_name,
		dir              => $self->dir,
	);
}

method _build_result_class_x {

	return MySQL::ORM::Generate::Class::ResultClassX->new(
		table            => $self->table,
		table_class_name => $self->get_class_name,
		dir              => $self->dir,
		extends          => $self->_result_class->get_class_name,
	);
}

method _build_custom_role {

	return MySQL::ORM::Generate::Class::CustomRole->new(
		table_class_name => $self->get_class_name,
		dir              => $self->dir,
	);
}

1;
