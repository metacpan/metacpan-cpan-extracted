package SPOPS::Tool::DBI::MaintainLinkedList;

# $Id: MaintainLinkedList.pm,v 1.5 2004/06/02 00:48:24 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use Data::Dumper qw( Dumper );
use SPOPS;
use SPOPS::ClassFactory qw( OK DONE ERROR RULESET_METHOD );

use constant HEAD_DEFAULT => 'null';

my $log = get_logger();

$SPOPS::Tool::DBI::MaintainLinkedList::VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

########################################
# CODE GENERATION BEHAVIOR
########################################

sub behavior_factory {
     my ( $class ) = @_;
     return { read_code => \&generate_link_methods };
}

#
# Create previous_in_list(), next_in_list() methods

my $LINK_METHODS = <<'METHODS';

       # Generate the previous/next links

       sub %%CLASS%%::previous_in_list {
          my ( $self, $p ) = @_;
          my $previous_id = $self->{ %%PREVIOUS_ID_FIELD%% };
          return $self->fetch( $previous_id, $p );
       }

       sub %%CLASS%%::next_in_list {
          my ( $self, $p ) = @_;
          my $next_id = $self->{ %%NEXT_ID_FIELD%% };
          return $self->fetch( $next_id, $p );
       }

METHODS

sub generate_link_methods {
    my ( $class ) = @_;
    my $CONFIG = $class->CONFIG;
    my $field_prev = $CONFIG->{linklist_previous};
    my $field_next = $CONFIG->{linklist_next};
    my $methods = $LINK_METHODS;
    $methods =~ s/%%CLASS%%/$class/g;
    $methods =~ s/%%PREVIOUS_ID_FIELD%%/$field_prev/g;
    $methods =~ s/%%NEXT_ID_FIELD%%/$field_next/g;
    {
        local $SIG{__WARN__} = sub { return undef };
        eval $methods;
        if ( $@ ) {
            return ( ERROR, "Cannot generate 'previous_in_list()' and " .
                            "'next_in_list()' methods for object linked " .
                            "list in class [$class]. Error: $@" );
        }
    }
    return ( OK, undef );
}


########################################
# RUNTIME RULES
########################################

sub ruleset_factory {
    my ( $class, $rs_table ) = @_;
    push @{ $rs_table->{post_save_action} },   \&update_links;
    push @{ $rs_table->{post_remove_action} }, \&remove_links;
    $log->is_debug &&
        $log->debug( "Adding rules to [$class] from [", __PACKAGE__, "]" );
    return __PACKAGE__;
}

sub update_links {
    my ( $self, $p ) = @_;
    return 1 unless ( $p->{is_add} );
    return 1 if ( $p->{skip_linklist} );

    my @bad_params = ();
    my $field_prev = $self->CONFIG->{linklist_previous};
    my $field_next = $self->CONFIG->{linklist_next};
    unless ( $field_prev ) {
        push @bad_params, "[linklist_previous: $field_prev]";
    }
    unless ( $field_next ) {
        push @bad_params, "[linklist_next: $field_next]";
    }

    my $head_type = $self->CONFIG->{linklist_head} || HEAD_DEFAULT;
    my ( $order_by, $head_value );
    if ( $head_type eq 'order' ) {
        $order_by = $self->CONFIG->{linklist_head_order};
        unless ( $order_by ) {
            push @bad_params, "[linklist_head_order: $order_by]";
        }
    }
    if ( $head_type eq 'value' ) {
        $head_value = $self->CONFIG->{linklist_head_value};
        unless ( $head_value ) {
            push @bad_params, "[linklist_head_value: $head_value]";
        }
    }


    if ( scalar @bad_params ) {
        $log->warn( "Cannot automatically maintain linked list because field\n",
               "configuration variables are not available:\n",
               join( "\n", @bad_params ) );
        return 1;
    }

    # Add framework parameters (resources, etc) that need to be passed
    # into the save() commands here (this is dirty)

    my %temp_params = ( db => $p->{db} );

    my $this_id = $self->id;
    my ( $previous );
    if ( $head_type eq 'null' ) {
        $previous = _linklist_fetch_previous_null( $self, $field_next, \%temp_params );
    }
    elsif ( $head_type eq 'order' ) {
        $previous = _linklist_fetch_previous_order( $self, $order_by, \%temp_params );
    }
    elsif ( $head_type eq 'value' ) {
        $previous = _linklist_fetch_previous_value( $self, $field_next, $head_value, \%temp_params );
    }
    return 1 unless ( $previous );
    my $previous_id = $previous->id;

    $log->is_debug &&
        $log->debug( "Creating linked list entries for [", ref( $self ), "]",
                    "with ID [$this_id] to previous [$previous_id]" );

    $previous->{ $field_next } = $this_id;
    $self->{ $field_prev }     = $previous_id;
    eval {
        $previous->save( \%temp_params );
        $self->save( \%temp_params );
    };
    if ( $@ ) {
        $log->warn( "Error maintaining linked list: $@" );
        return undef;
    }
    $log->is_debug &&
        $log->debug( "Created links ok" );
    return 1;
}

