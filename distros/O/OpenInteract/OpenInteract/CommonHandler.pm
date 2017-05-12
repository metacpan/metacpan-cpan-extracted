package OpenInteract::CommonHandler;

# $Id: CommonHandler.pm,v 1.44 2003/11/15 02:02:32 lachoy Exp $

use strict;
use Data::Dumper    qw( Dumper );
use OpenInteract::Handler::GenericDispatcher;
use SPOPS::Secure   qw( :level );
require Exporter;

@OpenInteract::CommonHandler::ISA       = qw( OpenInteract::Handler::GenericDispatcher );
$OpenInteract::CommonHandler::VERSION   = sprintf("%d.%02d", q$Revision: 1.44 $ =~ /(\d+)\.(\d+)/);
@OpenInteract::CommonHandler::EXPORT_OK = qw( OK ERROR );

use constant OK    => '1';
use constant ERROR => '4';


########################################
# SEARCH FORM
########################################

# Common handler method for a search form (easy)

sub search_form {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_SEARCH_FORM ) {
        $R->scrib( 0, "User requested search_form for ($class) and it's not allowed." );
        return '<h1>Error</h1><p>Objects of this type cannot be searched.</p>';
    }
    $p ||= {};

    my %params = %{ $p };
    $R->{page}{title} = $class->MY_SEARCH_FORM_TITLE;

    $class->_search_form_customize( \%params );
    my $template_name = $class->_template_name(
                                   \%params,
                                   $class->MY_SEARCH_FORM_TEMPLATE( \%params ) );
    return $R->template->handler( {}, \%params, { name => $template_name } );
}


########################################
# SEARCH
########################################

# Common handler method for a search

sub search {
    my ( $class, $p ) = @_;
    my $R   = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_SEARCH ) {
        $R->scrib( 0, "User requested search for ($class) and it's not allowed." );
        return '<h1>Error</h1><p>Objects of this type cannot be searched.</p>';
    }

    $p ||= {};
    my %params = %{ $p };

    my $apr = $R->apache;

    if ( $class->MY_SEARCH_RESULTS_PAGED ) {
        require OpenInteract::ResultsManage;
        my $search_id = $class->_search_get_id;
        my $results = OpenInteract::ResultsManage->new();

        # If the search has been run before, just set the ID

        if ( $search_id ) {
            $R->DEBUG && $R->scrib( 1, "Retrieving search for ID ($search_id)" );
            $results->{search_id} = $search_id;
        }

        # Otherwise, run the search and get an iterator back, then
        # pass the iterator to ResultsManage so we can reuse the
        # results

        else {
            $R->DEBUG && $R->scrib( 1, "Running search for the first time" );
            my ( $iterator, $msg ) =
                    eval { $class->_search_build_and_run({ %params, is_paged => 1 }) };

            # TODO: We will probably catch a specific exception here
            # when we use exceptions in OI

            if ( ! $iterator and $msg ) {
                my $cap_task = $class->MY_SEARCH_RESULTS_CAP_FAIL_TASK;
                return $class->$cap_task({ %params, error_msg => $msg });
            }

            if ( $@ ) {
                my $fail_task = $class->MY_SEARCH_FAIL_TASK;
                return $class->$fail_task({ %params, error_msg => "Search failed: $@" });
            }

            $results->save( $iterator );
            $R->DEBUG && $R->scrib( 1, "Search ID ($results->{search_id})" );
            $class->_search_save_id( $results->{search_id} );
        }

        if ( $results->{search_id} ) {
            $params{page_number_field} =  $class->MY_SEARCH_RESULTS_PAGE_FIELD;
            $params{current_page} = $apr->param( $params{page_number_field} ) || 1;
            my $hits_per_page     = $class->MY_SEARCH_RESULTS_PAGE_SIZE;
            my ( $min, $max )     = $results->find_page_boundaries(
                                                  $params{current_page}, $hits_per_page );
            $params{iterator}     = $results->retrieve({ min => $min, max => $max,
                                                         return => 'iterator' });
            $params{total_pages}  = $results->find_total_page_count( $hits_per_page );
            $params{total_hits}   = $results->{num_records};
            $params{search_id}    = $results->{search_id};
            $params{search_results_key} = $class->MY_SEARCH_RESULTS_KEY;
            $R->DEBUG && $R->scrib( 1, "Search info: min: ($min); max: ($max)",
                                       "records ($results->{num_records})" );
        }
    }

    # If we're not using paged results, then just run the normal
    # search and get back an iterator

    else {
        my ( $msg );
        ( $params{iterator}, $msg ) =
                    eval { $class->_search_build_and_run( \%params ) };

        # TODO: We will probably catch a specific exception here
        # when we use exceptions in OI

        if ( ! $params{iterator} and $msg ) {
            my $cap_task = $class->MY_SEARCH_RESULTS_CAP_FAIL_TASK;
            return $class->$cap_task({ %params, error_msg => $msg });
        }

        if ( $@ ) {
            my $fail_task = $class->MY_SEARCH_FAIL_TASK;
            $R->scrib( 0, "Got error from running search: $@" );
            return $class->$fail_task({ %params, error_msg => "Search failed: $@" });
        }
    }

    $R->{page}{title} = $class->MY_SEARCH_RESULTS_TITLE;

    $class->_search_customize( \%params );
    my $template_name = $class->_template_name(
                                   \%params,
                                   $class->MY_SEARCH_RESULTS_TEMPLATE( \%params ) );
    return $R->template->handler( {}, \%params, { name => $template_name } );
}


sub _search_get_id {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    my $search_key = $class->MY_SEARCH_RESULTS_KEY;
    return $R->apache->param( $search_key );
}


# If the handler wants to save the search ID elsewhere (session,
# etc.), override this

sub _search_save_id { return $_[1] }


# Build the search and run it, returning an iterator

sub _search_build_and_run {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;

    # Grab the criteria and customize if necessary

    my $criteria = $class->_search_build_criteria( $p );

    my ( $tables, $where, $values ) =
                    $class->_search_build_where_clause( $criteria, $p );

    my ( $limit );
    if ( $p->{min} or $p->{max} ) {
        if ( $p->{min} and $p->{max} ) { $limit = "$p->{min},$p->{max}" }
        elsif ( $p->{max} )            { $limit = $p->{max} }
    }

    my $object_class = $class->MY_OBJECT_CLASS;

    if ( my $num_limit_results = $class->MY_SEARCH_RESULTS_CAP ) {
        my $row = eval { $object_class->db_select({ select => [ 'count(*)' ],
                                                    from   => $tables,
                                                    where  => $where,
                                                    value  => $values,
                                                    return => 'single' }) };
        if ( $row->[0] > $num_limit_results ) {
            my $msg = "Your search has returned too many results. " .
                      "(Limit: $num_limit_results) Please try again.";
            return ( undef,  $msg );
        }
    }

    $R->DEBUG && $R->scrib( 1, "RUN SEARCH (before): ", scalar localtime );
    my $order = $class->MY_SEARCH_RESULTS_ORDER;
    my $additional_params = $class->MY_SEARCH_ADDITIONAL_PARAMETERS || {};
    my $iter = eval { $object_class->fetch_iterator({
                                         from       => $tables,  where => $where,
                                         value      => $values,  limit => $limit,
                                         order      => $order,
                                         %{ $additional_params } }) };
    $R->DEBUG && $R->scrib( 1, "RUN SEARCH (after): ", scalar localtime );

    return ( $iter, undef ) unless ( $@ );

    $R->scrib( 0, "Search failed: $@\nClass: $class\n",
                  "FROM", join( ',', @{ $tables } ), "\n",
                  "WHERE $where\n",
                  "ORDER BY $order\n",
                  "VALUES", join( ',', @{ $values } ) );
    die "Search failed ($@)\n";
}


# Grab the specified fields and values out of the form
# submitted. Fields with multiple values are saved as arrayrefs.

