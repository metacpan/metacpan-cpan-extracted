package Myco::Query::Part::Filter;

###############################################################################
# $Id: Filter.pm,v 1.6 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Query::Part::Filter - a Myco entity class

=head1 SYNOPSIS

  use Myco;

  # Constructors. See Myco::Entity for more.
  my $filter = Myco::Query::Part::Filter->new;

  $filter->set_relevance( 1 ); # this filter is relevant to the query,
                               # required, even

  $filter->set_parts(
                      [
                        # starting with just one part...

                        { remote => '$sample_base_entity_',
                          attr => 'chicken',
                          oper => '==',
                          param => '$params{chk}' }
                      ]
                    );

  # Note that 'set_parts' accepts a precompiled (see below) filter or clause
  # object or just an attribute hash that is constructor-friendly.

  # See Myco::Entity::SampleEntity for more on this 'poultry' example

  # We must be able to nest filters inside of other filters, ad infinitum.
  my $parent_filter = Myco::Query::Part::Filter->new
                        ( relevance => 0,
                          parts => [ $filter ], # here we're passing in a
                                                # pre-compiled filter object
                        );

  # See below for examples of instance methods


=head1 DESCRIPTION

This class of object encapsulates L<Tangram::Filter> objects. It stores
metadata about the filter object, facilitates the addition and removal of
metadata, and gathers the metadata together when the time comes for
L<Myco::QueryTemplate> to render these objects into usable Tangram query
filters when a query is run. A key feature of this class is to recursively
include other Myco::Query::Part::Filter objects into each other, via the
L<parts> attribute.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use Myco::Entity::Meta;

##############################################################################
# Programatic Dependencies


##############################################################################
# Constants
##############################################################################
use constant FILTER => 'Myco::Query::Part::Filter';
use constant CLAUSE => 'Myco::Query::Part::Clause';
use constant PART => 'Myco::Query::Part';

##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw( Myco::Query::Part );
my $md = Myco::Entity::Meta->new( name => __PACKAGE__ );

##############################################################################
# Function and Closure Prototypes
##############################################################################


##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Myco::Entity.

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 3

=item *

Set attribute value

 $obj->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *

Get attribute value

 $value = $obj->get_attribute;

=back

A listing of available attributes follows:

=head2 parts

 type: transient

An array reference of the parts of the query filter. These parts consist of clauses and
(potentially) other filter objects.

=cut

$md->add_attribute( name => 'parts', type => 'transient' );

sub set_parts {
    my $self = shift;
    my $parts = shift;

    my @compiled_parts;
    for my $part (@$parts) {
        if ( UNIVERSAL::isa($part, PART) ) {
            # handed a compiled PART obj... use it!
            push @compiled_parts, $part;
        } elsif (ref $part eq 'HASH') {
            # $part is a PART->new happy hashref.
            # Figure out if it itself is a FILTER spec, or just a CLAUSE spec
            my $part_kind = exists $part->{parts} ? FILTER : CLAUSE;
            push @compiled_parts, $part_kind->new( %$part );
        } else {
            Myco::Exception::Query::Filter->throw
                ( error => 'Error setting parts in the Filter object' );
        }
    }

    $self->SUPER::set_parts( [ @compiled_parts ] );
}



=head2 relevance

 type: transient - boolean (1 | 0)

A boolean attribute that determines if a Filter is 'relevant', i.e. whether
its inclusion in a query should be by default even if none of the params
relevant to it were passed at query-run-time. On its own, this attribute is
useless. To dynamically determine if a filter is relevant just prior to
query-run-time, use $filter->is_relevant( %query_run_params ).

=cut

$md->add_attribute( name => 'relevance', type => 'transient' );

sub set_relevance {
    $_[0]->SUPER::set_relevance( $_[1] == 1 ? 1 : 0 );
}


##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=head2 add_part

  $query_filter->add_part( $query_part );

Pushes a Myco::Query::Part object onto the end of the parts array.

=cut

sub add_part {
    my $self = shift;
    my $part = shift;

    Myco::Exception::Query::Filter->throw
        ( error => "$part is not a Myco::Query::Part object" )
          unless UNIVERSAL::isa($part, 'Myco::Query::Part');

    $self->set_parts( [ @{ $self->get_parts }, $part ] );

}


=head2 remove_part

  $query_filter->remove_part( $query_part );

Deletes a Myco::Query::Part object from the parts array. Accpets and object
reference or an object ID.

=cut

sub remove_part {
    my ($self, $part_to_remove) = @_;

    my @parts;
    for my $part ( @{$self->get_parts} ) {
        # Stringify the part object to get the memory address to compare
        push @parts, $part if "$part" ne "$part_to_remove";
    }
    $self->set_parts( [ @parts ] );
}



=head2 get_combined_parts

  my $filter_string = $query_filter->get_combined_parts;

Returns all the filter parts into a string.

=cut

sub get_combined_parts {
    my $self = shift;
    my $query = shift;
    my $run_query_params = shift;
    my $optional_params_not_submitted = shift;

    my $filter_string;
    my @parts = @{ $self->get_parts };
    my $i = 0;
    for my $part (@parts) {
        # Recurse if this $part is itself a filter
        if (ref $part eq FILTER) {
            next if ! $part->is_relevant( $run_query_params );
            my $combined_parts = $part->get_combined_parts
              ($query, $run_query_params, $optional_params_not_submitted);
            if ($combined_parts =~ /(&|&\s+)$/) {
                $combined_parts =~ s/(.*)(\s*)(&)(\s*)$/$1/;
                $filter_string .= ' ('. $combined_parts . ' ) & ';
            }
        } else {
            # Its a Myco::Query::Part::Clause

            # Must parse the param name out of the '$params{}'
            # Leave this for any legacy code still embedding the '$params{}'
            # If its a match oper, access the bare param as index [0].
            my $param = $part->get_oper eq 'match'
              ? $part->get_param->[0] : $part->get_param;
            $param =~ s/\$params\{(.+)\}/$1/;

            # Skip ahead if the optional param wasn't submitted
            next if exists $optional_params_not_submitted->{$param};
            $filter_string .= $part->get_clause( $query ) . ' ';
        }
        $i++;
    }

    return '' if ! $filter_string;
    # Chop trailing operators and spaces
    $filter_string =~ s/(.*)(\s*)(&|\||\|\|)(\s*)$/$1/;
    return $filter_string . ($self->get_part_join_oper || '');
}


=head2 is_relevant

  my $is_relevant = $query_filter->is_relevant( \%query_run_time_params );

Calculates whether this filter is relevant to its containing
query - i.e. its clauses having to do with 'remote' object comparison will be
ignored if their attendant paramters were not passed to run_query.

=cut

sub is_relevant {
    my $self = shift;
    my $params = shift;

    my $is_relevant = $self->get_relevance || 0;

    for my $param (keys %$params) {
        # next if its a remote param
        next if $param =~ /^\$.*/;
        for my $part ( @{$self->get_parts} ) {
            if (ref $part eq FILTER) {
                return 1 if $part->is_relevant( $params );
            } elsif (ref $part eq CLAUSE) {
                # Return right away if we've got even one relevant param.
                return 1 if $param eq $part->get_param;
            }
        }
    }
    # no way, like, totally irrelevant. gag me w/a spoon. or am I like, stupid?
    return $is_relevant;
    # defaults to the relevance bit, so that filters
    # that need to be relevant will be forced to compile into the query.
}


##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Query::Part::Filter::Test|Myco::Query::Part::Filter::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