sub _linklist_fetch_previous_null {
    my ( $self, $head_field, $p ) = @_;
    my $id_field = $self->id_field;
    return ( $self->fetch_group({ %{ $p },
                                  where => "$id_field != ? and $head_field IS NULL",
                                  value => [ $self->id ],
                                  limit => 1 }) )->[0];
}

sub _linklist_fetch_previous_order {
    my ( $self, $order_by, $p ) = @_;
    my $id_field = $self->id_field;
    return ( $self->fetch_group({ %{ $p },
                                  where => "$id_field != ?",
                                  value => [ $self->id ],
                                  order => $order_by,
                                  limit => 1 }) )->[0];
}

sub _linklist_fetch_previous_value {
    my ( $self, $head_field, $head_value, $p ) = @_;
    my $id_field = $self->id_field;
    return ( $self->fetch_group({ %{ $p },
                                  where => "$id_field != ? AND $head_field = ?",
                                  value => [ $self->id, $head_value ],
                                  limit => 1 }) )->[0];
}


sub remove_links {
    my ( $self, $p ) = @_;
    return 1 if ( $p->{skip_linklist} );

    my $field_prev = $self->CONFIG->{linklist_previous};
    my $field_next = $self->CONFIG->{linklist_next};
    unless ( $field_prev and $field_next ) {
        $log->warn( "Cannot automatically maintain linked list because certain\n",
               "configuration variables are not available:\n",
               "[linklist_previous: $field_prev]\n",
               "[linklist_next: $field_next]" );
        return 1;
    }

    my $previous = $self->fetch( $self->{ $field_prev }, $p );
    my $next     = $self->fetch( $self->{ $field_next }, $p );
    if ( $previous and $next ) {
        $previous->{ $field_next } = $next->id;
        $next->{ $field_prev }     = $previous->id;
        $log->is_debug &&
            $log->debug( "Linking [", ref( $self ), "] ",
                        "[previous: ", $previous->id, "] ",
                        "[next: ", $next->id, "]" );
    }
    elsif ( $previous ) {
        $previous->{ $field_next } = undef;
        $log->is_debug &&
            $log->debug( "Linking [", ref( $self ), "] ",
                        "[previous: ", $previous->id, "] ",
                        "[next: n/a]" );
    }
    elsif ( $next ) {
        $next->{ $field_prev }     = undef;
        $log->is_debug &&
            $log->debug( "Linking [", ref( $self ), "] ",
                        "[previous: n/a] ",
                        "[next: ", $next->id, "]" );
    }
    else {
        $log->is_debug &&
            $log->debug( "Linking [", ref( $self ), "] ",
                        "[previous: n/a] ",
                        "[next: n/a]" );
    }
    eval {
        $previous->save( $p ) if ( $previous );
        $next->save( $p )     if ( $next );;
    };
    if ( $@ ) {
        warn "Error maintaining linked list: $@\n";
        return undef;
    }
    return 1;
}

1;

__END__

=head1 NAME

SPOPS::Tool::DBI::MaintainLinkedList - Support objects that automatically maintain a link to the previous and next objects