sub _search_build_criteria {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    my $apr = $R->apache;
    my $object_class = $class->MY_OBJECT_CLASS;
    my $object_table = $object_class->base_table;
    my ( %search_params );

    # Go through each search field and assign a value. If the search
    # field is a simple one (no table.field), then prepend the object
    # table to the fieldname

    foreach my $field ( $class->MY_SEARCH_FIELDS ) {
        my @value = $apr->param( $field );
        next unless ( defined $value[0] and $value[0] ne '' );
        my $full_field = ( $field =~ /\./ )
                           ? $field : "$object_table.$field";
        $search_params{ $full_field } = ( scalar @value > 1 )
                                          ? \@value : $value[0];
    }
    $class->_search_criteria_customize( \%search_params, $p );
    $R->DEBUG && $R->scrib( 1, "($class) Found search parameters:\n",
                               Dumper( \%search_params ) );
    return \%search_params
}


# Build a WHERE clause -- parameters with multiple values are 'OR',
# everything else is 'AND'. Example:
#
#  ( table.last_name LIKE '%win%' OR table.last_name LIKE '%smi%' )
#  AND ( table.first_name LIKE '%john%' )

sub _search_build_where_clause {
    my ( $class, $search_criteria, $p ) = @_;
    my $R = OpenInteract::Request->instance;

    # Find all our configured information

    my $object_class = $class->MY_OBJECT_CLASS;
    my $object_table = $object_class->base_table;
    my %from_tables  = ( $object_table => 1 );
    my %exact_match        = map { $_ => 1 } $class->_fq_fields( $class->MY_SEARCH_FIELDS_EXACT );
    my %left_exact_match   = map { $_ => 1 } $class->_fq_fields( $class->MY_SEARCH_FIELDS_LEFT_EXACT );
    my %right_exact_match  = map { $_ => 1 } $class->_fq_fields( $class->MY_SEARCH_FIELDS_RIGHT_EXACT );

    # Go through each of the criteria set -- note that each one must
    # be a fully-qualified (table.field) fieldname or it is discarded.

    my ( @where, @value ) = ();
    foreach my $field_name ( keys %{ $search_criteria } ) {
        $R->DEBUG && $R->scrib( 2, "Testing ($field_name) with ",
                                   "($search_criteria->{ $field_name })" );
        next unless ( defined $search_criteria->{ $field_name } );

        # Discard non-qualified fieldnames. Note that this regex will
        # greedily swallow everything to the last '.' to accommodate
        # systems that use a 'db.table' syntax to refer to a table.

        my ( $table ) = $field_name =~ /^([\w\.]*)\./;
        next unless ( $table );

        # Track the table used

        $from_tables{ $table }++;

        # See if we're using one or multiple values

        my $value_list = ( ref $search_criteria->{ $field_name } )
                           ? $search_criteria->{ $field_name }
                           : [ $search_criteria->{ $field_name } ];

        # Hold the items for this particular criterion, which will be
        # join'd with an 'OR'

        my @where_param = ();
        foreach my $value ( @{ $value_list } ) {

            # Value must be defined to be set

            next unless ( defined $value and $value ne '' );

            # Default is a LIKE match (see POD)

            my $oper         = ( $exact_match{ $field_name } ) ? '=' : 'LIKE';
            push @where_param, " $field_name $oper ? ";
            my ( $search_value );
            if ( $exact_match{ $field_name } ) {
                $search_value = $value;
            }
            elsif ( $left_exact_match{ $field_name } ) {
                $search_value = "$value%";
            }
            elsif ( $right_exact_match{ $field_name } ) {
                $search_value = "%$value";
            }
            else {
                $search_value = "%$value%";
            }
            push @value, $search_value;
            $R->DEBUG && $R->scrib( 2, "Set ($field_name) $oper ($search_value)" );
        }
        push @where, '( ' . join( ' OR ', @where_param ) . ' )';
    }

    # Generate any statements needed to link tables for searching.

    # DO NOT replace '@tables_used' in the foreach with 'keys
    # %from_tables' since we may add items to %from_tables during the
    # loop. Also don't do an 'each %table_links' and then check to see
    # if the table is in %from_tables for the same reason.

    my %table_links = $class->MY_SEARCH_TABLE_LINKS;
    my @tables_used = keys %from_tables;
    foreach my $link_table ( @tables_used ) {
        my $id_link = $table_links{ $link_table };
        next unless ( $id_link );

        # See POD for what the values in MY_SEARCH_TABLE_LINKS mean

        if ( ref $id_link eq 'ARRAY' ) {
            my $num_linking_fields = scalar @{ $id_link };
            if ( $num_linking_fields == 2 ) {
                my ( $object_field, $link_field ) = @{ $id_link };
                $R->DEBUG && $R->scrib( 1, "Linking ($link_table) with my field ",
                                           "($object_field) to ($link_field)" );
                push @where, join( ' = ', "$object_table.$object_field",
                                          "$link_table.$link_field" );
            }

            # Remember to add the linking table to our FROM list!

            elsif ( $num_linking_fields == 3 ) {
                my ( $base_id_field, $middle_table, $link_id_field ) = @{ $id_link };
                $R->DEBUG && $R->scrib( 1, "Linking to ($link_table) through ",
                                           "($middle_table)" );
                push @where, join( ' = ', "$object_table.$base_id_field",
                                          "$middle_table.$base_id_field" );
                push @where, join( ' = ', "$middle_table.$link_id_field",
                                          "$link_table.$link_id_field" );
                $from_tables{ $middle_table }++;
            }
            else {
                $R->scrib( 0, "Cannot generate a link clause for ",
                              "($link_table) from ($class)" );
                die "Cannot generate linking clauses for ($link_table) from ",
                    "($class): if value of hash is an array reference it ",
                    "must have either two or three elements.\n";
            }
        }
        else {
            $R->DEBUG && $R->scrib( 1, "Straight link to ($link_table) with",
                                       "($id_link)" );
            push @where, join( ' = ', "$object_table.$id_link",
                                      "$link_table.$id_link" );
        }
    }

    my @tables = keys %from_tables;
    $class->_search_build_where_customize( \@tables, \@where, \@value, $p );

    my $clause = join( " AND ", @where );
    $R->DEBUG && $R->scrib( 1, "($class) Built WHERE clause\n",
                                "FROM:", join( ', ', @tables ), "\n",
                                "WHERE: $clause\n",
                                "VALUES:", join( ', ', @value ) );
    return ( \@tables, $clause, \@value );
}


# Take a list of fields and ensure that each one is fully-qualified

sub _fq_fields {
    my ( $class, @fields ) = @_;
    my $object_class = $class->MY_OBJECT_CLASS;
    my $object_table = $object_class->base_table;
    return map { ( /\./ ) ? $_ : "$object_table.$_" } @fields;
}



########################################
# DISPLAY
########################################


sub create {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_CREATE ) {
        $R->scrib( 0, "User requested create for ($class) and it's not allowed." );
        return '<h1>Error</h1><p>New objects of this type cannot be created.</p>';
    }
    unless ( $p->{level} >= $class->MY_OBJECT_CREATE_SECURITY ) {
        $R->scrib( 0, "Request for create ($class) denied - inadequate security" );
        return '<h1>Error</h1><p>You do not have permission to create new objects.</p>';
    }
    $p->{edit}          = 1;
    $p->{is_new_object} = 1;
    return $class->show( $p );
}


