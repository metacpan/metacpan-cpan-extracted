package Tangram::Relational::Engine::Class;

use strict;
use Tangram::Schema;

use vars qw(@ISA);
@ISA = qw( Tangram::Schema::Node );
use Carp qw(confess);

sub new {
    bless { }, shift;
}

sub fracture {
    my ($self) = @_;
    delete $self->{BASES};
    delete $self->{SPECS};
}

sub initialize {
    my ($self, $engine, $class, $mapping) = @_;
    ref($self->{CLASS} = $class)
	&& UNIVERSAL::isa($class, "Tangram::Schema::Class")
	    or confess "not class but $class";
    $self->{MAPPING} = $mapping;
    $self->{BASES} = [
		      map { $engine->get_class_engine($_) }
		      $class->get_bases()
		     ];
    $self->{SPECS} = [
		      map { $engine->get_class_engine($_) }
		      $class->get_specs()
		     ];
    $self->{ID_COL} = $engine->{SCHEMA}{sql}{id_col};
}

sub get_instance_select {
    my ($self, $engine) = @_;

    return $self->{INSTANCE_SELECT} ||= do {

	my $schema = $engine->{SCHEMA};
	my $id_col = $schema->{sql}{id_col};

	my $context = {
		       engine => $engine,
		       schema => $schema,
		       layout1 => $engine->{layout1}
		      };

	my (@tables, %seen, @cols, $root);

	$self->for_composing
	    (
	     sub {
		 my ($part) = @_;
		 $root ||= $part;
		 $context->{class} = $part->{CLASS};
		 push @cols,
		     (
		      map {
			  my ($table, $col) = @$_;
			  push @tables, $table unless $seen{$table}++;
			  "$table.$col"
		      }
		      $part->{MAPPING}->get_import_cols($context)
		     );
		 }
	    );

	unless (@tables) {
	    # in case the class has absolutely no state at all...
	    # XXX - not reached by the test suite
	    @cols = $id_col;
	    @tables = $root->{MAPPING}->get_table;
	}

	my $first_table = shift @tables;

	sprintf("SELECT\n    %s\nFROM\n    %s\nWHERE\n    %s",
		join(",\n    ", @cols),
		join(",\n    ", $first_table, @tables),
		join("\tAND\n    ", "$first_table.$id_col = ?",
		     (map { "$first_table.$id_col = $_.$id_col" }
		      @tables)
		    )
	       );
  };
}

sub get_insert_statements {
  my ($self, $engine) = @_;
  return @{ $self->get_save_cache($engine)->{INSERTS} };
}

sub get_insert_fields {
  my ($self, $engine) = @_;
  return @{ $self->get_save_cache($engine)->{INSERT_FIELDS} };
}

sub get_update_statements {
  my ($self, $engine) = @_;
  return @{ $self->get_save_cache($engine)->{UPDATES} };
}

sub get_update_fields {
  my ($self, $engine) = @_;
  return @{ $self->get_save_cache($engine)->{UPDATE_FIELDS} };
}

