package SPOPSx::Ginsu;

use strict;
use vars qw($VERSION $Revision);

BEGIN {
	$Revision = sprintf "%d.%03d", q$Revision: 1.60 $ =~ /: (\d+)\.(\d+)/;
	$VERSION = '0.58';
}

use base qw( SPOPSx::Ginsu::DBI );
use SPOPSx::Ginsu::DBI;
use SPOPS::ClassFactory;
use SPOPS::DBI;
use DBI qw( :sql_types );
use Log::Log4perl    qw( get_logger );

my $log = get_logger();

sub ROOT_OBJ_CLASS { die "Must be overridden by a root base class."; }

sub e_has_a { return { }; }

##-----  Public Class Methods  -----
sub new {
    my $class = shift;
    my $p     = shift;
# 	my $self = $class->SUPER::new($p);
	
	## Since SUPER::new($p) ignores keys in $p that are defined as fields
	## in the CONFIG of a parent object, we have to do the assigning of
	## these parameters manually (or fix SPOPS to handle this internally).
	my $self = $class->SUPER::new;
	
	foreach my $field ( @{$class->all_fields} ) {
	    $self->{$field} = defined $p->{$field} ? $p->{$field} : undef;
	}
	
	$self->{class} = ref($self);

	return $self;
}

sub isa_classes {
	my $self	= shift;
	my $isa		= $self->_isa_classes;
	
	return [ sort { $isa->{$a} <=> $isa->{$b} } keys %$isa ];
}

sub inherited_fields {
	my $class	= shift;
	$class = ref($class)	if ref($class);	## get class if passed an object
	
	my $fields = [];
	foreach my $c ( @{$class->isa_classes} ) {
		next if $c eq $class;
		foreach my $field ( @{$c->field_list} ) {
			push @$fields, $field	unless $field eq $c->id_field;
		}
	}

	return $fields;
}

sub all_fields { return [ @{$_[0]->field_list}, @{$_[0]->inherited_fields} ]; }

sub all_field_types {
	my $class	= shift;
	my $p		= shift;
	$class = ref($class)	if ref($class);	## get class if passed an object
	
	my $type_info = {};
	foreach my $c ( @{$class->isa_classes} ) {
		my $c_types = { $c->db_discover_types( $c->base_table, $p )->as_hash };
		foreach my $field ( @{$c->field_list} ) {
			$type_info->{$field} = $c_types->{$field}
				unless $field eq $c->id_field && $c ne $class; ## skip parent table ids
		}
	}

	return $type_info;
}

sub config_and_init {
	my $class = shift;
	
	SPOPS::ClassFactory->create( $class->_build_conf )
		unless $class->_config_processed; 

	$class->class_initialize;
}

## copied straight from SPOPS::DBI, with the modifications as noted
sub fetch {
    my ( $class, $id, $p ) = @_;
    $p ||= {};

    $log->is_debug &&
        $log->debug( "Trying to fetch an item of $class with ID $id and params ",
                     join( " // ", map { sprintf( "%s -> %s", $_, defined $p->{$_} ? $p->{$_} : '' )  }
                                        grep { defined $_ } keys %{ $p } ) );

    # No ID, no object

    return undef  unless ( defined( $id ) and $id ne '' and $id !~ /^tmp/ );

    # Security violations bubble up to caller

    my $level = $p->{security_level};
    unless ( $p->{skip_security} ) {
        $level ||= $class->check_action_security({ id       => $id,
                                                   required => SPOPS::Secure::SEC_LEVEL_READ });
    }

    # Do any actions the class wants before fetching -- note that if
    # any of the actions returns undef (false), we bail.

    return undef unless ( $class->pre_fetch_action( { %{ $p }, id => $id } ) );

    my $obj = undef;

    # If we were passed the data for an object, go ahead and create
    # it; if not, check to see if we can whip up a cached object

    if ( ref $p->{data} eq 'HASH' ) {
        $obj = $class->new({ %{ $p->{data} }, skip_default_values => 1 });
    }
    else {
        $obj = $class->get_cached_object({ %{ $p }, id => $id });
        $p->{skip_cache}++;         # Set so we don't re-cache it later
    }

    unless ( ref $obj eq $class ) {
##-----  REPLACE THIS ORIGINAL CODE  -----
#         my ( $raw_fields, $select_fields ) = $class->_fetch_select_fields( $p );
##-----  WITH THIS OVERRIDING CODE  -----
		## Note: this code skips the column group and alter field stuff
		my $table_name		= $class->base_table;
		my $my_id_field		= $class->id_field;
		my $raw_fields		= [];
		my $select_fields	= [];
		my $sqltables		= [];
		my $sqlwhere		= [];
		foreach my $parent_class ( @{$class->isa_classes} ) {
			my $table		= $parent_class->table_name;
			my $id_field	= $parent_class->id_field;

			push @$sqltables, $table;	## list of tables for "FROM" clause
	
			## join tables by id field (set all equal to id field of this class)
			push @$sqlwhere,	$table . '.' . $id_field . ' = ' .
								$table_name . '.' . $my_id_field
									unless($table_name eq $table);
	
			## all fields, except id of inherited tables
			foreach my $field ( keys %{$parent_class->field} ) {
				next if $parent_class ne $class && $field eq $id_field;
				push @$select_fields, $table . '.' . $field;
				push @$raw_fields, $field;
			}
		}
		push @$sqlwhere, $class->id_clause( $id, undef, $p );
##-----  END OVERRIDING CODE  -----
        $log->is_info &&
            $log->info( "SELECTing: ", join( "//", @{ $select_fields } ) );

        # Put all the arguments into a hash (so we can reuse them simply
        # later) and grab the record

##-----  REPLACE THIS ORIGINAL CODE  -----
#         my %args = (
#             from   => [ $class->table_name ],
#             select => $select_fields,
#             where  => $class->id_clause( $id, undef, $p ),
##-----  WITH THIS OVERRIDING CODE  -----
		my %args = (
			from   => $sqltables,
			select => $select_fields,
			where  => join(' AND ', @$sqlwhere),
##-----  END OVERRIDING CODE  -----
			db     => $p->{db},
			return => 'single',
        );
        my $row = eval { $class->db_select( \%args ) };
        if ( $@ ) {
            $class->fail_fetch( \%args );
            die $@;
        }

        # If the row isn't found, return nothing; just as if an incorrect
        # (or nonexistent) ID were passed in

        return undef unless ( $row );

        # Note that we pass $p along to the ->new() method, in case
        # other information was passed in needed by it -- however, we
        # need to be careful that certain parameters used by this
        # method (e.g., the optional 'field_alter') is not the same as
        # a parameter of an object -- THAT would be fun to debug...

        $obj = $class->new({ id => $id, skip_default_values => 1, %{ $p } });
        $obj->_fetch_assign_row( $raw_fields, $row, $p );
    }
    return $obj->_fetch_post_process( $p, $level );
}