sub show {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_SHOW ) {
        $R->scrib( 0, "User requested show for ($class) and it's not allowed." );
        return '<h1>Error</h1><p>Objects of this type cannot be viewed.</p>';
    }
    $p ||= {};

    my %params = %{ $p };

    # Assumption: Only users with SEC_LEVEL_WRITE can edit. Maybe
    # create configuration for: object_update_level,
    # object_create_level so we can have different security levels for
    # create and modify?

    $params{do_edit} = ( $p->{edit} or $R->apache->param( 'edit' ) );

    # Setup our default info

    my $fail_method  = $class->MY_SHOW_FAIL_TASK;
    my $object_type  = $class->MY_OBJECT_TYPE;
    my $object_class = $class->MY_OBJECT_CLASS;
    my $id_field     = $object_class->id_field;
    my $object = $object_class->new;
    unless ( $p->{is_new_object} ) {
        $object = $p->{ $object_type } ||
                  eval { $class->fetch_object( $p->{ $id_field }, $id_field ) };
        return $class->$fail_method({ %params, error_msg => $@ }) if ( $@ );
    }

    # If this is a saved object, see if we're supposed to ensure it's
    # active. If the user is an admin, it doesn't matter.

    my $active_field = $class->MY_ACTIVE_CHECK;
    if ( ! $R->{auth}{is_admin} and $object->is_saved and $active_field ) {
        my $status = $object->{ $active_field };
        unless ( $status =~ /^\s*(y|yes|1)\s*$/i ) {
            $R->scrib( 0, "Object failed 'active' status check (Status: $status)" );
            my $error_msg = "This object is currently inactive. Please check later.";
            return $class->$fail_method({ %params, error_msg => $error_msg });
        }
        $R->DEBUG && $R->scrib( 1, "Object passed 'active' status check (Status: $status)" );
    }

    # Ensure the object can be edited -- remember, 'fetch_object'
    # ALWAYS returns an object or dies, so don't add another clause
    # testing for the existence of $object

    unless ( $params{do_edit} or $object->is_saved ) {
        $R->scrib( 0, "User has requested static display on a new object -- bailing." );
        my $error_msg = 'Sorry, I could not display the object you requested.';
        return $class->search_form({ error_msg => $error_msg });
    }

    # Set both 'object' and the object type equal to the object so the
    # template can use either.

    $params{task_security} = $p->{level};
    $params{object} = $params{ $object_type } = $object;
    $R->{page}{title} = $class->MY_OBJECT_FORM_TITLE;

    $class->_show_customize( \%params );
    my $template_name = $class->_template_name(
                                   \%params,
                                   $class->MY_OBJECT_FORM_TEMPLATE( \%params ) );
    return $R->template->handler( {}, \%params, { name => $template_name } );
}



########################################
# MODIFY
########################################

sub edit {
    my ( $class, $p ) = @_;
    $p ||= {};
    my $R = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_EDIT ) {
        $R->scrib( 0, "User requested edit for ($class) and it's not allowed." );
        return '<h1>Error</h1><p>Objects of this type cannot be edited.</p>';
    }

    $R->{page}{return_url} = $class->MY_EDIT_RETURN_URL;

    # Setup default info

    my $fail_method  = $class->MY_EDIT_FAIL_TASK;
    my $object_type  = $class->MY_OBJECT_TYPE;
    my $object_class = $class->MY_OBJECT_CLASS;
    my $id_field     = $object_class->id_field;
    my $object       = eval { $class->fetch_object( $p->{ $id_field }, $id_field ) };

    # If we cannot fetch the object for editing, there's clearly a bad
    # error and we should go back to the search form rather than the
    # display form.

    if ( $@ ) {
        return $class->$fail_method({ %{ $p }, error_msg => $@ });
    }

    # Assumption: SEC_LEVEL_WRITE is necessary. (Probably ok.)

    my $is_new       = ( ! $object->is_saved );
    my $object_level = ( $is_new ) ? SEC_LEVEL_WRITE : $object->{tmp_security_level};
    if ( $object_level < SEC_LEVEL_WRITE ) {
        my $error_msg = 'Sorry, you do not have access to modify this ' .
                        'object. No modifications made.';
        return $class->$fail_method({ %{ $p }, error_msg => $error_msg });
    }

    $R->scrib( 1, "Object is new object? ", ( $is_new ) ? 'yes' : 'no' );

    # We pass this to the customization routine so you can do
    # comparisons, set off triggers based on changes, etc.

    my $old_data = $object->as_data_only;

    # Assign values from the form (specified by MY_EDIT_FIELDS,
    # MY_EDIT_FIELDS_DATE, MY_EDIT_FIELDS_TOGGLED, ...)

    $class->_edit_assign_fields( $object );

    # If after customizing/inspecting the object you want to bail and
    # go somewhere else, return the status 'ERROR' and fill \%opts
    # with information on what you want to do. (Overriding this is
    # quite common -- see POD.)

    my ( $status, $opts ) = $class->_edit_customize( $object, $old_data );
    if ( $status == ERROR ) {
        $opts->{object} = $opts->{ $object_type } = $object;
        return $class->_execute_options( $opts );
    }

    my %show_params = ( %{ $p }, $object_type => $object, object => $object );
    eval { $object->save( $opts ) };
    if ( $@ ) {
        my $ei = OpenInteract::Error->set( SPOPS::Error->get );
        $R->scrib( 0, "Object ($object_type) save failed: $@ ($ei->{system_msg})" );
        $R->throw({ code => 407 });
        $show_params{error_msg} = "Object modification failed. Error found: $ei->{system_msg}";
        return $class->$fail_method( \%show_params );
    }

    $class->_edit_post_action_customize( $object, $old_data );

    $show_params{status_msg} = ( $is_new )
                                 ? 'Object created properly.'
                                 : 'Object saved properly with changes.';
    my $method = $class->MY_EDIT_DISPLAY_TASK;
    return $class->$method( \%show_params );
}


# Assign values from GET/POST to the object

sub _edit_assign_fields {
    my ( $class, $object ) = @_;
    my $R = OpenInteract::Request->instance;
    my $apr = $R->apache;
    my $object_type = $class->MY_OBJECT_TYPE;

    # Go through normal fields

    foreach my $field ( $class->MY_EDIT_FIELDS ) {
        my $value = $class->_read_field( $apr, $field );
        $R->DEBUG && $R->scrib( 1, "Object edit: ($object_type) ($field) ($value)" );
        $object->{ $field } = $value;
    }

    # Go through toggled (yes/no) fields

    foreach my $field ( $class->MY_EDIT_FIELDS_TOGGLED ) {
        my $value = $class->_read_field_toggled( $apr, $field );
        $R->DEBUG && $R->scrib( 1, "Object edit toggle: ($object_type) ($field) ($value)" );
        $object->{ $field } = $value;
    }

    # Go through date fields

    foreach my $field ( $class->MY_EDIT_FIELDS_DATE ) {
        my $value = $class->_read_field_date( $apr, $field );
        $R->DEBUG && $R->scrib( 1, "Object edit date: ($object_type) ($field) ($value)" );
        $object->{ $field } = $value;
    }

    # Go through datetime fields

    foreach my $field ( $class->MY_EDIT_FIELDS_DATETIME ) {
        my $value = $class->_read_field_datetime( $apr, $field );
        $R->DEBUG && $R->scrib( 1, "Object edit datetime: ($object_type) ($field) ($value)" );
        $object->{ $field } = $value;
    }

    return ( OK, undef );
}


########################################
# READ FIELDS
########################################

# Just return the value

sub _read_field {
    my ( $class, $apr, $field ) = @_;
    return $apr->param( $field );
}


# If any value, return 'yes', otherwise 'no'

sub _read_field_toggled {
    my ( $class, $apr, $field ) = @_;
    return ( $apr->param( $field ) ) ? 'yes' : 'no';
}


# Default is to have the year, month and day in three separate fields.

sub _read_field_date {
    my ( $class, $apr, $field ) = @_;
    my ( $y, $m, $d ) = ( $apr->param( $field . '_year' ),
                          $apr->param( $field . '_month' ),
                          $apr->param( $field . '_day' ) );
    return undef unless ( $y and $m and $d );
    return join( '-', $y, $m, $d );
}


sub _read_field_datetime {
    my ( $class, $apr, $field ) = @_;
    my $date = $class->_read_field_date( $apr, $field );
    return undef unless ( $date );
    my ( $h, $m, $am_pm ) = ( $apr->param( $field . '_hour' ),
                              $apr->param( $field . '_minute' ),
                              $apr->param( $field . '_am_pm' ) );
    unless ( $h and $m and $am_pm ) {
        $h = '12'; $m = '00'; $am_pm = 'AM';
    }
    return join( ' ', $date, "$h:$m $am_pm" );
}


sub _read_field_date_object {
    my ( $class, $apr, $field ) = @_;
    my $date = $class->_read_field_date( $apr, $field );
    return Class::Date->new( $date );
}


########################################
# REMOVE
########################################