sub get_save_cache {

    my ($class, $engine) = @_;

    return $class->{SAVE} ||= do {

	my $schema = $engine->{SCHEMA};
	my $id_col = $schema->{sql}{id_col};
	my $type_col = $engine->{TYPE_COL};

	my (%tables, @tables);
	my (@export_sources, @export_closures);

	my $context = { layout1 => $engine->{layout1} };

	my $field_index = 2;

	$class->for_composing
	    (sub {
		 my ($part) = @_;

		 my $table_name =  $part->{MAPPING}{table};
		 my $table = $tables{$table_name}
		     ||= do {
			 push @tables,
			     my $table = [ $table_name, [], [] ];
			 $table
		     };

		 $context->{class} = $part;

		 for my $field ($part->{MAPPING}->get_direct_fields())
		 {
		     my @export_cols =
			 $field->get_export_cols($context);

		     push @{ $table->[1] }, @export_cols;
		     push @{ $table->[2] },
			 $field_index..($field_index + $#export_cols);
		     $field_index += @export_cols;
		 }
	     });

	my (@inserts, @updates, @insert_fields, @update_fields);

	for my $table (@tables) {
	    my ($table_name, $cols, $fields) = @$table;
	    my @meta = ( $id_col );
	    my @meta_fields = ( 0 );

	    if ($engine->{ROOT_TABLES}{$table_name}) {
		push @meta, $type_col;
		push @meta_fields, 1;
	    }

	    next unless @meta > 1 || @$cols;

	    push @inserts, sprintf("INSERT INTO %s\n    (%s)\nVALUES\n    (%s)",
				   $table_name,
				   join(', ', @meta, @$cols),
				   join(', ', ('?') x (@meta + @$cols)));
	    push @insert_fields, [ @meta_fields, @$fields ];

	    if (@$cols) {
		push @updates, sprintf("UPDATE\n    %s\nSET\n%s\nWHERE\n    %s = ?",
				       $table_name,
				       join(",\n", map { "    $_ = ?" } @$cols),
				       $id_col);
		push @update_fields, [ @$fields, 0 ];
	    }
	}

	{
	    INSERT_FIELDS => \@insert_fields, INSERTS => \@inserts,
	    UPDATE_FIELDS => \@update_fields, UPDATES => \@updates,
	}
    };
}

sub get_deletes {

    my ($self, $engine) = @_;

    return @{ $self->{DELETE} ||= do {
	my $schema = $engine->{SCHEMA};
	my $context = {
		       engine => $engine,
		       schema => $schema,
		       layout1 => $engine->{layout1}
		      };
	my (@tables, %seen);

	$self->for_composing
	    (sub {
		 my ($part) = @_;
		 my $mapping = $part->{MAPPING};

		 my $home_table = $mapping->{table};
		 push @tables, $home_table
		     if $mapping->is_root() && !$seen{$home_table}++;

		 $context->{class} = $part->{CLASS};

		 for my $qcol ($mapping->get_export_cols($context)) {
		     my ($table) = @$qcol;
		     push @tables, $table unless $seen{$table}++;
		 }
	     });

	  my $id_col = $engine->{SCHEMA}{sql}{id_col};

	  [ map { "DELETE FROM $_ WHERE $id_col = ?" } @tables ]
      } };
}

sub get_table_set {
    my ($self, $engine) = @_;

    # return the TableSet on which the object's state resides

    # It doesn't include tables resulting solely from an intrusion.
    # Tables that carry only meta-information are also included.

    return $self->{TABLE_SET} ||= do {

	my $mapping = $self->{MAPPING};
	my $home_table = $mapping->{table};
	my $context = {
		       layout1 => $engine->{layout1},
		       class => $self->{CLASS}
		      };

	my @table = map { $_->[0] }
	    $mapping->get_export_cols($context);

	push @table, $home_table
	    if $engine->{ROOT_TABLES}{$home_table};

	Tangram::Relational::TableSet
		->new((map { $_->get_table_set($engine)->tables }
		       $self->direct_bases()), @table );
    };
}

sub get_polymorphic_select {
    my ($self, $engine, $storage) = @_;

    my $selects = $self->{POLYMORPHIC_SELECT} ||= do {

	my $schema = $engine->{SCHEMA};
	my $id_col = $schema->{sql}{id_col};
	my $type_col = $engine->{TYPE_COL};
	my $context = {
		       engine => $engine,
		       schema => $schema,
		       layout1 => $engine->{layout1}
		      };

	my $table_set = $self->get_table_set($engine);
	my %base_tables = do {
	    my $ph = 0; map { $_ => $ph++ } $table_set->tables()
	};

	my %partition;

	$self->for_conforming
	    (sub {
		 my $conforming = shift;
		 my $key = $conforming->get_table_set($engine)->key;
		 push @{ $partition{ $key } }, $conforming
		     unless $conforming->{CLASS}{abstract};
	     });

	my @selects;

	for my $table_set_key (keys %partition) {

	    my $mates = $partition{$table_set_key};
	    my $table_set = $mates->[0]->get_table_set($engine);
	    my @tables = $table_set->tables();

	    my %slice;
	    my %col_index;
	    my $col_mark = 0;
	    my (@cols, @expand);

	    my $root_table = $tables[0];

	    push @cols, qualify($id_col, $root_table,
				\%base_tables, \@expand);
	    push @cols, qualify($type_col, $root_table,
				\%base_tables, \@expand);

	    my %used;
	    $used{$root_table} += 2;

	    for my $mate (@$mates) {
		my @slice;

		$mate->for_composing
		    (sub {
			 my ($composing) = @_;
			 my $table = $composing->{MAPPING}{table};
			 $context->{class} = $composing;
			 my @direct_fields =
			     $composing->{MAPPING}->get_direct_fields();
			 for my $field (@direct_fields) {
			     my @import_cols =
				 $field->get_import_cols($context);

			     $used{$table} += @import_cols;

			     for my $col (@import_cols) {
				 my $qualified_col = "$table.$col";
				 unless (exists $col_index{$qualified_col}) {
				     push @cols, qualify($col, $table,
							 \%base_tables,
							 \@expand);
				     $col_index{$qualified_col} = $col_mark++;
				 }

				 push @slice, $col_index{$qualified_col};
			     }
			 }
		     });

		$slice{ $storage->{class2id}{$mate->{CLASS}{name}}
			|| $mate->{MAPPING}{id} }
		    = \@slice; # should be $mate->{id} (compat)
	    }

	    my @from;

	    for my $table (@tables) {
		next unless $used{$table};
		if (exists $base_tables{$table}) {
		    push @expand, $base_tables{$table};
		    push @from, "$table t%d";
		} else {
		    push @from, $table;
		}
	    }

	    my @where =
		(map {
		    (qualify($id_col, $root_table, \%base_tables,
			     \@expand)
		     . ' = '
		     . qualify($id_col, $_, \%base_tables, \@expand) )
		}
		 grep { $used{$_} }
		 @tables[1..$#tables]
		);

	    unless ( ($storage->{compat} and $storage->{compat} le "2.08")
		     or
		     @$mates == $engine->get_heterogeneity($table_set))
	    {
		my @type_ids = (map {
		    # try $storage first for compatibility
		    # with layout1
		    $storage->{class2id}{$_->{CLASS}{name}}
			or $_->{MAPPING}{id}
		    } @$mates);

		my $column = qualify($type_col, $root_table, \%base_tables,
				     \@expand);
		if ( @type_ids == 1 ) {
		    push @where, "$column = @type_ids";
		} else {
		    push @where, "$column IN (". (join ', ', @type_ids). ")";
		}
	    }

	    push @selects,
		Tangram::Relational::PolySelectTemplate
			->new(\@expand, \@cols, \@from, \@where,
			      \%slice);
	  }

	\@selects;
    };

    return @$selects;
}

sub qualify {
    my ($col, $table, $ph, $expand) = @_;

    if (exists $ph->{$table}) {
	push @$expand, $ph->{$table};
	return "t%d.$col";
    } else {
	return "$table.$col";
    }
}

# XXX - never reached (?)
sub get_exporter {
    my ($self, $context) = @_;

    return $self->{EXPORTER} ||= do {

	my (@export_sources, @export_closures);

	$self->for_composing
	    (sub {
		 my ($composing) = @_;

		 my $class = $composing->{CLASS};
		 $context->{class} = $class;

		 for my $field ($composing->{MAPPING}->get_direct_fields()) {
		     if (my $exporter = $field->get_exporter($context)) {
			 if (ref $exporter) {
			     push @export_closures, $exporter;
			     push @export_sources,
				 'shift(@closures)->($obj, $context)';
			 } else {
			     push @export_sources, $exporter;
			 }
		     }
		 }
	     });

	my $export_source = join ",\n", @export_sources;
	my $copy_closures =
	    ( @export_closures ? ' my @closures = @export_closures;' : '' );

	$export_source = ("sub { my (\$obj, \$context) = \@_;"
			  ."$copy_closures\n$export_source }");

	print $Tangram::TRACE ("Compiling exporter for $self->{name}..."
			       ."\n$export_source\n")
	    if $Tangram::TRACE;

	eval $export_source or die;
    }
}

# XXX - never reached (?)
sub get_importer {
  my ($self, $context) = @_;

  return $self->{IMPORTER} ||= do {
	my (@import_sources, @import_closures);

	$self->for_composing
	    (
	     sub {
		 my ($composing) = @_;

		 my $class = $composing->{CLASS};
		 $context->{class} = $class;

		 for my $field ($composing->{MAPPING}->get_direct_fields()) {

		     my $importer = $field->get_importer($context)
			 or next;

		     if (ref $importer) {
			 push @import_closures, $importer;
			 push @import_sources,
			     'shift(@closures)->($obj, $row, $context)';
		     } else {
			 push @import_sources, $importer;
		     }
		 }
	     } );

	my $import_source = join ";\n", @import_sources;
	my $copy_closures = 
	    ( @import_closures
	      ? ' my @closures = @import_closures;'
	      : '' );

	# $Tangram::TRACE = \*STDOUT;

	$import_source = ("sub { my (\$obj, \$row, \$context) = \@_;"
			  ."$copy_closures\n$import_source }");

	print $Tangram::TRACE ("Compiling importer for $self->{name}:"
			       ."\n$import_source\n")
	  if $Tangram::TRACE;

	# use Data::Dumper; print Dumper \@cols;
	eval $import_source or die;
  };
}

1;
