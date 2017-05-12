#==============================================================================
#
# PQL::Cache
#      A cache using Perl Query Language, similar to SQL and DBIx::Class
#
# Ralf Peine, Sun Dec 21 13:51:53 2014
#
#==============================================================================

package PQL::Cache;

use strict;
use vars qw($VERSION);
$VERSION ='0.800';

# standards
use warnings;
use Carp;
# use Data::Dumper;

# --- Create Instance -----------------
sub new
{
    my $caller = $_[0];
    my $class  = ref($caller) || $caller;

    # let the class go
    my $self = {};
    bless $self, $class;

    $self->_init();

    return $self;
}

# --- _init ------------------------------------------------------------------
sub _init
{
    my ($self        # instance_ref
        ) = @_;

    $self->clear();
    $self->{_table_def} = {};
    $self->_implement_compare_subs();
}

# --- clear the stored data ---------------------------------
sub clear {
    my ($self,          # instance_ref
        # $cache_to_clear  # optional: cache to clear. clear all if unset
        ) = @_;
    $self->{_cache}                 = {};
    $self->{_index}                = {};
    $self->{_next_free_index_list} = {};
}

# --- table_definition ---------------------------------------------------------

sub set_table_definition {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        $table_def       # definitions for table
        ) = @_;
    croak "no table set" unless defined $table_name;

    $self->{_table_def}->{$table_name} = $table_def;
    $self->_prepare_cache($table_name);
    return $table_name;
}

sub get_table_definition {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        ) = @_;
    croak "no table set " unless defined $table_name;

    my $table_def = $self->{_table_def}->{$table_name};

    unless ($table_def) {
        my $known_tables = "known tables: ".join ("\n", sort keys (%{$self->{_table_def}}), '');
        # print "$known_tables\n";
        croak "No definition found for table [$table_name], $known_tables";
    }

    return $table_def;
}

# --- table cache --------------------------------------------

sub get_table_cache {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        ) = @_;
    croak "no table set" unless defined $table_name;

    my $table = $self->{_cache}->{$table_name};

    croak "table [$table_name] not found" unless $table;

    return $table;
}

# --- table_index --------------------------------------------

sub get_table_index {
    my ($self,           # instance_ref
        $table_name,     # index (table) to store data...
        ) = @_;
    croak "no table set" unless defined $table_name;

    my $index = $self->{_index}->{$table_name};
    
    croak "index of table [$table_name] not found" unless $index;

    return $index;
}

# --- table_keys --------------------------------------------

sub get_table_keys {
    my ($self,           # instance_ref
        $table_name,     # table
	$column,         # column
        ) = @_;
    croak "no table set" unless defined $table_name;

    my $keys = $self->{_keys}->{$table_name};

    return $keys unless defined $column;
    
    return $keys->{$column};
}

# --- get index of next free field in table -----------------
sub get_next_free_idx {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        ) = @_;

    my $cache = $self->get_table_cache($table_name);

    my $index = $self->{_next_free_index_list}->{$table_name};
    $index = 0 unless defined $index;
    while ($cache->[$index]) {
        # print "#### search next free index $index\n";
        $index++;
    }
    $self->{_next_free_index_list}->{$table_name} = $index + 1;
    return $index;
}

# --- get compare subs ---

sub get_compare_subs {
    my ($self,           # instance_ref
        ) = @_;

    return $self->{_compare_subs} || {};
}

# --- get combine subs ---

sub get_combine_subs {
    my ($self,           # instance_ref
        ) = @_;

    return $self->{_combine_subs} || {};
}

# --- get step2 subs ---

sub get_step2_subs {
    my ($self,           # instance_ref
        ) = @_;

    return $self->{_step2_subs} || {};
}

# --- implement compare subs ----------------------------------------------------------------