sub remove {
    my ( $class, $p ) = @_;
    $p ||= {};
    my $R = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_REMOVE ) {
        $R->scrib( 0, "User requested remove for ($class) and it's not allowed." );
        return $class->search_form({
                  error_msg => 'Objects of this type cannot be removed.' });
    }

    my $apr = $R->apache;

    my $fail_method  = $class->MY_REMOVE_FAIL_TASK;
    my $object_type  = $class->MY_OBJECT_TYPE;
    my $object_class = $class->MY_OBJECT_CLASS;
    my $id_field     = $object_class->id_field;
    my $object       = eval { $class->fetch_object( $p->{ $id_field },
                                                    $id_field ) };

    if ( $@ ) {
        return $class->$fail_method({ %{ $p }, error_msg => $@ });
    }
    unless ( $object->is_saved ) {
        my $error_msg = 'Cannot fetch object for removal. No modifications made.';
        return $class->$fail_method({ %{ $p }, error_msg => $error_msg });
    }


    # Assumption: SEC_LEVEL_WRITE is necessary to remove. (Probably ok.)

    if ( $object->{tmp_security_level} < SEC_LEVEL_WRITE ) {
        my $error_msg = 'Sorry, you do not have access to remove this ' .
                        'object. No modifications made.';
        return $class->$fail_method({ %{ $p }, error_msg => $error_msg });
    }

    my %show_params = %{ $p };

    $class->_remove_customize( $object );
    eval { $object->remove };
    if ( $@ ) {
        my $ei = OpenInteract::Error->set( SPOPS::Error->get );
        $R->scrib( 0, "Cannot remove object ($object_type) ($@) ($ei->{system_msg})" );
        $R->throw({ code => 405 });
        $show_params{error_msg} = "Cannot remove object! See error log.";
        return $class->$fail_method( \%show_params );
    }

    $class->_remove_post_action_customize( $object );

    $show_params{status_msg} = 'Object successfully removed.';
    my $method = $class->MY_REMOVE_DISPLAY_TASK;
    return $class->$method( \%show_params );
}



########################################
# NOTIFY
########################################


sub notify {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_NOTIFY ) {
        $R->scrib( 0, "User requested notify for ($class) and it's not allowed." );
        return '<h1>Error</h1><p>Objects of this type cannot be sent.';
    }

    my $apr = $R->apache;
    my $object_class = $class->MY_OBJECT_CLASS;
    my @id_list      = $p->{id_list} || $apr->param( $class->MY_NOTIFY_ID_FIELD );
    my $email        = $p->{email}   || $apr->param( $class->MY_NOTIFY_EMAIL_FIELD );
    unless ( $email ) {
        return '<h2 align="center">Error</h2>' .
               '<p>Error: Cannot run notification: no email address given.</p>';
    }
    unless ( scalar @id_list ) {
        return '<h2 align="center">Error</h2>' .
               '<p>Error: Cannot run notification: no objects specified.</p>';
    }

    my @object_list = ();
    foreach my $id ( @id_list ) {
        my $object = eval { $object_class->fetch( $id ) };
        push @object_list, $object    if ( $object );
    }
    my %params = ( from_email => $class->MY_NOTIFY_FROM,
                   email      => $email,
                   subject    => $class->MY_NOTIFY_SUBJECT,
                   object     => \@object_list,
                   notes      => $apr->param( $class->MY_NOTIFY_NOTES_FIELD ),
                   type       => $class->MY_OBJECT_TYPE );
    $class->_notify_customize( \%params );
    if ( OpenInteract::SPOPS->notify( \%params ) ) {
        return '<h2 align="center">Success!</h2>' .
               '<p>Notification sent properly!</p>';
    }
    return '<h2 align="center">Error</h2>' .
           '<p>Error sending email. Please check error logs!</p>';
}


########################################
# WIZARD
########################################

# Wizard stuff is pretty simple -- a lot of the difficult stuff is done
# via javascript.


# Start the wizard (simple search form, usually)

sub wizard {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_WIZARD ) {
        $R->scrib( 0, "User requested wizard for ($class) and it's not allowed." );
        return '<h1>Error</h1><p>The wizard is not enabled for these objects.</p>';
    }
    $p ||= {};

    my %params = %{ $p };

    $R->{page}{title} = $class->MY_WIZARD_FORM_TITLE;
    $R->{page}{_simple_}++;

    $class->_wizard_form_customize( \%params );
    my $template_name = $class->_template_name(
                                   \%params,
                                   $class->MY_WIZARD_FORM_TEMPLATE( \%params ) );
    return $R->template->handler( {}, \%params, { name => $template_name } );
}


# Run the search and present results; note that we truncate the
# iterator results with a max of 50, so we don't have any issues with
# paged results or with the user typing 'a' for a last name and
# getting back 100000 items...

sub wizard_search {
    my ( $class, $p ) = @_;
    my $R = OpenInteract::Request->instance;
    unless ( $class->MY_ALLOW_WIZARD ) {
        $R->scrib( 0, "User requested wizard search for ($class) and it's not allowed." );
        return '<h1>Error</h1><p>The wizard is not enabled for these objects.</p>';
    }
    $p ||= {};

    my %params = %{ $p };
    ( $params{iterator}, $params{msg} ) =
                    $class->_search_build_and_run({ max => $class->MY_WIZARD_RESULTS_MAX });

    $R->{page}{title} = $class->MY_WIZARD_RESULTS_TITLE;
    $R->{page}{_simple_}++;

    $class->_wizard_search_customize( \%params );
    my $template_name = $class->_template_name(
                                   \%params,
                                   $class->MY_WIZARD_RESULTS_TEMPLATE( \%params ) );
    return $R->template->handler( {}, \%params, { name => $template_name } );
}



########################################
# TASK FLOW MANIPULATION
########################################

# Find relevant information in \%opts to execute. Potential information:
#  - class, method --> what to execute; if 'method' specified but not
#  'class', we use our own class
#  - action --> Lookup the action and pass in $opts
#  - error_msg: error message to pass around
#  - status_msg: status message to pass around
#  ... Whatever else is passed along

# Currently only used in edit()

sub _execute_options {
    my ( $class, $opts ) = @_;
    my $R = OpenInteract::Request->instance;
    if ( my $method = $opts->{method} ) {
        my $execute_class = $opts->{class} || $class;
        $R->DEBUG && $R->scrib( 1, "Executing ($execute_class) ($method) after bail." );
        return $execute_class->$method( $opts );
    }

    if ( $opts->{action} ) {
        my ( $execute_class, $method ) = $R->lookup_action( $opts->{action} );
        if ( $execute_class and $method ) {
            $R->DEBUG && $R->scrib( 1, "Executing ($execute_class) ($method) ",
                                       "from ($opts->{action} after bail." );
            return $execute_class->$method( $opts );
        }
    }
    return "Cannot find next execute operation.";
}



########################################
# GENERIC OBJECT FETCH
########################################

# ALWAYS RETURNS OBJECT OR DIES

# Retrieve a record: if no $id then return a new one; if $id throw a
# error and die if we cannot fetch; if object with $id not found,
# return a new one. You can always tell if the returned object is new
# by the '->is_saved()' flag (false if new, true if existing)

sub fetch_object {
    my ( $class, $id, @id_field_list ) = @_;
    my $R = OpenInteract::Request->instance;

    unless ( $id ) {
        my $apr = $R->apache;
        foreach my $id_field ( @id_field_list ) {
            $id = $apr->param( $id_field );
            last if ( $id );
        }
    }

    my $object_class = $class->MY_OBJECT_CLASS;

    return $object_class->new  unless ( $id );

    my $object = eval { $object_class->fetch( $id ) };
    unless ( $@ ) {
        $object ||= $object_class->new;
        $class->_fetch_object_customize( $object );
        return $object;
    }

    my $ei = OpenInteract::Error->set( SPOPS::Error->get );
    my $error_msg = undef;
    if ( $ei->{type} eq 'security' ) {
        $error_msg = "Permission denied: you do not have access to view " .
                     "the requested object. ";
    }
    else {
        $R->throw({ code => 404 });
        $error_msg = "Error encountered trying to retrieve object. The " .
                     "error has been logged. "
    }
    die "$error_msg\n";
}


########################################
# OTHER
########################################

# Common template name specification

sub _template_name {
    my ( $class, $p, $default_name ) = @_;
    return $p->{template_name} if ( $p->{template_name} );
    my $package  = $class->MY_PACKAGE;
    my $template = $default_name;
    return join( '::', $package, $template );
}


########################################
# MANDATORY CONFIGURATION
########################################

sub MY_PACKAGE {
    die "Please define class method MY_PACKAGE() in $_[0]\n";
}
sub MY_OBJECT_TYPE {
    die "Please define class method MY_OBJECT_TYPE() in $_[0]\n";
}


########################################
# DEFAULT CONFIGURATION
########################################