=head1 SYNOPSIS

 $spops = {
    'my' => {
      class             => 'My::Object',
      isa               => [ qw/ SPOPS::DBI::MySQL  SPOPS::DBI / ],
      field             => [ qw/ object_id name next_object_id previous_object_id / ],
      skip_undef        => [ qw/ next_object_id previous_object_id / ],
      rules_from        => [ 'SPOPS::Tool::DBI::MaintainLinkedList' ],
      linklist_previous => 'next_object_id',
      linklist_next     => 'previous_object_id',
      ...
    },
 };

 # Create some objects; new links are maintained along the way

 My::Object->new({ object_id => 1, name => 'first' })->save();
 My::Object->new({ object_id => 2, name => 'second' })->save();
 My::Object->new({ object_id => 3, name => 'third' })->save();

 my $object2 = My::Object->fetch(2);
 print "This object: ", $object2->name, "\n",
       "Previous object: ", $object2->previous_in_list->name, "\n",
       "Next object: ", $object2->next_in_list->name, "\n";
 # This object: second
 # Previous object: first
 # Next object: third

 # Remove the middle object to shuffle the links
 $object2->remove;

 my $object1 = My::Object->fetch(1);
 print "This object: ", $object1->name, "\n",
       "Previous object: ", ( $object1->previous_in_list )
                              ? "n/a" : $object1->previous_in_list->name ), "\n",
       "Next object: ", $object1->next_in_list->name, "\n";
 # This object: first
 # Previous object: n/a
 # Next object: third

=head1 DESCRIPTION

This package supports an SPOPS ruleset to maintain a linked list of
next/previous IDs. Adding a new object will set its the 'next' link to
the previous head to the new object and the 'previous' link of the new
object to the previous head.

=head2 Configuration

The following configuration entries are defined:

B<linklist_previous> ($)

Name of the field that holds the ID for the previous object.

B<linklist_next> ($)

Name of the field that holds the ID for the next object.

B<linklist_head> ($)

Method to use for finding the head object. Options are defined below
in B<Finding the Head>.

B<linklist_head_order> ($) (optional)

Used if the C<linklist_head> is 'order'. The C<ORDER BY> clause to use
to find the head. This can be any valid SQL clause, so something like
C<posted_on_date DESC> would work fine.

B<linklist_head_value> ($) (optional)

Used if the C<linklist_head> is 'value'. Set to the value of
C<linklist_next> for the head object. This can be useful if your
database uses 0 instead of NULL for numeric fields, or if you want to
set a default for C<linklist_next> to a known value rather than
relying on NULL.

=head2 Finding the Head

The previous head can be found in a few ways, controlled by the
configuration option 'linklist_head':

B<null> (default)

Find the object with the C<linklist_next> field as NULL. If you have
not setup the objects properly so that there is more than one object
with a NULL value you will probably get a surprise: we just take the
first object returned with a NULL value in the field.

B<value>

Find the object with the C<linklist_next> field as
C<linklist_head_value>. Same conditions apply for the B<null> option.

B<order>

Fetch the objects ordered by a certain field and assume the first is
the head. Requires you to set C<linklist_head_order> to the relevant
SQL C<ORDER BY> clause.

=head1 METHODS

B<post_save_action>

When a new object is created, it updates the C<linklist_next> field of
the previous object (found in the manner described above) with the ID
of the object just created and the C<linklist_previous> field of the
saved object with the ID of the previous object.

Performs no action on an update or if the option 'skip_linklist' is
passed to C<save()>:

 my $object = My::Object->new({ id => 1 })->save({ skip_linklist => 1 });

The latter option can be useful if you are creating new objects which
do not belong at the head of the list. (See C<BUGS> for an example of
how to do this.)

B<post_remove_action>

Relink the previous and next objects to point to each other rather
than the object just removed.

=head1 BUGS

B<Non-head inserts>

You need to manually manipulate inserts not at the head of the list
using something like:

 # do not use automatic linking for this save...

 my $object = My::Object->new({ id => 1 })->save({ skip_linklist => 1 });

 my $field_previous = My::Object->CONFIG->{linklist_previous};
 my $field_next     = My::Object->CONFIG->{linklist_next};

 # ...find place to insert your object (find_[previous|next]_object()
 # are defined by you)...

 my $previous = find_previous_object( ... );
 my $next     = find_next_object( ... );

 # ...shuffle the IDs and save...

 $previous->{ $field_next }   = $object->id;
 $object->{ $field_previous } = $previous->id;
 $object->{ $field_next }     = $next->id;
 $next->{ $field_previous }   = $object->id;
 eval {
     $previous->save();
     $object->save();
     $next->save();
 };

=head1 TO DO

None known.

=head1 SEE ALSO

L<SPOPS::Manual::ObjectRules|SPOPS::Manual::ObjectRules>

L<SPOPS::ClassFactory|SPOPS::ClassFactory>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