sub _implement_compare_subs {
    my ($self,           # instance_ref
        ) = @_;

    my $step2_subs = $self->{_step2_subs};

    $step2_subs = $self->{_step2_subs} = {} unless $step2_subs;

    $step2_subs->{ge} = sub {
	my ($column, $compare_value,
	    ) = @{$_[0]};
	
	croak '"ge" operation needs SCALAR as parameter' if ref $compare_value;
	return sub { $_->{$column} ge $compare_value };
    };

    $step2_subs->{le} = sub {
	my ($column, $compare_value,
	    ) = @{$_[0]};

	croak '"ge" operation needs SCALAR as parameter' if ref $compare_value;
	return sub { $_->{$column} le $compare_value };
    };

    $step2_subs->{obj} = sub {
	my ($operation, $matching_sub,
	    ) = @{$_[0]};
	
	croak '"$operation" operation needs CODE_REF as parameter' unless ref $matching_sub eq "CODE";
	return $matching_sub;
    };

    $step2_subs->{data} = sub {
	my ($operation, $matching_sub,
	    ) = @{$_[0]};
	croak '"$operation" operation needs CODE_REF as parameter' unless ref $matching_sub eq "CODE";
	return $matching_sub;
    };

    $step2_subs->{sub_value} = sub {
	my ($key,
	    $matching_sub
	    ) = @{$_[0]};

	croak '"data" operation needs CODE_REF as parameter' unless ref $matching_sub eq "CODE";
	return sub { my $obj = $_; { local $_ = $obj->{$key}; return $matching_sub->() }};
    };

    my $combine_subs = $self->{_combine_subs};

    $combine_subs = $self->{_combine_subs} = {} unless $combine_subs;

    $combine_subs->{and} = sub {
	my ($conditions,
	    ) = @_;

	croak '"and" operation needs ARRAY_REF as parameter' unless ref $conditions eq "ARRAY";

	return $self->_handle_where(@_);       
    };
    
    my $compare_subs = $self->{_compare_subs};

    $compare_subs = $self->{_compare_subs} = {} unless $compare_subs;

    $compare_subs->{in} = sub {
	my ($key,
	    $array_ref
	    ) = @{$_[0]};

	croak '"in" operation needs ARRAY_REF as parameter' unless ref $array_ref eq "ARRAY";

	my $search_key = $self->escape_regular_expression_special_chars($key);
	my @in_select_arr;
	foreach my $in_value (@$array_ref) {
	    $in_value = $self->escape_regular_expression_special_chars($in_value);
	    push (@in_select_arr, $in_value);
	}
	my $values_str = join ("|", @in_select_arr);
	return ("#\\|$search_key=($values_str)\\|#", $values_str);
	
    };
    
    $compare_subs->{is} = sub {
	my ($key,
	    $value
	    ) = @{$_[0]};

	croak '"is" operation needs SCALAR as parameter'.ref $value if ref $value;

	my $search_key = $self->escape_regular_expression_special_chars($key);
	$value = '' unless defined $value;
	$value = $self->escape_regular_expression_special_chars($value);
	return ("#\\|$search_key=$value\\|#", $value);
    };

    $compare_subs->{like} = sub {
	my ($key,
	    $value
	    ) = @{$_[0]};
	
	croak '"like" operation needs SCALAR as parameter'.ref $value if ref $value;
	
	my $pattern = $value;

	my $search_key = $self->escape_regular_expression_special_chars($key);
	if ($pattern =~ /^\^/o) {
	    $pattern =~ s/^\^//o;
	}
	else {
	    $pattern = "[^|]*".$pattern;
	}
	
	if ($pattern =~ /\$$/o) {
	    $pattern =~ s/\$$//o;
	}
	else {
	    $pattern .= '[^|]*'
	}
	# print "like $pattern\n";
	return ("#\\|$search_key=$pattern\\|#", $value);
    };

    $compare_subs->{or} = sub {
	carp "or is currently not supported";
    };
}

# --- prepare cache, if not already done ------------------

sub _prepare_cache {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        ) = @_;

    $self->{_cache}->{$table_name} = [] unless $self->{_cache}->{$table_name};
    $self->{_index}->{$table_name} = [] unless $self->{_index}->{$table_name};

    unless ($self->{_keys}->{$table_name}) {
	my $table_def = $self->get_table_definition($table_name);
	# print "# Define key columns for table $table_name: ";
	foreach my $key_column (@{$table_def->{keys}}) {
	    # print "$key_column, ";
	    $self->{_keys}->{$table_name}->{$key_column} = {};
	}
	# print "\n";
    }
}

# --- add data ----------------------------------------------
sub insert {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        $data,
        ) = @_;

    croak "no table set" unless defined $table_name;
    croak "no data given" unless defined $data;

    $self->_prepare_cache($table_name);

    my $count = 0;
    if (ref $data eq 'ARRAY') {
        foreach my $single_data (@$data) {
            $count = $self->_insert($table_name, $single_data);
        }
    }
    else {
        $count = $self->_insert($table_name, $data);
    }
    return $count;
}