sub MY_HANDLER_PATH            { return '/' . $_[0]->MY_OBJECT_TYPE }
sub MY_OBJECT_CLASS {
    my $object_type = $_[0]->MY_OBJECT_TYPE;
    return OpenInteract::Request->instance->$object_type();
}

sub MY_ALLOW_SEARCH_FORM         { return 1 }
sub MY_SEARCH_FORM_TITLE         { return 'Search Form' }
sub MY_SEARCH_FORM_TEMPLATE      { return 'search_form' }

sub MY_ALLOW_SEARCH              { return 1 }
sub MY_SEARCH_FIELDS             { return () }
sub MY_SEARCH_FIELDS_EXACT       { return () }
sub MY_SEARCH_FIELDS_LEFT_EXACT  { return () }
sub MY_SEARCH_FIELDS_RIGHT_EXACT { return () }
sub MY_SEARCH_TABLE_LINKS        { return () }
sub MY_SEARCH_ADDITIONAL_PARAMETERS { return {} }
sub MY_SEARCH_FAIL_TASK          { return 'search_form' }
sub MY_SEARCH_RESULTS_CAP        { return 0 }
sub MY_SEARCH_RESULTS_CAP_FAIL_TASK { return 'search_form' }
sub MY_SEARCH_RESULTS_ORDER      { return undef }
sub MY_SEARCH_RESULTS_PAGED      { return undef }
sub MY_SEARCH_RESULTS_KEY        { return $_[0]->MY_OBJECT_TYPE . '_search_id' }
sub MY_SEARCH_RESULTS_PAGE_SIZE  { return 50 }
sub MY_SEARCH_RESULTS_PAGE_FIELD { return 'pagenum' }
sub MY_SEARCH_RESULTS_TITLE      { return 'Search Results' }
sub MY_SEARCH_RESULTS_TEMPLATE   { return 'search_results' }

sub MY_ALLOW_SHOW                { return 1 }
sub MY_SHOW_FAIL_TASK            { return 'search_form' }
sub MY_ACTIVE_CHECK              { return undef }
sub MY_OBJECT_FORM_TITLE         { return 'Object Detail' }
sub MY_OBJECT_FORM_TEMPLATE      { return 'object_form' }

sub MY_ALLOW_CREATE              { return undef }
sub MY_OBJECT_CREATE_SECURITY    { return SEC_LEVEL_WRITE }

sub MY_ALLOW_EDIT                { return undef }
sub MY_EDIT_RETURN_URL           { return $_[0]->MY_HANDLER_PATH . '/' }
sub MY_EDIT_FIELDS               { return () }
sub MY_EDIT_FIELDS_TOGGLED       { return () }
sub MY_EDIT_FIELDS_DATE          { return () }
sub MY_EDIT_FIELDS_DATETIME      { return () }
sub MY_EDIT_FAIL_TASK            { return 'search_form' }
sub MY_EDIT_DISPLAY_TASK         { return 'show' }

sub MY_ALLOW_REMOVE              { return undef }
sub MY_REMOVE_FAIL_TASK          { return 'search_form' }
sub MY_REMOVE_DISPLAY_TASK       { return 'search_form' }

sub MY_ALLOW_NOTIFY              { return undef }
sub MY_NOTIFY_FROM               { return undef }
sub MY_NOTIFY_SUBJECT            { return '' }
sub MY_NOTIFY_ID_FIELD           { my $oc = $_[0]->MY_OBJECT_CLASS; return $oc->id_field }
sub MY_NOTIFY_EMAIL_FIELD        { return 'email' }
sub MY_NOTIFY_NOTES_FIELD        { return 'notes' }

sub MY_ALLOW_WIZARD              { return undef }
sub MY_WIZARD_FORM_TITLE         { return 'Wizard: Search' }
sub MY_WIZARD_FORM_TEMPLATE      { return 'wizard_form' }
sub MY_WIZARD_RESULTS_MAX        { return 50 }
sub MY_WIZARD_RESULTS_TITLE      { return 'Wizard: Results' }
sub MY_WIZARD_RESULTS_TEMPLATE   { return 'wizard_results' }


########################################
# CUSTOMIZATION INTERFACE
########################################

# Template/param modifications
sub _search_form_customize        { return 1 }
sub _search_customize             { return 1 }
sub _show_customize               { return 1 }
sub _notify_customize             { return 1 }
sub _wizard_form_customize        { return 1 }
sub _wizard_search_customize      { return 1 }

# Criteria/Object modifications
sub _search_criteria_customize    { return $_[1] }
sub _search_build_where_customize { return 1 }
sub _fetch_object_customize       { return $_[1] }
sub _edit_customize               { return ( OK, undef ) }
sub _edit_post_action_customize   { return 1 }
sub _remove_customize             { return 1 }
sub _remove_post_action_customize { return 1 }


1;

__END__

=head1 NAME

OpenInteract::CommonHandler - Base class that with a few configuration items takes care of many common operations

=head1 SYNOPSIS

 package MySite::Handler::MyTask;

 use strict;
 use OpenInteract::CommonHandler;

 @MySite::Handler::MyTask::ISA = qw( OpenInteract::CommonHandler );

 sub MY_PACKAGE                 { return 'mytask' }
 sub MY_HANDLER_PATH            { return '/MyTask' }
 sub MY_OBJECT_TYPE             { return 'myobject' }
 sub MY_OBJECT_CLASS            {
     return OpenInteract::Request->instance->myobject
 }
 sub MY_SEARCH_FIELDS {
     return qw( name type quantity purpose_in_life that_other.object_name )
 }
 sub MY_SEARCH_TABLE_LINKS      { return ( that_other => 'myobject_id' ) }
 sub MY_SEARCH_FORM_TITLE       { return 'Search for Thingies' }
 sub MY_SEARCH_FORM_TEMPLATE    { return 'search_form' }
 sub MY_SEARCH_RESULTS_TITLE    { return 'Thingy Search Results' }
 sub MY_SEARCH_RESULTS_TEMPLATE { return 'search_results' }
 sub MY_OBJECT_FORM_TITLE       { return 'Thingy Detail' }
 sub MY_OBJECT_FORM_TEMPLATE    { return 'form' }
 sub MY_EDIT_RETURN_URL         { return '/Thingy/search_form/' }
 sub MY_EDIT_FIELDS             {
     return qw( myobject_id name type quantity purpose_in_life )
 }
 sub MY_EDIT_FIELDS_TOGGLED     { return qw( is_indoctrinated ) }
 sub MY_EDIT_FIELDS_DATE        { return qw( birth_date ) }
 sub MY_ALLOW_SEARCH_FORM       { return 1 }
 sub MY_ALLOW_SEARCH            { return 1 }
 sub MY_ALLOW_SHOW              { return 1 }
 sub MY_ALLOW_CREATE            { return 1 }
 sub MY_ALLOW_EDIT              { return 1 }
 sub MY_ALLOW_REMOVE            { return undef }
 sub MY_ALLOW_WIZARD            { return undef }
 sub MY_ALLOW_NOTIFY            { return 1 }

 # My date format is for users to type in 'yyyymmdd'

 sub _read_field_date {
    my ( $class, $apr, $field ) = @_;
    my $date_value = $apr->param( $field );
    $date_value =~ s/\D//g;
    my ( $y, $m, $d ) = $date_value =~ /^(\d\d\d\d)(\d\d)(\d\d)$/;
    return undef unless ( $y and $m and $d );
    return join( '-', $y, $m, $d );
 }

 1;

=head1 DESCRIPTION

This class implements most of the common functionality required for
finding and displaying multiple objects, viewing a particular object,
making changes to it and removing it. And you just need to modify a
few configuration methods so that it knows what to save, where to save
it and what type of things you are doing.

This class is meant for the bread-and-butter of many web applications
-- enable a user to find, view and edit a particular object. Why keep
writing these parts again and again? And if you have more extensive
needs, it is very easy to still let this class do most of the work and
you can concentrate on the differences, making more maintainable code
and more sane programmers.

We break the process down into tasks, each task basically
corresponding to a particular URL class. (For instance,
'/MyApp/show/?myobject_id=4927' is a 'show' task that displays the
object with ID 4927.)

Every task allows you to customize an object, means for finding
objects or the parameters passed to the template. Each of these
methods take two arguments -- the first argument is always the class,
and the second is either the information (object, search criteria) to
be modified or a hashref of template parameters. (More detail below.)

