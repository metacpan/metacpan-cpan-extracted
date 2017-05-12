package SPOPS::ClassFactory::DBI;

# $Id: DBI.pm,v 3.11 2004/06/02 00:48:22 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;
use SPOPS::ClassFactory qw( OK ERROR DONE );

my $log = get_logger();

$SPOPS::ClassFactory::DBI::VERSION  = sprintf("%d.%02d", q$Revision: 3.11 $ =~ /(\d+)\.(\d+)/);

# NOTE: The behavior is installed in SPOPS::DBI


########################################
# MULTIPLE FIELD KEYS
########################################

my $generic_multifield_id = <<'MFID';

    sub %%GEN_CLASS%%::id {
        my ( $self, $id ) = @_;
        if ( $id ) {
	        ( %%ID_FIELD_OBJECT_LIST%% )  = split /\s*,\s*/, $id;
	    }
        return wantarray ? ( %%ID_FIELD_OBJECT_LIST%% )
                         : join( ',', %%ID_FIELD_OBJECT_LIST%% );
    }
MFID


# Generate an ID method for classes that have multiple-field primary
# keys

sub conf_multi_field_key_id {
    my ( $class ) = @_;
    my $CONFIG = $class->CONFIG;
    my $id_field = $CONFIG->{id_field};

    return ( OK, undef ) unless ( ref $id_field eq 'ARRAY' );
    if ( scalar @{ $id_field } == 1 ) {
        $CONFIG->{id_field} = $id_field->[0];
        return ( OK, undef );
    }

    my $id_object_reference = join( ', ',
                                    map { '$self->{' . $_ . '}' }
                                        @{ $id_field } );
    my $id_sub = $generic_multifield_id;
    $id_sub =~ s/%%GEN_CLASS%%/$class/g;
    $id_sub =~ s/%%ID_FIELD_OBJECT_LIST%%/$id_object_reference/g;
    $log->is_debug &&
        $log->debug( "Evaluation method 'id' for class [$class]\n$id_sub" );
    {
        local $SIG{__WARN__} = sub { return undef };
        eval $id_sub;
        if ( $@ ) {
            warn "Code: $id_sub\n";
            return ( ERROR, "Cannot create multifield 'id()' method for " .
                            "class [$class]: $@" );
        }
    }
    return ( DONE, undef );
}


# TODO: The explicit 'SPOPS::DBI' method below works, but it ignores
# anything in ISA between $class and it that might define-and-forward
# (or override) fetch().