# --- add data ----------------------------------------------
sub _insert {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        $data,
        ) = @_;

    my $cache = $self->get_table_cache($table_name);
    my $index = $self->get_table_index($table_name);

    my $next_idx = $self->get_next_free_idx($table_name);

    my $index_str = $self->build_index_string($table_name, $data, $next_idx);

    my $table_def = $self->get_table_definition($table_name);

    foreach my $key_column (@{$table_def->{keys}}) {
	my $key_index_hash = $self->get_table_keys($table_name, $key_column);
	my $value = $data->{$key_column}; # TODO: later use sub_ref to get value
	my $key_index = $key_index_hash->{$value};
	$key_index_hash->{$value} = $key_index = [] unless $key_index;
	push (@$key_index, $next_idx);
    }

    $cache->[$next_idx] = $data;
    $index->[$next_idx] = $index_str;
    return scalar @$cache;
}

# --- update the index key(s) ----------------------------------------------
sub update_index {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        $data,           # optional: later update single data
        ) = @_;

    croak "no table set" unless defined $table_name;

    my $cache_arr = $self->get_table_cache($table_name);
    my $index_arr = $self->get_table_index($table_name);

    croak "No data found for table '$table_name'"
        unless $cache_arr && $index_arr;

    # print "### Update index for cache table $table_name\n";

    foreach my $index (0..$#$cache_arr) {
        $self->_update_index_key($table_name,   $index);
    }
}

# --- update the index key ----------------------------------------------
sub _update_index_key {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        $index           # internal index, where data is stored
        ) = @_;

    my $cache_arr = $self->get_table_cache($table_name);
    my $index_arr = $self->get_table_index($table_name);

    my $data = $cache_arr->[$index];

    return unless $data;

    my $index_str = $self->build_index_string($table_name, $data, $index);

    # print "$index_str\n";

    $index_arr->[$index] = $index_str;
}

# --- build the string to add to the index for searching -------------------
sub build_index_string {
    my ($self,           # instance_ref
        $table_name,     # cache (table) to store data...
        $data,
        $index
	) = @_;

    my $table_def = $self->get_table_definition($table_name);

    my $index_str = "#|$index|#";

    my $value;
    foreach my $key (@{$table_def->{keys}}, @{$table_def->{columns}}) {
        $value = $data->{$key};
        next unless defined $value;
        $index_str .= "#|$key=$value|#"
    }

    return $index_str;
}

# --- Same like SQL DELETE ---------------------------------

sub delete {
    my ($self,           # instance_ref
        %query,          # perl query
	) = @_;

    my $tid_list    = $self->_find_matches(%query);

    my $table_name  = $query{from};
    my $string_index_field = $self->get_table_index($table_name);
    my $cache       = $self->get_table_cache($table_name);

    my $deleted_rows_count = 0;
    my $next_free_idx = $self->{_next_free_index_list}->{$table_name};
    $next_free_idx = scalar @$cache unless defined $next_free_idx;
    
    foreach my $index (@$tid_list) {
	my $object = $cache->[$index];
	$next_free_idx = $index if $index < $next_free_idx;
	$cache->[$index] = '';
	$string_index_field->[$index] = '';
	
	my $table_key_indexes = $self->get_table_keys($table_name);
	foreach my $column_key (keys(%$table_key_indexes)) {
	    my $values_hash       = $table_key_indexes->{$column_key};
	    my $value             = $object->{$column_key}; #TODO get value
	    my $index_arr_ref     = $values_hash->{$value};
	    my $new_index_arr_ref = $values_hash->{$value} = [];
	    foreach my $other_index (@$index_arr_ref) {
		push (@$new_index_arr_ref, $other_index) if $index != $other_index;
	    }
	}
	$deleted_rows_count++;
    }

    $self->{_next_free_index_list}->{$table_name} = $next_free_idx;

    return $deleted_rows_count;
}

# --- extract touple ids from selection list ---------------------------------
sub extract_tid_from_selection {
    my ($self,          # instance_ref
        $selection,     # perl query
	) = @_;

    my @result = map {
        if (/^#\|(\d+)\|#/) {
            $1;
        } else {
            ()
        }
    } @$selection;

    return \@result;
}