In this documentation, we first list all the available tasks with a
brief description of what they do. Note that these are tasks
implemented for you, you are B<always> free to create your own.

Next, we go into depth for each task and describe how you configure it
and how you can customize its behavior.

=head1 TASK METHODS

This class supplies the following methods for direct use as tasks. If
you override one, you need to supply content. You can, of course, add
your own methods (e.g., a 'summary()' method which displays the object
information in static detail along with related objects).

=over 4

=item *

B<search_form()>: Display a search form.

=item *

B<search()>: Execute a search and display results.

=item *

B<create()>: Alias for C<show()> that displays an entry form for a
single record.

=item *

B<show()>: Display a single record.

=item *

B<edit()>: Modify a single record.

=item *

B<remove()>: Remove a single record.

=item *

B<notify()>: Email one or more objects in human-readable format.

=item *

B<wizard()>: Start the search wizard (generally display a search
criteria page).

=item *

B<wizard_search()>: Run the search wizard and display the results.

=back

=head1 CUSTOMIZATION TYPES

=over 4

=item *

B<Template Customizations>

These methods allow you to step in and modify any template parameters
that you like.

You can modify the template that any of these will use by setting the
parameter 'template_name'. If you set the template name yourself you
need to set it to a fully-qualified name, such as
'mypackage::mytemplate'.

=item *

B<Data Customizations>

These methods allow you to step in and modify the data being displayed
or processed. Read up on the specific customization method for the
exact parameters you can change and what is available to you.

=head1 OVERALL

These are configuration and customization items that are not specific
to a particular task.

=head2 Configuration

B<MY_PACKAGE()> ($)

Name of this package.

B<MY_OBJECT_TYPE()> ($)

Object type (e.g., 'user', 'news', etc.)

B<MY_HANDLER_PATH()> ($) (optional)

Path of handler.

Default: '/' . MY_OBJECT_TYPE

B<MY_OBJECT_CLASS()> ($) (optional)

Object class.

Default: Gets object class from C<$R> using C<MY_OBJECT_TYPE>:

=head2 Customizatiion

B<_fetch_object_customize( $object )>

Called just before an object is returned via C<fetch_object()>. You
have the option of looking at C<$object> and making any necessary
modifications.

Note that C<fetch_object()> is not called when returning objects from
a search, only when manipulating a single object with C<show()>,
C<edit()> or C<remove()>.

=head1 TASK: SEARCH FORM

=head2 Configuration

B<MY_ALLOW_SEARCH_FORM()> (bool) (optional)

Should the search form be viewed?

Default: true

B<MY_SEARCH_FORM_TITLE()> ($) (optional)

Set the title for the search form.

Default: 'Search for Thingies'

B<MY_SEARCH_FORM_TEMPLATE()> ($) (optional)

Name of the search form template.

Default: C<MY_PACKAGE> . '::search_form'

=head2 Customization

B<_search_form_customize( \%template_params )>

Template customization. Typically there are no parameters to
set/manipulate except possibly 'error_msg' or 'status_msg' if called
from other methods.

=head1 TASK: SEARCH

=head2 Configuration

B<MY_ALLOW_SEARCH()> (bool) (optional)

Should searches be allowed?

Default: true

B<MY_SEARCH_FAIL_TASK()> ($) (optional)

Task to run if your search fails. The parameter 'error_msg' will be
set to an appropriate message which you can display.

Default: search_form

B<MY_SEARCH_RESULTS_CAP()> ($) (optional)

Constrains the max number of records returned. If this is set we run a
'count(*)' query using the search criteria before running the
search. If the result is greater than the number set here, we call
B<MY_SEARCH_RESULTS_CAP_FAIL_TASK> with an error message set in the
'error_msg' parameter about the number of records that would have been
returned.

Note that this is a somewhat crude measure of the records returned
because it does not take into account security checks. That is, a
search that returns 500 records from the database could conceivably
return only 100 records after security checks. Keep this in mind when
setting the value.

Default: 0 (no cap)

B<MY_SEARCH_RESULTS_CAP_FAIL_TASK()> ($) (optional)

Task to run in this class when a search exceeds the figure set in
B<MY_SEARCH_RESULTS_CAP>. The task is run with a relevant message in
the 'error_msg' parameter.

Default: search_form

B<MY_SEARCH_RESULTS_PAGED()> (bool) (optional)

Set to a true value to enable paged results, meaning that search
results will come back in groups of B<MY_SEARCH_RESULTS_PAGE_SIZE>. We
use the methods in 'results_manage' to accomplish this.

Note: If your objects are not retrievable through a single ID field,
you will not be able to page your results automatically. You should be
able to do this by hand in the future.

Default: false.

B<MY_SEARCH_RESULTS_PAGE_FIELD()> ($) (optional)

If B<MY_SEARCH_RESULTS_PAGED> is true this is the parameter we will
check to see what page number of the results the user is requesting.

Default: 'pagenum'.

B<MY_SEARCH_RESULTS_PAGE_SIZE()> ($) (optional)

If B<MY_SEARCH_RESULTS_PAGED> is set to a true value we output pages
of this size.

Default: 50

B<MY_SEARCH_RESULTS_KEY()> ($) (optional)

If B<MY_SEARCH_RESULTS_PAGED> is true this routine will generate a key
under which you will save the ID to get your persisted search
results. We make the search ID accessible in the template parameters
under this name as well as 'search_id'.

Default: C<MY_OBJECT_CLASS()> . '_search_id'

B<MY_SEARCH_RESULTS_TITLE()> ($) (optional)

Title of search results page.

Default: 'Search Results'

B<MY_SEARCH_RESULTS_TEMPLATE()> ($) (optional)

Search results template name.

Default: 'search_results'

B<MY_SEARCH_FIELDS()> (@) (optional)

List of fields used to build search. This can include fields from
other tables. Fields from other tables must be fully-qualified with
the table name.

For instance, for a list of fields used to find users, I might list:

 sub MY_SEARCH_FIELDS { return qw( login_name last_name group.name ) }

Where 'group.name' is a field from another table. I would then have to
configure B<MY_SEARCH_TABLE_LINKS> (below) to tell CommonHandler how
to link my object with that table.

These are the actual parameters from the form used for searching. If
the names do not match up, such as if you fully-qualify your names in
the configuration but not the search form, then you will not get the
criteria you think you will. An obvious symptom of this is running a
search and getting many more records than you expected, maybe even all
of them.

No default.

B<MY_SEARCH_FIELDS_EXACT()> (@) (optional)

Returns fields from C<MY_SEARCH_FIELDS> that must be an exact match.

This is used in C<_search_build_where_clause()>. If the field being
searched is an exact match, we use '=' as a search test.

Otherwise we use 'LIKE' and, if the field is not in
C<MY_SEARCH_FIELDS_LEFT_EXACT> or C<MY_SEARCH_FIELDS_RIGHT_EXACT> (see
below), wrap the value in '%'.

If you need other custom behavior, do not include the field in
C<MY_SEARCH_FIELDS> and use C<_search_build_where_customize()> to set.

No default.

B<MY_SEARCH_FIELDS_LEFT_EXACT()> (@) (optional)

Returns fields from C<MY_SEARCH_FIELDS> that must match exactly on the
left-hand side. This sets up:

 $fieldname LIKE "$fieldvalue%"

No default.

B<MY_SEARCH_FIELDS_RIGHT_EXACT()> (@) (optional)

Returns fields from C<MY_SEARCH_FIELDS> that must match
exactly on the right-hand side. This sets up:

 $fieldname LIKE "%$fieldvalue"

No default.

B<MY_SEARCH_TABLE_LINKS()> (%) (optional)

Returns table name => ID field mapping used to build WHERE
clauses that JOIN multiple tables when executing a search.

A key is a table name, and the value enables us to build a join clause
to link table specified in the key to the table containing the object
being searched. The value is either a scalar or an arrayref.

If a scalar, the value is just the ID field in the destination table
that the ID value in the object maps to:

  sub MY_SEARCH_TABLE_LINKS { return ( address => 'user_id' ) }

This means that the table 'address' contains the field 'user_id' which
the ID of our object matches.

If the value is an arrayref that means one of two things, depending on
the number of elements in the arrayref.