my $generic_multifield_etc = <<'MFETC';

    sub %%GEN_CLASS%%::fetch {
        my ( $class, $id, @params ) = @_;
        my $id_string = ( ref $id eq 'ARRAY' )
                          ? join( ',', @{ $id } ) : $id;
        return $class->SPOPS::DBI::fetch( $id_string, @params );
    }

    sub %%GEN_CLASS%%::clone {
        my ( $self, $p ) = @_;
        my $class = $p->{_class} || ref $self;
        $log->is_info &&
            $log->info( "Cloning new object of class ($class) from old ",
                          "object of class (", ref $self, ")" );
        my %initial_data = ();

        my %id_field = map { $_ => 1 } $class->id_field;

        while ( my ( $k, $v ) = each %{ $self } ) {
            next unless ( $k );
            next if ( $id_field{ $k } );
            $initial_data{ $k } = $p->{ $k } || $v;
        }

        my $cloned = $class->new({ %initial_data, skip_default_values => 1 });
        if ( $p->{id} ) {
            $cloned->id( $p->{id} );
        }
        else {
            foreach my $field ( keys %id_field ) {
                $cloned->{ $field } = $p->{ $field } if ( $p->{ $field } );
            }
        }
        return $cloned;
    }

    sub %%GEN_CLASS%%::id_field {
        return wantarray ? %%ID_FIELD_NAME_LIST%%
                         : join( ',', %%ID_FIELD_NAME_LIST%% );
    }

    sub %%GEN_CLASS%%::id_clause {
        my ( $self, $id, $opt, $p ) = @_;
        $opt ||= '';
        $p   ||= {};
        my %val = ();
        my $db = $p->{db} || $self->global_datasource_handle( $p->{connect_key} );
        unless ( $db ) {
            SPOPS::Exception->throw( "Cannot create ID clause: no DB handle available" );
        }

        # let any errors bubble up
        my $type_info = $self->db_discover_types(
                                        $self->table_name,
                                        { dbi_type_info => $p->{dbi_type_info},
                                          db            => $db,
                                          DEBUG         => $p->{DEBUG} } );
        if ( $id and ref $id eq 'ARRAY' ) {
            ( %%ID_FIELD_VARIABLE_LIST%% ) = @{ $id };
        }
        elsif ( $id ) {
      	    ( %%ID_FIELD_VARIABLE_LIST%% ) = split /\s*,\s*/, $id;
        }
        else {
    	    ( %%ID_FIELD_VARIABLE_LIST%% ) = ( %%ID_FIELD_OBJECT_LIST%% );
        }
        unless ( %%ID_FIELD_BOOLEAN_LIST%% ) {
	        SPOPS::Exception->throw( "Insufficient values for ID (%%ID_FIELD_VARIABLE_LIST%%)" );
        }
    	my @clause     = ();
    	my $table_name = $self->table_name;
    	foreach my $id_field ( %%ID_FIELD_NAME_LIST%% ) {
            my $use_id_field = ( $opt eq 'noqualify' )
                                 ? $id_field
                                 : join( '.', $table_name, $id_field );
            my $quoted_value = $self->sql_quote( $val{ $id_field },
                                                 $type_info->get_type( $id_field ),
                                                 $db );
    	    push @clause, join( ' = ', $use_id_field, $quoted_value );
	    }
        return join( ' AND ', @clause );
    }

    # should return something like:
    # ( 'mytable.id1', 'mytable.id2' )
    sub %%GEN_CLASS%%::id_field_select {
        my ( $class, $p ) = @_;
        return ( $p->{noqualify} )
                 ? %%ID_FIELD_NAME_LIST%%
                 : map { join( '.', $class->table_name, $_ ) } %%ID_FIELD_NAME_LIST%%;
    }

MFETC


sub conf_multi_field_key_other {
    my ( $class ) = @_;
    my $CONFIG = $class->CONFIG;
    my $id_field = $CONFIG->{id_field};

    return ( OK, undef ) unless ( ref $id_field eq 'ARRAY' );
    if ( scalar @{ $id_field } == 1 ) {
        $CONFIG->{id_field} = $id_field->[0];
        return ( OK, undef );
    }

    my $id_object_reference    = join( ', ',
				       map { '$self->{' . $_ . '}' }
				           @{ $id_field } );
    my $id_variable_reference  = join( ', ', map { "\$val{$_}" } @{ $id_field } );
    my $id_boolean_reference   = join( ' and ', map { "\$val{$_}" } @{ $id_field } );
    my $id_field_reference     = 'qw( ' . join( ' ', @{ $id_field } ) . ' )';
    my $other_sub = $generic_multifield_etc;
    $other_sub =~ s/%%GEN_CLASS%%/$class/g;
    $other_sub =~ s/%%ID_FIELD_OBJECT_LIST%%/$id_object_reference/g;
    $other_sub =~ s/%%ID_FIELD_VARIABLE_LIST%%/$id_variable_reference/g;
    $other_sub =~ s/%%ID_FIELD_BOOLEAN_LIST%%/$id_boolean_reference/g;
    $other_sub =~ s/%%ID_FIELD_NAME_LIST%%/$id_field_reference/g;
    $log->is_debug &&
        $log->debug( "Evaluating other multifield key methods:\n$other_sub" );
    {
        local $SIG{__WARN__} = sub { return undef };
        eval $other_sub;
        if ( $@ ) {
            return ( ERROR, "Cannot create multifield key 'clone()', " .
                            "'id_field(), 'id_clause()', and " .
                            "'id_field_select()' methods for [$class]. " .
                            "Error: $@" );
        }
    }
    return ( OK, undef );
}


########################################
# links_to
########################################

# EVAL'D SUBROUTINES
#
# This is the routine we'll be putting in the namespace of all the
# classes that have asked to be linked to other classes; obviously,
# the items marked like this: %%KEY%% will be replaced before the eval
# is done.