# --- Same like SQL SELECT ---------------------------------
sub select {
    my ($self,           # instance_ref
        %query,          # perl query
	) = @_;

    my $tids        = $self->_find_matches(%query);

    my $table_name  = $query{from};
    my $cache       = $self->get_table_cache($table_name);

    my @result = map {
	$cache->[$_];
    } @$tids;

    my $result_ref = \@result;
    
    my $columns = $query{what};

    $result_ref = $self->_select_columns($columns, $result_ref)
        if $columns;

    return $result_ref;
}

# --- select columns ----------------------

sub _select_columns {
    my ($self,           # instance_ref
        $columns,        # string 'all' or ArrayRef with column names
        $results,        # ArrayRef of results
	) = @_;

    my $value_type = ref ($columns);
    if ($value_type) {
        if ($value_type eq 'ARRAY') {
            my @what_list = map {
                my $result_row = {};
                foreach my $key (@$columns) {
                    $result_row->{$key} = $_->{$key};
                }
                $result_row;
            } @$results;
            $results = \@what_list;
        }
        else {
            croak "unknown column selection by what => $value_type ";
        }
    }
    elsif ($columns eq 'all') {
    }
    else {
        croak "unknown column selection by what => '$columns'";
    }
    return $results;
}

# --- Find matching elements --- used for selection and removing ------
sub _find_matches {
    my ($self,           # instance_ref
        %query,          # perl query
        ) = @_;

    my $table_name         = $query{from};
    my $table_def          = $self->get_table_definition($table_name);
    my $string_index_field = $self->get_table_index($table_name);
    my $key_index_field    = $self->get_table_keys($table_name);
    my $table_objs         = $self->get_table_cache($table_name);

    my $search_str  = "";

    # my %conditions = $self->_handle_where($query{where});
    my $query            = $self->_handle_where($query{where}, $key_index_field);
    my $index_keys       = $query->{indexes};
    my $conditions       = $query->{conditions};
    my $values           = $query->{values};
    my $step2_operations = $query->{step2_operations};

    my @selection;
    my $first_search = 1;
    my $tids_first_run;

    if ($index_keys && scalar @$index_keys) {
	$first_search = 0;
	my ($column, $value);

	while (defined ($column = shift @$index_keys)) {
	    $value = shift @$index_keys;
	    my $matches = $key_index_field->{$column}->{$value};
	    if ($tids_first_run) {
		if (scalar @$tids_first_run < scalar @$matches) {
		    $tids_first_run = $matches;
		}
	    }
	    else {
		$tids_first_run = $matches;
	    }
	}
    }

    if ($first_search) {
	$search_str = "";

	foreach my $key (@{$table_def->{keys}}, @{$table_def->{columns}}) {
	    
	    # print "#### '$key'\n";
	    
	    if ($conditions->{$key}) {
		$search_str .= ".*" if $search_str;
		$search_str .= $conditions->{$key};
	    }
	}
	# print "##### search string: $search_str\n";
	if ($search_str) {
	    @selection = grep (/$search_str/, @$string_index_field);
	}
	else {
	    # --- empty condition, select all -------
	    @selection = @$string_index_field;
	}
	
	$tids_first_run = $self->extract_tid_from_selection(\@selection);
    }
    else {
	my @step1_operations;
	foreach my $key (keys(%$conditions)) {
	    my $pattern = $values->{$key};
	    # print "$key => $pattern\n";
	    push (@step1_operations, sub { $_->{$key} =~ /$pattern/ });
	}
	$step2_operations = [@step1_operations, @$step2_operations];
    }

    # print Dumper($tids_first_run);

    my $tids = $tids_first_run;

    if ($step2_operations && scalar @$step2_operations) {
	$tids = [];
	foreach my $tid (@$tids_first_run) {
	    local $_ = $table_objs->[$tid];
	    my $selected = 1;
	    # print "$tid\n";
	    foreach my $selection_sub (@$step2_operations) {
		# print Dumper ($selection_sub);
		unless ($selection_sub->()) {
		    $selected = 0;
		    last;
		}
	    }
	    push (@$tids, $tid) if $selected;
	}
    }

    return $tids;
}

# --- handle where condition part -----------------------------