First, a two-element arrayref. This means we are have a non-key field
in our object which matches up with a key field in another object.

The elements are:

 0: Fieldname in the object
 1: Fieldname in the other table

(Frequently these are the same, but they do not have to be.)

For instance, say we have a table of people records and a table of
phone log records. Each phone log record has a 'person_id' field, but
we want to find all the phone log records generated by people who have
a last name with 'mith' in it.

 sub MY_SEARCH_TABLE_LINKS {
     return ( person => [ 'person_id', 'person_id' ] ) }

Which will generate a WHERE clause like:

  WHERE person.last_name LIKE '%mith%'
    AND phonelog.person_id = person.person_id

Second, a three-element arrayref. This means we are using a linking
table to do the join. The values of the arrayref are:

 0: ID field matching the object ID field on the linking table
 1: Name of the linking table
 2: Name of the ID field on the destination table

So you could have the setup:

  user (user_id) <--> user_group (user_id, group_id) <--> group (group_id)

and:

  sub MY_SEARCH_TABLE_LINKS {
      return ( group => [ 'user_id', 'user_group', 'group_id' ] ) }

And searching for a user by a group name with 'admin' would give:

  WHERE group.name LIKE '%admin%'
    AND group.group_id = user_group.group_id
    AND user_group.user_id = user.user_id

No default.

B<MY_SEARCH_RESULTS_ORDER()> ($) (optional)

An 'ORDER BY' clause used to order your results. The CommonHandler
makes sure to include the fields used to order the results in the
SELECT statement, since many databases will complain about their
absence.

No default.

B<MY_SEARCH_ADDITIONAL_PARAMS()> (\%) (optional)

If you want to pass additional parameters directly to the SPOPS
C<fetch_iterator()> call, return them here. For instance, if you want
to skip security for a particular search you would create:

 sub MY_SEARCH_ADDITIONAL_PARAMS { return { skip_security => 1 } }

Default: An empty hashref (no parameters)

=head2 Customization

B<_search_customize( \%template_params )>

Template customization. If you are not using paged results there is
only the parameter 'iterator' set. If you use paged results, then
there is 'iterator' as well as:

=over 4

=item *

C<page_number_field>

=item *

C<current_page>

=item *

C<total_pages>

=item *

C<total_hits>

=item *

C<search_id>

=item *

C<search_results_key>

=back

B<_search_criteria_customize( \%search_criteria )>

Data customization. Modify the items in C<\%search_criteria> as
necessary. The format is simple: a key is a fully-qualified
(table.field) fieldname, and its value is either a scalar or arrayref
depending on whether multiple values were passed.

For instance, say we wanted to restrict searches to all objects with
an 'active' property of 'yes':

 sub _search_criteria_customize {
    my ( $class, $criteria ) = @_;
    $criteria->{'mytable.active'} = 'yes';
 }

Easy! Other possibilities include selecting objects based on qualities
of the user -- say certain objects should only be included in a search
if the user is a member of a particular group. Since C<$R> is
available to you, it is simple to check whether the user is a member
of a group and make necessary modifications.

Note that you must use the fully-qualified 'table.field' format for
the criteria key or the criterion will be discarded.

The method should always return the hashref of criteria. Failure to do
so will likely retrieve all objects in the database, which is
frequently a Bad Thing.

B<_search_build_where_customize( \@tables, \@where, \@values )>

Data customization. Allows you to hand-modify the WHERE clause that
will be used for searching. If you override this method, you will be
passed three arguments:

=over 4

=item 1.

B<\@tables>: An arrayref of tables that are used in the WHERE clause
-- they become the FROM clause of our search SELECT. If you add a JOIN
or other clause that depends on a separate table then be sure to add
it here -- otherwise the search will fail mightily.

=item 2.

B<\@where>: An arrayref of operations that will be joined together
with 'AND' before being passed to the C<search()> method.

=item 3.

B<\@values>: An arrayref of values that will be plugged into the
operations.

=back

This might seem a little confusing, but as usual it is easier to show
than tell. For example, we want to allow the user to select a date in
a search form and find all items one week after and one week before
that date:

 sub _search_build_where_customize {
     my ( $class, $table, $where, $value ) = @_;
     my $R = OpenInteract::Request->instance;
     my $search_date = $class->_read_field_date( 'pivot_date' );
     push @{ $where },
       "( TO_DAYS( ? ) BETWEEN ( TO_DAYS( pivot_date ) + 7 ) " .
       "AND ( TO_DAYS( pivot_date ) - 7 ) )";
     push @{ $value }, $search_date;
 }

=head1 TASK: CREATE

This task is just an alias for C<show()>, passing along a true value
for both the 'edit' and 'is_new_object' parameters, which C<show()>
can inspect to do the right thing.

=head2 Configuration

B<MY_ALLOW_CREATE()> (bool) (optional)

Should shortcut to display a form to create a new object be allowed?

Default: false

B<MY_OBJECT_CREATE_SECURITY()> (security level) (optional)

Security required to create an object -- this should be a constant
from L<SPOPS::Secure|SPOPS::Secure>

Default: SEC_LEVEL_WRITE

=head2 Customization

None.

=head1 TASK: SHOW

=head2 Configuration

B<MY_ALLOW_SHOW()> (bool) (optional)

Should object display be allowed?

Default: true

B<MY_SHOW_FAIL_TASK()> ($) (optional)

If the display of the object fails -- cannot fetch it, object is not
active, etc. -- then what method should we run? Whatever method is run
should be able to display the error message (in 'error_msg') so the
user knows what happened.

Default: 'search_form'

B<MY_ACTIVE_CHECK()> ($) (optional)

Should we check to see if the object is active before displaying it?
If true, the return value from this method should be the field to
check for a value of 'yes' or '1'.

If you do not want to check the 'active' status of an object, leave
this blank (the default).

Default: undef

B<MY_OBJECT_FORM_TITLE()> ($) (optional)

Title of object editing page.

Default: 'Object Detail'

B<MY_OBJECT_FORM_TEMPLATE()> ($) (optional)

Object form template name.

Default: 'object_form'

=head2 Customization

B<_show_customize( \%template_params )>

Typically there are only the parameters 'object' and C<MY_OBJECT_TYPE>
set to the same value.

Note that this task does not differentiate between displaying an
object in an editable form and in a static (non-editable) display. If
you want to use this task to do both, you can use this customization
to set the template name based on the security status of the object.

For instance:

 sub _show_customize {
     my ( $class, $params ) = @_;
     $params->{template_name} = ( $params->{object}{tmp_security_level} < SEC_LEVEL_WRITE )
                                  ? 'mypkg::static_display' : 'mypkg::form_display';
 }

=head1 TASK: EDIT

=head2 Configuration

B<MY_ALLOW_EDIT()> (bool) (optional)

Should edits be allowed?

Default: false

B<MY_EDIT_RETURN_URL()> ($) (optional)

URL to use as return when displaying the 'edit' page. (If
you do not define this weird things can happen if users logout from
the editing page.)

Default: MY_HANDLER_PATH . '/'

B<MY_EDIT_FIELDS()> (@) (optional)

Fields for CommonHandler to retrieve values from the form and set into
the object. You can set other values by hand using
C<_edit_customize()>.

You can also specify fields to be handled automatically by
CommonHandler in C<MY_EDIT_FIELDS_TOGGLED> and C<MY_EDIT_FIELDS_DATE>.

No default.

B<MY_EDIT_FIELDS_TOGGLED()> (@) (optional)

List of fields that are either 'yes' or 'no'. If any true value (as
perl defines it) is read in then the value of the field is set to
'yes', otherwise it is set to 'no'.

No default

B<MY_EDIT_FIELDS_DATE()> (@) (optional)

List of fields that are dates. If users are editing raw dates and the
field value does not need to be manipulated before entering the
database, then just keep such fields in C<MY_EDIT_FIELDS> since they
do not need to be treated differently. The default is to read the date
from three separate fields, but you can override C<_read_field_date()>
for your own needs.

No default

B<MY_EDIT_FAIL_TASK()> ($) (optional)

Specify the task to run when the edit fails for any reason -- except
if you specify a different task to run when returning from
C<_edit_customize()> with an error.

Default: 'search_form'

B<MY_EDIT_DISPLAY_TASK()> ($) (optional)

Task we should execute after we have edited the record.