my $generic_linksto = <<'LINKSTO';

    sub %%GEN_CLASS%%::%%LINKSTO_ALIAS%% {
        my ( $self, $p ) = @_;
        my $log = Log::Log4perl::get_logger();
        $p ||= {};
        $p->{select} = [ '%%LINKSTO_ID_FIELD%%' ];
        $p->{from}   = [ '%%LINKSTO_TABLE%%' ];
        my $id_clause = $self->id_clause( $self->id, 'noqualify', $p );
        $p->{where}  = ( $p->{where} )
                         ? join ( ' AND ', $p->{where}, $id_clause ) : $id_clause;
        $p->{return} = 'list';
        $p->{db}   ||= %%LINKSTO_CLASS%%->global_datasource_handle;
        my $rows = %%LINKSTO_CLASS%%->db_select( $p );
        my @obj = ();
        foreach my $info ( @{ $rows } ) {
            my $item = eval { %%LINKSTO_CLASS%%->fetch( $info->[0], $p ) };
            if ( $@ ) {
                $log->error( " Cannot fetch linked object %%LINKSTO_CLASS%% [$info->[0]] ",
                             "from %%GEN_CLASS%%: $@\nContinuing with others..." );
                next;
            }
            push @obj, $item if ( $item );
        }
        return \@obj;
    }

    sub %%GEN_CLASS%%::%%LINKSTO_ALIAS%%_add {
        my ( $self, $link_id_list, $p ) = @_;
        return 0 unless ( defined $link_id_list );
        my $log = Log::Log4perl::get_logger();

        $p ||= {};

        # Allow user to pass only one ID to add (scalar) or an
        # arrayref (ref)

        $link_id_list = ( ref $link_id_list eq 'ARRAY' )
                          ? $link_id_list : [ $link_id_list ];
        my $added = 0;
        $p->{db} ||= %%LINKSTO_CLASS%%->global_datasource_handle;
        foreach my $link_item ( @{ $link_id_list } ) {
            my $link_id = ( ref $link_item ) ? $link_item->id : $link_item;
            $log->is_info &&
                $log->info( "Trying to add link to ID [$link_id]" );
            %%LINKSTO_CLASS%%->db_insert({ table => '%%LINKSTO_TABLE%%',
                                           field => [ '%%ID_FIELD%%', '%%LINKSTO_ID_FIELD%%' ],
                                           value => [ $self->{%%ID_FIELD%%}, $link_id ],
                                           db    => $p->{db},
                                           DEBUG => $p->{DEBUG} });
            $added++;
        }
        return $added;
    }

    sub %%GEN_CLASS%%::%%LINKSTO_ALIAS%%_remove {
        my ( $self, $link_id_list, $p ) = @_;
        $p ||= {};
        my $log = Log::Log4perl::get_logger();

        # Allow user to pass only one ID to remove (scalar) or an
        # arrayref (ref)

        $link_id_list = ( ref $link_id_list eq 'ARRAY' )
                          ? $link_id_list : [ $link_id_list ];
        my $removed = 0;
        $p->{db} ||= %%LINKSTO_CLASS%%->global_datasource_handle;
        foreach my $link_item ( @{ $link_id_list } ) {
            my $link_id = ( ref $link_item ) ? $link_item->id : $link_item;
            $log->is_info &&
                $log->info( "Trying to remove link to ID ($link_id)" );
            my $from_id_clause = $self->id_clause( undef, 'noqualify', $p  );
            my $to_id_clause   = %%LINKSTO_CLASS%%->id_clause( $link_id, 'noqualify', $p );
            %%LINKSTO_CLASS%%->db_delete({ table => '%%LINKSTO_TABLE%%',
                                           where => join( ' AND ', $from_id_clause, $to_id_clause ),
                                           db    => $p->{db},
                                           DEBUG => $p->{DEBUG} });
            $removed++;
        }
        return $removed;
    }

LINKSTO


#
# ACTUAL SUBROUTINE
#