sub _handle_where {
    my ($self,             # instance_ref
        $where_condition,  # perl query
	$table_indexes,    # hash with all indexes of table
        ) = @_;

    my $conditions = {};
    my $values     = {};
    my $operation_func_used = 0;
    my $index               = 0;
    my $search_str;

    return $conditions unless $where_condition;
    
    my $compare_subs = $self->get_compare_subs();
    my $combine_subs = $self->get_combine_subs();
    my $step2_subs   = $self->get_step2_subs();

    my @step2_operation_list;

    my @indexes;
    
    while ($index < $#$where_condition) {
	$operation_func_used = 0;
	my $operation  = '?';
	my $param_1 = $where_condition->[$index++];
	my $param_2 = $where_condition->[$index++];

	my $param_2_ref = ref $param_2;

	# print "###1 operation: $operation ($param_2_ref)\n";

	if (!$param_2_ref) {
	    $operation = 'is';
	}
	elsif ($param_2_ref eq "ARRAY") {
	    $operation = 'in';
	}
	elsif ($param_2_ref eq "HASH") {
	    ($operation) = keys   %$param_2;
	    ($param_2)   = values %$param_2;
	}
	elsif ($param_2_ref eq "CODE") {
	    local $_;
	    if ($param_1 eq 'data') {
		$operation = 'data';
	    }
	    elsif ($param_1 eq 'obj') {
		$operation = 'obj';
	    }
	    else {
		$operation = 'sub_value';
	    }
	}
	else {
	    # print "####2 Dump param_2 = " .Dumper ($param_2);
	    print "###3 operation: $operation ($param_1, $param_2) ($param_2_ref)\n";
	    
	    return ();
	}
	
	my $parameters = [$param_1, $param_2];

	my $comb_ref  = $combine_subs->{$operation};

	return $comb_ref->($parameters, $table_indexes) if $comb_ref;

	my $use_index = 0;

	if ($operation eq 'is') {
	    my $column = $parameters->[0];
	    my $value  = $parameters->[1];
	    # print "is $column => $value => $table_indexes\n";
	    if ($table_indexes->{$column}) {
		# print "# --- use key index field [$column]\n";
		$use_index = 1;
		push (@indexes, $column, $value);
	    }
	}

	unless ($use_index) {
	    my $cond_ref  = $compare_subs->{$operation};

	    if ($cond_ref) {
		my $column = $parameters->[0];
		($conditions->{$column}, $values->{$column}) = $cond_ref->($parameters);           
	    } else {
		my $step2_operation = $step2_subs->{$operation};
		
		if ($step2_operation) {
		    push (@step2_operation_list, $step2_operation->($parameters));
		    next;
		}
		else {
		    # parse_error ("Unknown operation '$operation'")
		    unless ($cond_ref) {
			warn ("Unknown operation '$operation'");
			$cond_ref = sub { return 0; };
		    }
		}
	    }
	}
    }

    return {
	indexes          => \@indexes,
	conditions       => $conditions,
	values           => $values,
	step2_operations => \@step2_operation_list};
}

# --- parse error --------------------------------------------

sub parse_error {
    my $message = shift;

    croak "PQL-Parser: $message";
}