## copied straight from SPOPS::DBI, with the modifications as noted
sub fetch_group {
    my ( $class, $p ) = @_;
##-----  REPLACE THIS ORIGINAL CODE  -----
#     ( $p->{raw_fields}, $p->{select} ) = $class->_construct_group_select( $p );
##-----  WITH THIS OVERRIDING CODE  -----
	## Note: this code skips the column group and alter field stuff
	my $table_name = $class->table_name;
	my $p_original = $p ? { %$p } : {};
	my $my_id_field		= $class->id_field;
	my $raw_fields		= [];
	my $select_fields	= [];
	my $sqltables		= [];
	my $sqlwhere		= [];

	foreach my $parent_class ( @{$class->isa_classes} ) {
		my $table		= $parent_class->table_name;
		my $id_field	= $parent_class->id_field;

		push @$sqltables, $table;	## list of tables for "FROM" clause

		## join tables by id field (set all equal to id field of this class)
		push @$sqlwhere,	$table . '.' . $id_field . ' = ' .
							$table_name . '.' . $my_id_field
								unless($table_name eq $table);

		## all fields, except id of inherited tables
		foreach my $field ( keys %{$parent_class->field} ) {
			next if $parent_class ne $class && $field eq $id_field;
			push @$select_fields, $table . '.' . $field;
			push @$raw_fields, $field;
		}
	}

	## original table list and WHERE clause
	push @$sqltables, @{ $p->{from} }	if $p->{from};
	push @$sqlwhere, $p->{where}		if $p->{where};

	$p->{where}			= join(' AND ', @$sqlwhere);
	$p->{from}   		= $sqltables;
	$p->{select} 		= $select_fields;
	$p->{raw_fields}	= $raw_fields;

	## get indices into rows of class name and object id
	my ($classname_idx) = grep $raw_fields->[$_] eq 'class', (0..$#{$raw_fields});
	my ($id_field_idx)  = grep $raw_fields->[$_] eq $class->id_field, (0..$#{$raw_fields});
##-----  END OVERRIDING CODE  -----
    my $sth              = $class->_execute_multiple_record_query( $p );
    my ( $offset, $max ) = SPOPS::Utility->determine_limit( $p->{limit} );
    my @obj_list = ();

    my $row_count = 0;
ROW:
    while ( my $row = $sth->fetchrow_arrayref ) {
##-----  BEGIN ADDITIONAL CODE  -----
		my $newclass = $row->[ $classname_idx ];
		if ($newclass eq $class) {
##-----  END ADDITIONAL CODE  -----
        my $obj = $class->new({ skip_default_values => 1 });
        $obj->_fetch_assign_row( $p->{raw_fields}, $row, $p );

        next ROW unless ( $obj ); # How could this ever be true?

        # Check security on the row unless overridden by
        # 'skip_security'. If the security check fails that's ok, just
        # skip the row and move on

        my $sec_level = SPOPS::Secure::SEC_LEVEL_WRITE;
        unless ( $p->{skip_security} ) {
            $log->is_debug &&
                $log->debug( "Checking security for [", ref( $obj ), ": ", $obj->id, "]" );
            $sec_level = eval {
                $obj->check_action_security({ required => SPOPS::Secure::SEC_LEVEL_READ })
            };
            if ( $@ ) {
                $log->is_info &&
                    $log->info( "Security check for object in ",
                                          "fetch_group() failed, skipping." );
                next ROW;
            }
        }

        # Not to the offset yet, so go to the next row but still increment
        # the counter so we calculate limits properly

        if ( $offset and ( $row_count < $offset ) ) {
            $row_count++;
            next ROW;
        }
        last ROW if ( $max and ( $row_count >= $max ) );
        $row_count++;

        # If we've made it down to here, we're home free; just call the
        # post_fetch callback

        next ROW unless ( $obj->_fetch_post_process( $p, $sec_level ) );
        push @obj_list, $obj;
##-----  BEGIN ADDITIONAL CODE  -----
		} else {
			next ROW unless UNIVERSAL::isa($newclass, $class);
			my $obj = $newclass->fetch( $row->[ $id_field_idx ], $p_original);
        next ROW unless ( $obj );

		## deleted security check (done by fetch)

        # Not to the offset yet, so go to the next row but still increment
        # the counter so we calculate limits properly

        if ( $offset and ( $row_count < $offset ) ) {
            $row_count++;
            next ROW;
        }
        last ROW if ( $max and ( $row_count >= $max ) );
        $row_count++;

		## deleted _post_fetch_process (done by fetch)
        push @obj_list, $obj;
		}
##-----  END ADDITIONAL CODE  -----
    }
    $sth->finish;
    return \@obj_list;
}

## copied straight from SPOPS::DBI, with the modifications as noted
sub fetch_count {
    my ( $class, $p ) = @_;
    my $row_count = 0;
##-----  REPLACE THIS ORIGINAL CODE  -----
#   if ( $p->{skip_security} ) {
#       $p->{select} = [ 'COUNT(*)' ];
#       my $db = $p->{db}
#                || $class->global_datasource_handle( $p->{connect_key} );
#       my $row_count_rec = eval {
#           $class->db_select({ select => [ 'COUNT(*)' ],
#                               where  => $p->{where},
#                               value  => $p->{value},
#                               from   => $class->table_name,
#                               return => 'single',
#                               db     => $db })
#       };
#       $row_count = $row_count_rec->[0];
#       if ( $@ ) {
#           $log->warn( "Caught error running SELECT COUNT(*): $@" );
#       }
#   }
#   else {
#       $p->{select} = [ $class->id_field_select( $p ) ];
##-----  WITH THIS OVERRIDING CODE  -----
		## should be fine if the class has a table,
		## except we can't use inherited fields in WHERE clause
		## without doing explicit join
		return $class->SUPER::fetch_count($p) if $class->_config_processed;
	
		my $obj_table = $class->ROOT_OBJ_CLASS->table_name;
		my $my_table  = $class->table_name;
		$p->{select} = [ $class->id_field_select( $p ), "$obj_table.class" ];
		if ($my_table ne $obj_table) {
			push @{$p->{from}}, $obj_table;
			my @where = $obj_table . '.' . $class->ROOT_OBJ_CLASS->id_field . ' = ' .
						$my_table . '.' . $class->id_field;
			push @where, $p->{where}	if $p->{where};
			$p->{where} = join(' AND ', @where);
		}
##-----  END OVERRIDING CODE  -----
        my $sth = $class->_execute_multiple_record_query( $p );
        while ( my $row = $sth->fetch ) {
            eval {
                $class->check_action_security({ id       => $row->[0],
                                                required => SPOPS::Secure::SEC_LEVEL_READ })
            };
            next if ( $@ );
##-----  BEGIN ADDITIONAL CODE  -----
			next unless UNIVERSAL::isa($row->[1], $class);
##-----  END ADDITIONAL CODE  -----
            $row_count++;
        }
##-----  BEGIN REMOVE CODE  -----
#     }
##-----  END REMOVE CODE  -----
    return $row_count;
}

sub pm_fetch {
	my ( $class, $id, $p ) = @_;

	$p->{where} = $class->id_clause( $id );
	my $obj = $class->fetch_group( $p )->[0];

	return $obj;
}

sub fetch_group_by_field {
	my ( $class, $field, $vals, $p ) = @_;
	return []	unless @$vals;

	my $where = $class->base_table . ".$field" .
				' IN (' . join(',', map('?', @$vals)) . ')';
	$where .= ' AND (' . $p->{where} . ')'	if $p->{where}; 
	$p->{where} = $where;
	unshift @{$p->{value}}, @$vals;

	my $objs = $class->fetch_group( $p );

	return $objs;
}

sub fetch_group_by_ids {
	my ( $class, $ids, $p ) = @_;

	my $unordered = $class->fetch_group_by_field( $class->id_field, $ids, $p );
	
	## order by id list
	my %obj_by_id	= map { $_->id => $_ } @$unordered;
	my @ordered		= grep { $_ } map { $obj_by_id{$_} } @$ids;

	return \@ordered;
}

##-----  Public Object Methods  -----
## copied straight from SPOPS::DBI, with the modifications as noted
sub save {
    my ( $self, $p ) = @_;
    $log->is_info &&
        $log->info( "Trying to save a (", ref $self, ")" );

    # We can force save() to be an INSERT by passing in a true value
    # for the is_add parameter; otherwise, we rely on the flag within
    # SPOPS::Tie to reflect whether an object has been saved or not.

    my $is_add = ( $p->{is_add} or ! $self->saved );

    # If this is an update and it hasn't changed, we don't need to do
    # anything.

    unless ( $is_add or $self->changed ) {
        $log->is_info &&
            $log->info( "This object exists and has not changed. Exiting." );
        return $self;
    }

    # Check security for create/update

    my $action = ( $is_add ) ? 'create' : 'update';
    my ( $level );
    unless ( $p->{skip_security} ) {
        $level = $self->check_action_security({ required => SPOPS::Secure::SEC_LEVEL_WRITE,
                                                is_add   => $is_add });
    }
    $log->is_info &&
        $log->info( "Security check passed ok. Continuing." );

    # Callback for objects to do something before they're saved

    return undef unless ( $self->pre_save_action({ %{ $p },
                                                   is_add => $is_add }) );

##-----  BEGIN ADDITIONAL CODE  -----
	## get list of classes which need to be saved
	## (put ROOT_OBJ_CLASS first, and this class last)
	my $no_insert = $p->{no_insert};	## this gets converted to an empty hash
										## which causes problems the 2nd time through
	my @classes = reverse @{ $self->isa_classes };
	foreach my $class (@classes) {
		bless $self, $class;
		$p->{field} = [];
		$p->{value} = [];
		$p->{no_insert} = $no_insert;	
##-----  END ADDITIONAL CODE  -----
    # Do not include these fields in the insert/update at all. Allow
    # user to override even with an empty arrayref.

    my ( %not_included );
    if ( $is_add ) {
        my ( @no_insert_items );
        if ( $p->{no_insert} ) {
            @no_insert_items = ( ref $p->{no_insert} eq 'ARRAY' )
                                 ? @{ $p->{no_insert} } : ( $p->{no_insert} );
        }
        elsif ( my $no_insert_config = $self->no_insert ) {
            @no_insert_items = keys %{ $no_insert_config };
        }
        %not_included = map { $_ => 1 } @no_insert_items;
    }
    else {
        my ( @no_update_items );
        if ( $p->{no_update} ) {
            @no_update_items = ( ref $p->{no_update} eq 'ARRAY' )
                                 ? @{ $p->{no_update} } : ( $p->{no_update} );
        }
        elsif ( my $no_update_config = $self->no_update ) {
            @no_update_items = keys %{ $no_update_config };
        }
        %not_included = map { $_ => 1 } @no_update_items;
    }

    # Do not include these fields in the insert/update if they're not defined
    # (note that this includes blank/empty)

    $p->{skip_undef} ||= [];
    my $skip_undef = $self->skip_undef || {};
    $skip_undef->{ $_ }++ for ( @{ $p->{skip_undef} } );

    $p->{field} = [];
    $p->{value} = [];

FIELD:
    foreach my $field ( keys %{ $self->field } ) {
        next FIELD if ( $not_included{ $field } );
        my $value = $self->{ $field };
        next FIELD if ( ! defined $value and $skip_undef->{ $field } );
        push @{ $p->{field} }, $field;
        push @{ $p->{value} }, $value;
    }

    # Do the insert/update based on whether the object is new; don't
    # catch the die() that might be thrown -- let that percolate

##-----  REPLACE THIS ORIGINAL CODE  -----
#   if ( $is_add ) { $self->_save_insert( $p, \%not_included )  }
##-----  WITH THIS OVERRIDING CODE  -----
	if ( $is_add ) {
		eval { $self->_save_insert( $p, \%not_included ) };
		## clean up partial saves if there is a duplicate entry error
		if (my $error = $@) {		## save $@ from getting overwritten
									## in remove_from_parent_tables()
			$self->_remove_from_parent_tables if $error =~ /Duplicate entry/;
			die $error;
		}
	}
##-----  END OVERRIDING CODE  -----
    else           { $self->_save_update( $p, \%not_included )  }
##-----  BEGIN ADDITIONAL CODE  -----
	}
##-----  END ADDITIONAL CODE  -----

    # Set the 'has_save' flag so that any saved changes to the object
    # in the post_save will be an update rather than another insert;
    # clear the changed fields for the same reason

    $self->has_save;
    $self->clear_change;

    # Do any actions that need to happen after you save the object

    return undef unless ( $self->post_save_action({ %{ $p },
                                                    is_add => $is_add }) );

    # Save the newly-created/updated object to the cache

    $self->set_cached_object( $p );

    # Note the action that we've just taken (opportunity for subclasses)

    unless ( $p->{skip_log} ) {
        $self->log_action( $action, scalar $self->id );
    }

    return $self;
}

sub compare {
	my $self	= shift;
	my $twin	= shift;
	my $p		= shift;

	## must be objects of the same type
	return 0 unless ref($self) eq ref($twin);
	
	## and their fields must all have the same values
	my $type_info = $self->all_field_types($p);
	foreach my $field ( @{$self->all_fields} ) {
		next if $field eq $self->id_field;
		next unless defined $self->{$field} || defined $twin->{$field};
		return 0 unless defined $self->{$field} && $twin->{$field};
		if ( ref($self->{$field}) ) {
			return 0 unless $self->{$field}->compare($twin->{$field});
		} else {
			if ( $self->_is_numeric_type($type_info->{$field}) ) {
				return 0 unless $self->{$field} == $twin->{$field};
			} else {
				return 0 unless $self->{$field} eq $twin->{$field};
			}
		}
	}

	return 1;
}

sub as_string {
	my $self = shift;
	my $tab = shift || '';
	my $fields = $self->CONFIG->{as_string_order} || $self->all_fields;
	my $msg = '';
	foreach my $field (@$fields){
		$msg .= $tab.sprintf( "%-20s: %s\n", $field, defined $self->{$field} ? $self->{$field} : '');
		my $ref = ref $self->{$field};
		next unless ($ref  && $ref ne 'HASH' && $ref ne 'ARRAY');
		$msg .= $self->{$field}->as_string("\t");
	}
	return $msg;
}

##-----  Private Class Methods  -----
## overrides method in SPOPS
sub _get_definitive_fields {	return $_[0]->all_fields; }

sub _build_conf {
	my $class = shift;
	my $conf  = shift || {};

	# get the conf variable for the class.
	my $class_conf = $class->_get_CONF;
	# get the alias for the class
	my $alias = $class->_get_main_alias;

	unless (exists ($conf->{$alias})) {
		$conf->{$alias} = $class_conf->{$alias};
	}
	my $class_links = $class->_get_links_to || '';
	if ($class_links) {
		foreach my $key (keys %$class_links) {
			next if ($key->_config_processed || 
			         exists $conf->{$key->_get_main_alias});
			$conf = $key->_build_conf($conf);
		}  
	}#end if 
	return $conf;
}

sub _get_main_alias {
	## This method can be used to find the main alias even
	## before the class's configuration has been processed.
	my $class = shift;
	my $conf = eval '$' . $class . '::CONF';
	my ($alias) = grep $conf->{$_}->{class} eq $class, keys %$conf;

	return $alias;
}

sub _get_CONF 		 { return eval '$' . $_[0] . '::CONF'; }
sub _get_links_to	 { return $_[0]->_get_CONF->{$_[0]->_get_main_alias}->{links_to}; }

sub _config_processed {
	no strict 'refs';
	my $CONFIG_method = *{$_[0]."::CONFIG"}{CODE};
	return ref($CONFIG_method) eq 'CODE';
}

sub _is_numeric_type {
	my $self		= shift;
	my $type_info	= shift;
	
	return grep $type_info == $_, (	SQL_NUMERIC,
									SQL_DECIMAL,
									SQL_INTEGER,
									SQL_SMALLINT,
									SQL_FLOAT,
									SQL_REAL,
									SQL_DOUBLE,
# (no longer in DBI)				SQL_BIGINT,
									SQL_TINYINT	);
}

sub _isa_classes {
	my $class	= shift;
	my $href	= shift || {};
	my $depth	= shift || 1;

	$class = ref($class)	if ref($class);	## get class if passed an object
	$href->{$class} = $depth;				## stick it as a key in the hash
	
	foreach my $parent ( @{$class->CONFIG->{isa}} ) {
		next unless $parent->isa($class->ROOT_OBJ_CLASS);
		$href = $parent->_isa_classes($href, $depth+1)
			unless $href->{$parent} && $href->{$parent} > $depth+1;
	}
	return $href;
}

##-----  Private Object Methods  -----
sub _remove_from_parent_tables {
	my $self = shift;
	my $p    = shift || {};
 
	foreach my $class (@{ $self->isa_classes }) {
		next if $class eq ref($self);
		eval {
			$class->db_delete({
					table => $class->table_name,
					where => $class->id_clause($self->id, 'noqualify', {%$p}),
					db	  => $p->{db},
				})
		};
		warn "Unable to remove row from ". $class->table_name if $@;
	}

	return 1;
}

##-----  Callback Methods  -----
sub post_fetch_action {
	my $self	= shift;
	my $orig_p	= shift || {};

	## call the overridden post_fetch_action to handle rulesets
	$self->SUPER::post_fetch_action( $orig_p );

	foreach my $field ( keys %{ $self->e_has_a } ) {
		my $h = $self->e_has_a->{$field};
		if ( $h->{fetch} && $h->{fetch}{type} eq 'auto' ) {
			if ( my $val = $self->{$field} ) {
				my %p;
				$p{db} = $orig_p->{db} if defined $orig_p->{db};
				$self->{$field} = $h->{class}->pm_fetch($val, \%p ) ||
					die "Could not auto-fetch '$field' ($h->{class}) id: $val";
			}
		}
	}

	return $self;
}

sub pre_save_action {
	my $self	= shift;
	my $orig_p	= shift || {};
	
	## call the overridden pre_save_action to handle rulesets
	$self->SUPER::pre_save_action( $orig_p );

	foreach my $field ( keys %{ $self->e_has_a } ) {
		my $h = $self->e_has_a->{ $field };
		my $val = $self->{$field};
		if ( $val && ref $val ) {
			## save if indicated
			my %p;
			$p{db} = $orig_p->{db} if defined $orig_p->{db};
			$val->save( \%p )	if $h->{fetch} && !$h->{fetch}{nosave};

			## move object to a temp field during save
			$self->{'tmp_' . $field . '_'} = $val;
			$self->{$field} = $self->{$field}->id;
		}
	}

	return $self;
}

sub post_save_action {
	my $self	= shift;
	my $orig_p	= shift || {};

	## call the overridden post_save_action to handle rulesets
	$self->SUPER::post_save_action( $orig_p );;

	foreach my $field ( keys %{ $self->e_has_a } ) {
		my $h = $self->e_has_a->{$field};
		my $val = $self->{'tmp_' . $field . '_'};
		if ( $val && ref $val ) {
			$self->{$field} = $val;
			$self->{'tmp_' . $field . '_'} = undef;
		} elsif ( $h->{fetch} && $h->{fetch}{type} eq 'auto' ) {
			if ( my $val = $self->{$field} ) {
				my %p;
				$p{db} = $orig_p->{db} if defined $orig_p->{db};
				$self->{$field} = $h->{class}->pm_fetch($val, \%p ) ||
					die "Could not auto-fetch '$field' ($h->{class}) id: $val";
			}
		}
	}

	return $self;
}

sub pre_remove_action {
	my $self	= shift;
	my $orig_p	= shift || {};
	my $class	= ref($self);

	## call the overridden pre_remove_action to handle rulesets
	$self->SUPER::pre_remove_action( $orig_p );

	## auto-remove specified secondary objects
	foreach my $field ( keys %{ $self->e_has_a } ) {
		my $h = $self->e_has_a->{$field};
		if ( $h->{remove} && $h->{remove}{type} eq 'auto' && $self->{$field} ) {
			my %p;
			$p{db} = $orig_p->{db} if defined $orig_p->{db};
			$self->{$field} = $h->{class}->pm_fetch($self->{$field}, \%p )
				unless ref $self->{$field};
			$self->{$field}->remove( $orig_p )	if $self->{$field};
		}
	}

	## remove all corresponding rows in 'links_to' tables
	my ($table, $where);
	foreach $table ( values %{$self->CONFIG->{links_to}} ) {
		$where = $self->id_clause(undef, 'noqualify', $orig_p);
		eval { $self->db_delete( {	table => $table,
									where => $where,
									db	  => $orig_p->{db}  }) };
		if ( $@ ) {
			warn "Unable to remove links."; 
		}
	}
	
	## remove corresponding row in each parent table
	$self->_remove_from_parent_tables;

	return $self;
}

1;
__END__

=head1 NAME

SPOPSx::Ginsu - SPOPS Extension for Generalized INheritance SUpport.

=head1 SYNOPSIS

1. Create a datasource class, for example MyDBI, which inherits from
SPOPSx::Ginsu::DBI holds the package variables for the database
connection (e.g. see t/MyDBI.pm).

2. Create a root base class, for example MyBaseObject, which inherits
from the datasource class and SPOPSx::Ginsu and defines the base table
(e.g. see t/MyBaseObject.pm).

3. Create your own sub-class of MyBaseObject which defines it's own
fields (e.g. see t/Person.pm).

4. Create a configuration file which defines the package variables used
by the datasource class to make the database connection (e.g. see
t/my_dbi_conf.pm).

Assuming the files from steps 1-4 are MyDBI.pm, MyBaseObject.pm,
MyObject.pm and my_dbi_conf.pm ...

  use my_dbi_conf;
  use MyObject;
 
  $obj = MyObject->new({field1 => 'value1', ... });
  $obj = $obj->save;
  $obj = MyObject->fetch($id);
  $obj = MyBaseObject->pm_fetch($id);

  $obj->remove;


=head1 DESCRIPTION

This is the base class for all Ginsu objects. SPOPS::DBI implements an
inherited persistence mechanism for classes whose objects are each
stored as a row in a single database table. Each class has its own table
and all of the persistent fields are stored in that table. Ginsu extends
this implementation to handle subclassing of such objects, including
polymorphic retrieval. The fields of a given object are stored across
several database tables, one for each parent class with persistent
fields. A Ginsu object is simply an SPOPS::DBI object stored across
multiple database tables.

All objects for which you want polymorphic access must share a base
class whose table has a unique 'id' field and a 'class' field. In the
example classes used for the tests (see the diagram in
docs/Example.pdf), this class is called MyBaseObject. Suppose we have a
VehicleImplementation class inheriting from MyBaseObject, which has the
fields 'name' and 'owner'. And suppose VehicleImplementation has a
subclass Aircraft which adds the field 'ceiling'. In this example, an
Aircraft object will be stored into 3 tables, 'id' and 'class' in the
base_table for MyBaseObject, 'name' and 'owner' in the base_table for
VehicleImplementation and 'ceiling' in the base_table for Aircraft. Each
table also has an id_field which is used to join the pieces of the
object together from the 3 tables.

Also, unlike the typical usage of SPOPS objects, where the classes are
created by SPOPS and have no corresponding .pm file, Ginsu objects are
defined in a .pm file just like a standard Perl object, with a few
additions. Each class must define the variables @ISA, $CONF, and
$TABLE_DEF in the BEGIN block. The @ISA variable is standard Perl and
$TABLE_DEF contains an SQL statement which creates the table for the
corresponding class. The $CONF variable contains an SPOPS configuration
hash with the configuration for this class only. The BEGIN block is
followed by 'use' statements for the classes which are referenced in
@ISA and the 'has_a' and 'links_to' parts of $CONF. Finally, after all
of the use statements, it should have the line:

  __PACKAGE__->config_and_init;

By convention we put it as the last line of code in the file.

These conventions allow us to say ...

  use MyObject;

... just like we would 'use' any other Perl object.

=head1 OBJECT RELATIONSHIPS

SPOPS has configuration for 'has_a' and 'links_to' types of
relationships between objects. These should continue to work just fine
in Ginsu. However, I have proposed a more general framework for
specifying these relationships, including defining auto-fetching/
saving/removing of related objects. This proposed syntax is described in
detail in two posts to the Openinteract-Dev mailing list which can also
be found in docs/new_has_a.txt and docs/update_to_new_has_a.txt

Neither SPOPS nor Ginsu fully implement this new configuration syntax,
though there is some interest in eventually adding it to SPOPS. Since
that's not yet happened Ginsu includes a temporary implementation of
some of the features, namely the forward direction
auto-fetch/save/remove. Ginsu looks for a configuration hash to be
returned by a method named C<e_has_a()>.

=head1 METHODS

=head2 Public Class Methods

=over 4

=item ROOT_OBJ_CLASS

 $class_name = CLASS->ROOT_OBJ_CLASS

Abstract method that must return the name of the root class whose table
constains an autoincrement id field and the class field.

=item e_has_a

 $config_hash = CLASS->e_has_a

This is a temporary mechanism for returning a configuration hashref for
the new style has-a relationships as specified in the OBJECT
RELATIONSHIPS section above. Hopefully, this functionality will some day
be included in SPOPS.

Default is an empty hashref. Sub-classes may override this to define
their own configurations. Currently, nothing in this configuration is
used during creation and initialization of the class, but only in the
execution of pre/post-fetch/save/remove_action methods.

=item new

 $object = CLASS->new( $href )

Overrides the inherited new() method to allow the input hashref to
initialize inherited fields. Also puts the class name in the 'class'
field.

=item isa_classes

 $class_list = CLASS->isa_classes
 $class_list = $object->isa_classes

Returns an arrayref of all classes in this class's inheritance hierarchy
which inherit from ROOT_OBJ_CLASS, including ROOT_OBJ_CLASS and the
class itself. The list is ordered by proximity to current class in the
inheritance tree, with the calling class always returned as the first
element and ROOT_OBJ_CLASS as the last element in the list.

=item inherited_fields

 $field_list = CLASS->inherited_fields
 $field_list = $object->inherited_fields

Returns an arrayref of all inherited non-id field names for the current
class. Does not include fields defined in the current class, only those
from parent classes.

=item all_fields

 $field_list = CLASS->all_fields
 $field_list = $object->all_fields

Returns an arrayref of all fields for the current class, including
inherited fields.

=item all_field_types

 $href = CLASS->all_field_types( \%p )
 $href = $object->all_field_types( \%p )

Returns a hashref of SQL types for each field (including inherited
fields), where the types are those defined by DBI. Takes an optional
hashref of parameters which are passed to db_discover_types().

=item config_and_init

 CLASS->config_and_init

Processes the configuration stored in $CONF for this class (via
SPOPS::ClassFactory->create) and any classes related to it via
'links_to' relationships. Calls class_initialize (inherited). This is
typically called by putting the line ...

 __PACKAGE__->config_and_init;

... as the last line of code in classes which inherit from
SPOPSx::Ginsu.

=item fetch

 $object = CLASS->fetch( $id, \%p )

Overrides the SPOPS::DBI::fetch method and modifies the database SELECT.
Instead of selecting from a single table it joins the tables by id to
get all fields of the object, including inherited fields. This method
currently ignores any column_group or alter_field specifications.

=item fetch_group

 $obj_list = CLASS->fetch_group( \%p )

Overrides the SPOPS::DBI::fetch_group method and modifies the database
SELECT. Instead of selecting from a single table it joins the tables by
id to get all fields of the object, including inherited fields. This
also allows the where clause to include conditions on inherited fields.
The objects fetched are of the type specified by the 'class' field in
the Object table, not simply the class used to call fetch_group. In
other words, it is a polymorphic fetch. This method currently ignores
any column_group or alter_field specifications. If the class used to
call the method does not have a table, the 'class' field of each fetched
row is checked to make sure that it "isa" object of the calling class,
otherwise it is excluded from the list returned.

=item fetch_count

 $count = CLASS->fetch_count( \%p )

Overrides the SPOPS::DBI::fetch_count method. If the class used to call
the method does not have a table, the 'class' field of each fetched row
is checked to make sure that it "isa" object of the calling class,
otherwise it is excluded from the count.

=item pm_fetch

 $object = CLASS->pm_fetch( $id, \%p )

A polymorphic fetch. Identical to fetch, except the class used to
perform the fetch is not the one used to call this method, but rather
the class indicated for this id in the database. Same as a fetch_group
with where clause being a simple id clause.  This method currently
ignores any column_group or alter_field specifications.

=item fetch_group_by_field

 $obj_list = CLASS->fetch_group_by_field( $field, \@vals, \%p )

Given a field name and a list of values, it fetches the objects whose
specified field matches one of the values in the list. Simply creates
the appropriate WHERE clause and calls fetch_group to return the
corresponding arrayref of objects. Additional fetch_group parameters can
be passed in the optional \%p hashref. If %p contains a 'where' field it
is put at the end of the generated WHERE clause as follows:

 '<generated where> AND (<where from %p>)'

If %p contains a 'value' field, any generated values are added to the
beginning of the list. This allows extra conditions to be added so one
can do the following to get all Vehicles owned by Bob or Sally, except
Bob's boat.

 $list = Vehicle->fetch_group_by_field( 'owner',
 										[$bob->id, $sally->id],
                                      { where => 'id != ?',
                                        value = [ $bobs_boat->id ] }
                                     )

=item fetch_group_by_ids

 $obj_list = CLASS->fetch_group_by_ids( \@id_list, \%p )

Does a C<fetch_group_by_field> on the id field and then sorts the
returned objects according to the list of ids passed in.

Note that, while the objects returned are in the same order as the
specified id's, there will be a one-to-one correspondence if and only if
all corresponding objects are in the database and are not eliminated by
an optional WHERE clause passed in %p.

=back

=head2 Public Object Methods

=over 4

=item save

 $object = $object->save( \%p )

Overrides the SPOPS::DBI::save method, saving the fields of the object
in the appropriate tables. Takes an optional parameter hashref as input
and returns the saved object.

=item compare

 $TorF = $object1->compare( $object2 )

Returns 1 if the two objects contain the same data, 0 otherwise.
Note: does not compare the id fields.

=item as_string

 $str = $object->as_string

Overrides as_string method of parent class. Prints all fields, including
inherited fields, and also prints contents of nested objects (though not
fields containing hashrefs or arrayrefs).

=back

=head2 Private Class Methods

=over 4

=item _execute_multiple_record_query

Overrides method in SPOPS::DBI to fix bug with case-sensitive table
names.

=item _build_conf

 $href = CLASS->_build_conf( $href )

Used recursively to build up a hashref containing the configuration info
($CONF variable contents) for all classes linked to this class via
'links_to' definitions (actually only those whose config has not yet
been processed). All of these classes must be passed to
SPOPS::ClassFactory->create() at the same time to properly process the
configurations.

=item _get_main_alias

 $alias = CLASS->_get_main_alias

Returns the name of the main alias for a class (the key to use in
$CONF). This method can be used even before the class's configuration
has been processed.

=item _get_CONF

 $conf = CLASS->_get_CONF

Returns the $CONF variable for the class.

=item _get_links_to

 $links_to = CLASS->_get_links_to

Returns the 'links_to' configuration hashref for the class.

=item _config_processed

 $TorF = CLASS->_config_processed

Returns 1 if the class's configuration has already been processed, 0
otherwise.

=item _isa_classes

 $href = CLASS->_isa_classes
 $href = CLASS->_isa_classes($href, $depth)

Recursively builds a hashref whose keys contain the names of all classes
in this class's inheritance hierarchy which inherit from ROOT_OBJ_CLASS,
including the class itself. The values in the hashref indicate level in
the inheritance hierarchy, with the calling class being level 1 and
ROOT_OBJ_CLASS being the maximum.

=back

=head2 Private Object Methods

=over 4

=item _remove_from_parent_tables

 $obj->_remove_from_parent_tables

Removes rows corresponding to this object's id from tables of parent
classes.

=back

=head2 Callback Methods

=over 4

=item post_fetch_action

 $object = $object->post_fetch_action( \%p )

Called automatically immediately following a fetch operation. It calls
the superclass's C<post_fetch_action()> method then examines the
configuration returned by C<e_has_a()> and fetches any secondary objects
specified for auto-fetching.

=item pre_save_action

 $object = $object->pre_save_action( \%p )

Called automatically immediately before a save operation. It calls the
superclass's C<pre_save_action()> method then examines the configuration
returned by C<e_has_a()> and saves any secondary objects specified for
auto-saving. Fields containing auto-fetched secondary objects are
temporarily modified to hold only the corresponding object ids (during
the save process).

=item post_save_action

 $object = $object->post_save_action( \%p )

Called automatically immediately after a save operation. It calls the
superclass's C<post_save_action()> method then examines the configuration
returned by C<e_has_a()> and restores (or fetches) any fields specified
for auto-fetching.

=item pre_remove_action

 $object = $object->pre_remove_action( \%p )

Called automatically immediately before a remove operation. It calls the
superclass's C<pre_remove_action()> method then examines the
configuration returned by C<e_has_a()> and removes any secondary objects
specified for auto-removal. Then, if present, it removes any
corresponding rows in 'links_to' tables. Finally it removes this
object's row from the table corresponding to each inherited class.

=back

=head1 BUGS / TODO

=over 4

=item *

Currently refetch() and field_update() do NOT work for inherited fields.

=item *

The fetch_iterator() functionality has never been tested and is likely
broken.

=item *

The column_group and alter_field functionality needs to be added back
into fetch and fetch_group.

=item *

Strict fields functionality does not work.

=back

=head1 CHANGE HISTORY

=over 4

$Log: Ginsu.pm,v $
Revision 1.60  2004/06/02 15:07:04  ray
Synced with SPOPS-0.87, removed _execute_multiple_record_query(), updated version number.

Revision 1.59  2004/04/23 18:05:31  ray
Updated docs.

Revision 1.58  2004/04/23 13:56:38  ray
Renamed from ESPOPS::Object to SPOPSx::Ginsu, updated to sync with SPOPS-0.83, removed create_unless_exists() method.


=back

=head1 COPYRIGHT

Copyright (c) 2001-2004 PSERC. All rights reserved.

and parts are

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

  Ray Zimmerman, <rz10@cornell.edu>
  Raj Chandran, <rc264@cornell.edu>

=head1 SEE ALSO

  SPOPS(3)
  SPOPS::DBI(3)
  perl(1)

=cut