sub conf_relate_links_to {
    my ( $class ) = @_;
    my $config = $class->CONFIG;
    $log->is_info &&
        $log->info( "Adding DBI relationships for: ($class)" );

    # Grab the information for the class we're modifying

    my $this_id_field = $config->{id_field};
    my $this_alias    = $config->{main_alias};

    # Process the 'links_to' aliases -- pretty straightforward (see pod)

    if ( my $links_to = $config->{links_to} ) {
        while ( my ( $to_class, $link_info ) = each %{ $links_to } ) {

            # Since the class specified can be a subclass of what's
            # generated, ensure that it's available

            eval "require $to_class";
            my $require_error = $@;
            my $to_config = eval { $to_class->CONFIG };
            if ( $@ ) {
                return ( ERROR, "Failed to retrieve configuration from " .
                                "'$to_class': $@. (Require error: $require_error)" );
            }

            my ( $to_alias, $to_id_field, $link_table, $from_id_field );

            # If the linking information is a hashref then give the
            # user the opportunity to define everything

            if ( ref( $link_info ) eq 'HASH' ) {
                $link_table    = $link_info->{table};
                $to_alias      = $link_info->{alias}
                                 || $to_config->{main_alias};
                $to_id_field   = $link_info->{to_id_field}
                                 || $to_config->{id_field};
                $from_id_field = $link_info->{from_id_field}
                                 || $this_id_field;
            }

            # Otherwise, if the value is a simple scalar then it names
            # the table

            else {
                $link_table     = $link_info;
                $to_alias       = $to_config->{main_alias};
                $to_id_field    = $to_config->{id_field};
                $from_id_field  = $this_id_field;
            }

            my $link_subs = $generic_linksto;
            $link_subs =~ s/%%ID_FIELD%%/$this_id_field/g;
            $link_subs =~ s/%%GEN_CLASS%%/$class/g;
            $link_subs =~ s/%%LINKSTO_CLASS%%/$to_class/g;
            $link_subs =~ s/%%LINKSTO_ALIAS%%/$to_alias/g;
            $link_subs =~ s/%%LINKSTO_ID_FIELD%%/$to_id_field/g;
            $link_subs =~ s/%%LINKSTO_TABLE%%/$link_table/g;
            $log->is_debug &&
                $log->debug( "Trying to create links_to routines from ",
                              "[$class: $from_id_field] to ",
                              "[$to_class: $to_id_field] using ",
                              "table [$link_table]" );
            $log->is_debug &&
                $log->debug( "Now going to eval the routine:\n$link_subs" );
            {
                local $SIG{__WARN__} = sub { return undef };
                eval $link_subs;
                if ( $@ ) {
                    return ( ERROR, "Cannot create 'links_to' methods for " .
                                    "class [$class] linking to class " .
                                    "[$to_class] via table [$link_table]. " .
                                    "Error: $@" );
                }
            }
        }
    }
    $log->is_info &&
        $log->info( "Finished adding DBI relationships for ($class)" );
    return ( OK, undef );
}

1;

__END__

=pod

=head1 NAME

SPOPS::ClassFactory::DBI - Define additional configuration methods

=head1 SYNOPSIS

 # Put SPOPS::DBI in your isa
 my $config = {
       class => 'My::SPOPS',
       isa   => [ 'SPOPS::DBI::Pg', 'SPOPS::DBI' ],
 };

=head1 DESCRIPTION

This class implements a behavior for the 'links_to' slot as described
in L<SPOPS::ClassFactory|SPOPS::ClassFactory>.

It is possible -- and perhaps desirable for the sake of clarity -- to
create a method within I<SPOPS::DBI> that does all the work that this
behavior does, then we would only need to create a subroutine that
calls that subroutine.

However, creating routines with the values embedded directly in them
should be quicker and more efficient. So we will try it this way.

=head1 METHODS

Note: Even though the first parameter for all behaviors is C<$class>,
they are not class methods. The parameter refers to the class into
which the behaviors will be installed.

B<conf_relate_links_to( $class )>

Slot: links_to

Get the config for C<$class> and find the 'links_to' configuration
information. If defined, we auto-generate subroutines to implement the
linking functionality.

Please see
L<SPOPS::Manual::Relationships|SPOPS::Manual::Relationships> for how
to configure this and examples of usage.

=head1 TO DO

B<Make 'links_to' more flexible>

We need to account for different types of linking; this may require an
additional field beyond 'links_to' that has a similar effect but works
differently.

For instance, Table-B might have a 'has_a' relationship with Table-A,
but Table-A might have a 'links_to' relationship with Table-B. (Themes
in OpenInteract work like this.) We need to be able to specify that
when Table-A severs its relationship with one or more objects from
Table-B, the actual B<object> is removed rather than just a link
between them.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters  E<lt>chris@cwinters.comE<gt>

See the L<SPOPS|SPOPS> module for the full author list.

=cut