# --- escape character with special meanings in reg exes for exact search ------------
sub escape_regular_expression_special_chars {
    my ($self,           # instance_ref
        $text            # text to escape chars in it
        ) = @_;

    my $result_text = '';
    my $rest        = $text;

    return $text unless $text;

    while ($text =~ /([\/\(\)\[\]\.\?\+\*\^\$\|\{\}\\])/o) {
        $result_text .= $`."\\".$1;
        $rest = $text = $';
    }

    $result_text .= $rest;
    return $result_text;
}

# --- export indexes for human analysis -----------------------
#     don't use data in any scripting !!!!!!!!!!!!!!!

    sub export_indexes {
	my ($self,           # instance_ref
	    $table
	    ) = @_;

	my @results;

	if ($table) {
	    my $string_index_field = $self->get_table_index($table);
	    foreach my $row (@$string_index_field) {
		push (@results, "table:$table$row");
	    }
	}
	else {
	    foreach $table (sort(keys(%{$self->{_index}}))) {
		my $string_index_field = $self->get_table_index($table);
		foreach my $row (@$string_index_field) {
		    push (@results, "table:$table$row");
		}
	    }
	}
	return \@results;
}

1;

__END__

=head1 NAME

PQL::Cache - A mini in memory database using pure perl and PQL -
PerlQueryLanguage - to store hashes and objects.

PQL is similar to DBIx::Class API, so switching to DBIx and SQL
databases is possible.

It uses pure Perl (no compilation needed), so you can run it from a
USB stick.

=head1 VERSION

This documentation refers to version 0.800 of PQL::Cache

=head1 SYNOPSIS

  use PQL::Cache qw(:all);

B<Create Cache>

  my $cache = PQL::Cache->new();
  $cache->set_table_definition
	('person',
	 {
		 keys    => ['ID'],
		 columns => [prename => surname => birth => gender => 'perl_level']
	 });

B<Insert>

  $cache->insert(person => {
	ID       => $person_id++,
	prename  => 'Ralf',
	surname  => 'Peine',
	gender   => 'male',
	birth    => '1965-12-29',
	location => 1,             # cannot be searched!
	perl_level => 'CPAN',
  });

B<Select>

  my $result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [perl_level => 'beginner']
        );

  my $first_matching_person = $result->[0];

  $result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [ perl_level => {like => 'founder.*'}
		   ]
         );

  $result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [ prename => [Larry => Damian => 'Audrey']
			]
        );

  $result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ birth      => { like => '^196'},
                    perl_level => { like => 'founder'},
                                         ]]
        );

  $result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ birth => { ge => '1960' },
		    birth => { le => '1960' },
	 ]);

  # and is default
  $result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ gender  => 'male',
                    like => { surname => '.a.'}
                        ]
          );

  $result = $cache->select
        (what  => 'all',
         from  => 'person',
         where => [ obj => sub { $_->{birth} le '1960' }]
        );

  $result = $cache->select
	(what  => 'all',
	 from  => 'person',
	 where => [ obj => sub { $_->get_birth() ge '1960' }]
	);

  # result rows as hashes
  $result = $cache->select
      (what  => [qw (prename surname)],
       from  => 'person',
       where => [ gender => 'male',
                ]
      );

  my $first_result_hash = $result->[0];

B<Update>

  my $read_person->{surname} = 'AnotherName';

Update whole index for searching after changing some objects
  
  $cache->update_index('person');

Waits for implementation:

  $cache->update_index('person', $read_person);

B<Delete>

Same where conditions as C<select()>.

  my $deleted_rows = $cache->delete
        (what  => 'all',
         from  => 'person',
         where => [prename => 'FORREST L.']
        );

=head1 DESCRIPTION

PQL::Cache implements a small in memory database using pure Perl.
It stores also B<objects> in tables, not only hashes.

You can define tables and columns. You can insert, select and delete objects.
You get back objects or hashes containing columns by C<select(...);>

It can be dumped, like a simple hash containing objects.

PQL - Perl Query Language - is something similar to SQL and uses
DBIx::Class API. So you have a little more checking by compiler and
you can switch to a real database if RAM is expended or you want to
save data to persistent storage.

=head2 How it works

=head3 Data Storage

Data, that are objects or hashes, are stored in a simple arrays. There
are no copies created, just the references are stored. The index in
the array is used in all other internal storage to reference the
object/hash.

=head3 Regex string matches

The values for all columns defined are stored in an extra array as one
string per object/hash, to start fast regex searches for multiple
columns in single grep statement. If data changes, its string in this
array has to be updated, thats the update method is for.

=head3 Keys

Every column defined as key column gets its own hash with value of
column as key. These key columns should contain different values for
every or nearly every stored object. It is used to fast preselect one
or some objects. The key column hash contains an array for every key
value, that contains the indexes of the matching objects. This needs
also to be updated if key column of objects/hashes changes.

=head3 Current no change control

There is currently no control, if an object or hash has changed. This
has to be checked by the user.

=head3 No persistence, no transactions

This is a cache, there is no persistence implemented. To get
persistence, use real databases and DBIx or store contents into files.
Or just dump the whole cache, if all stored objects can be dumped.

=head2 Use cases

I used this cache to read in files, tables out of spreadsheets or
whatever and then search after data like a small database.

It is very comfortable for testing, a dumped Cache is loaded in
seconds and then more than 1000 selects per second are possible. Show
me a database that is that fast!

It may also be interesting, to use it as cache for a repository using
DBIx::Class.

=head2 Memory And Performane 

Tables with 100,000.0 entries and more are possible and can be managed
without problems. It depends only on RAM for your perl process. RAM
needed may be up to 3 times more than for an array of original
objects. That depends on number of columns and, more expensive, on
number of key columns used.

Try example/performance.pl to find out max entries and speed on your
machines. On mine 1 Mio objects are possible to handle.

=head2 More description will follow up.

=head1 Missing Features

Using of object get-subs for column values waits for implementation.
Currently only direct access per hash key is supported.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 by Ralf Peine, Germany. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