Default 'show' (re-displays the form you just edited with a status
message)

=head2 Customization

B<_edit_customize( $object, \%old_data )>

Called just before an object is saved to the datastore. This is most
useful to perform any custom data retrieval, data manipulation or
validation. Data present in the object before any modifications is
passed as a hashref in the second argument.

Return value is a two-element list: the first is the status -- either
'OK' or 'ERROR' as exported by this module. The second is a hashref of
options whose contents depend on whether you return 'OK' or 'ERROR'.

If you return 'ERROR', thenthe options specify what to do next. If you
return 'OK', then the options get passed to the object C<save()> call,
which can be useful if for instance you need to tell SPOPS that a the
action is a creation even if it looks like an update.

Example. Data validation might look something like:

 package My::Handler::MyHander;

 use OpenInteract::CommonHandler qw( OK ERROR );

 my %required_label = ( name => 'Name', quest => 'Quest',
                        favorite_color => 'Favorite Color' );

 # ... Override the various configuration routines ...

 sub _edit_customize {
     my ( $class, $object, $old_data ) = @_;
     my @msg = ();
     foreach my $field ( keys %required_label ) {
         if ( $object->{ $field } eq '' or ! defined $object->{ $field } ) {
            push @msg, "$required_label{ $field } is a required field. " .
                       "Please enter data for it.";
        }
     }
     return ( OK, undef ) unless ( scalar @msg );
     return ( ERROR, { error_msg => join( "<br>\n", @msg ),
                       method    => 'show' } );
 }

So if any of the required fields are not filled in, the method returns
'ERROR' and a hashref with the method to execute on error, in this
case 'show' to redisplay the same object along with the error message
to display.

You can specify an action to execute in one of three ways:

=over 4

=item *

B<method>: Calls C<$method()> in the current class.

=item *

B<class>, B<method>: Calls C<$class-E<gt>$method()>.

=item *

B<action>: Calls the method and class specified by C<$action>.

=back

=head1 TASK: REMOVE

=head2 Configuration

B<MY_ALLOW_REMOVE()> (bool) (optional)

Should removals be allowed?

Default: false

B<MY_REMOVE_FAIL_TASK()> ($) (optional)

Task to run if the remove fails for any reason.

Default: 'search_form'

B<MY_REMOVE_DISPLAY_TASK()> ($) (optional)

Task to run after the remove completes

Default: 'search_form'

=head2 Customization

B<_remove_customize( $object )>

Called just before an object is removed from the datastore.

=head1 TASK: NOTIFY

=head2 Configuration

B<MY_ALLOW_NOTIFY()> (bool) (optional)

Should notify requests be fulfilled?

Default: false

B<MY_NOTIFY_FROM> ($) (optional)

Address from which the message should come.

Default: 'admin_email' value from server configuration (see
L<OpenInteract::SPOPS|OpenInteract::SPOPS> for more info).

B<MY_NOTIFY_ID_FIELD()> ($) (optional)

Specify the field used to grab ID values for objects to notify.

Default: C<MY_OBJECT_CLASS()>-E<gt>id_field();

B<MY_NOTIFY_EMAIL_FIELD()> ($) (optional)

Specify the field used for the address to which the notification
should be sent.

Default: 'email'

B<MY_NOTIFY_NOTES_FIELD()> ($) (optional)

Specify the field used for notes that will be sent along with the
notification.

Default: 'notes'

B<MY_NOTIFY_SUBJECT()> ($) (optional)

Subject of email to be sent out.

Default: "Object notification: $num_objects objects in mail"

=head2 Customization

B<_notify_customize( \%params )>

Data customization. The C<\%params> hashref has the following keys you
can modify. All keys/values get sent on to the C<notify()> method of
L<OpenInteract::SPOPS|OpenInteract::SPOPS>:

=over 4

=item *

B<from_email>: Address message is from (C<MY_NOTIFY_FROM>)

=item *

B<email>: Address message is to (value in C<MY_NOTIFY_EMAIL_FIELD>)

=item *

B<subject>: Subject of message (C<MY_NOTIFY_SUBJECT>)

=item *

B<object>: Object(s) fetched from specified IDs (values in C<MY_NOTIFY_ID_FIELD>)

=item *

B<notes>: Notes in message (value in C<MY_NOTIFY_NOTES_FIELD>)

=item *

B<type>: Type of object (C<MY_OBJECT_TYPE>)

=back

=head1 TASK: WIZARD

This class contains some simple support for search wizards. With such
a wizard you can use OpenInteract in conjunction with JavaScript to
implement a 'Find...' widget so you can link one object to another
easily.

=head2 Configuration

B<MY_ALLOW_WIZARD()> (bool) (optional)

Whether to enable the wizard.

Default: false

B<MY_WIZARD_FORM_TITLE()> ($) (optional)

Title of wizard search form page.

Default: 'Wizard: Search'

B<MY_WIZARD_FORM_TEMPLATE()> ($) (optional)

Name of wizard search form template.

Default: 'wizard_form'

=head2 Customization

B<_wizard_form_customize( \%params )>

Template customization.

=head1 TASK: WIZARD SEARCH

=head2 Configuration

B<MY_ALLOW_WIZARD()> (bool) (optional)

Whether to enable the wizard.

Default: false

B<MY_WIZARD_RESULTS_MAX()> ($) (optional)

Max number of results to return.

Default: 50

B<MY_WIZARD_RESULTS_TITLE()> ($) (optional)

Title of wizard search results page.

Default: 'Wizard: Results'

B<MY_WIZARD_RESULTS_TEMPLATE()> ($) (optional)

Name of wizard search results template

Default: 'wizard_results'

=head2 Customization

B<_wizard_search_customize( \%params )>

Template customization. Customize output of the search results.

=head1 INTERNAL BEHAVIOR

B<_search_build_criteria()>

Scans the GET/POST for relevant (as specified by C<MY_SEARCH_FIELDS>)
search criteria and puts them into a hashref. Multiple values are put
into an arrayref, single values into a scalar.

We call C<_search_criteria_customize()> on the criteria just before
they are passed back to the caller.

Returns: Hashref of search fields and values entered.

B<_search_build_where_clause( \%search_criteria )>

Builds a WHERE clause suitable for a SQL SELECT statement. It can
handle table links with configuration information available in
C<MY_SEARCH_TABLE_LINKS>.

Returns: Three-value array: the first value is an arrayref of tables
used in the search, including the object table itself; the second
value is the actual WHERE clause, the third value is an arrayref of
the values used in the WHERE clause.

We call C<_search_build_where_customize()> with the three arrayrefs
just before returning them.

B<_edit_assign_fields( $object )>

If you override this method you will have to read all the information
from the GET/POST to the object. See below C<FIELD VALUE BEHAVIOR> for
useful methods in doing this.

=head2 Object Retrieval

B<fetch_object( $id, [ $id_field, $id_field, ... ] )>

This method is slightly different than the rest. It retrieves a
particular object for you, given either the ID value in C<$id> or
given the ID value found in the first one of C<$id_field> that is
defined in the GET/POST.

Returns: This method B<always> returns an object. If it does not
return an object it will C<die()>. If an object is not retrieved due
to an ID value not being found or a matching object not being found, a
B<new> (empty) object is returned.

Depends on:

C<MY_OBJECT_CLASS>

=head2 Field Values

B<_read_field( $apache_request, $field_name )>

Just returns the value of C<$field_name> as read from the GET/POST.

B<_read_field_toggled( $apache_request, $field_name )>

If C<$field_name> is set to a true value, returns 'yes', otherwise
returns 'no'.

B<_read_field_date( $apache_request, $field_name )>

By default, reads in the value of C<$field_name> which it assumes to
be in the format 'YYYYMMDD' and puts it into 'YYYY-MM-DD' format,
which it returns. This is probably the method you will most often
override, depending on how you present dates to your users.

=head1 BUGS

None known.

=head1 TO DO

B<GenericDispatcher items available thru methods>

Modify the GenericDispatcher so that things like security information,
forbidden methods, etc. are available through class methods we can
override. We might hold off on this until we implement the
ActionDispatcher -- no reason to modify something we will
remove/modify soon anyway...

=head1 SEE ALSO

L<OpenInteract::Handler::GenericDispatcher|OpenInteract::Handler::GenericDispatcher>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
