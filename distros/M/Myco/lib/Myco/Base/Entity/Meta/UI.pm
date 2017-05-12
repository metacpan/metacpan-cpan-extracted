package Myco::Base::Entity::Meta::UI;

###############################################################################
# $Id: UI.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Meta::UI

=head1 VERSION

=over 4

=item Release

0.01

=cut

our $VERSION = 0.01;

=item Repository

$Revision$ $Date$

=back

=head1 SYNOPSIS

see L<Myco::Base::Entity::Meta|Myco::Base::Entity::Meta>

=head1 DESCRIPTION

Container for metadata describing appropriate user interface behavior for
an entity class.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;

##############################################################################
# Programatic Dependencies
use Myco::Base::Entity::Meta::UI::List;
use Myco::Base::Entity::Meta::UI::View;


##############################################################################
# Constants
##############################################################################
# names of some related classes
use constant META => 'Myco::Base::Entity::Meta';
use constant UI_LIST => 'Myco::Base::Entity::Meta::UI::List';
use constant UI_VIEW => 'Myco::Base::Entity::Meta::UI::View';

##############################################################################
# Inheritance
##############################################################################
use base qw(Class::Tangram);

##############################################################################
# Function and Closure Prototypes
##############################################################################


##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Class::Tangram

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 3

=item *  Set attribute value

 $obj->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *  Get attribute value

 $value = $obj->get_attribute;

=back

A listing of available attributes follows:

=cut

### Object Schema Definition
our $schema =
  {
   fields =>
   {
       transient =>
       { 
	   list => { class => UI_LIST,
		     init_default => sub { UI_LIST->new },
		 },
	   view => { class => UI_VIEW, },
	   meta => { class => META, },
	   attribute_options => { init_default => {},
				  check_func => sub { 1 } },
	   displayname => {},
	   displayname_coderef => {},
	   sort => [],
       },
    }
};
Class::Tangram::import_schema(__PACKAGE__);

=head2 attribute_options

 type: hash ref


=head2 displayname

 type: string or coderef

=head2 sort

 type: array ref

  my $sort = [ 'last_name',
               {first_name => 1},
             ];

List of attributes to use in sorting list of objects of same (or polymorphic)
type. Default order is ascending; optional boolean flag indicates 'descending'
order.

=head2 list

 type: hash ref

Reference to ..::Meta::UI::List object.  C<set_list()> automatically
constructs such an object (a new one).

=cut

sub set_list {
    shift->SUPER::set_list( UI_LIST->new( %{ $_[0] } ) );
}

=head2 view

 type: hash ref

Reference to ..::Meta::UI::View object.  C<set_view()> automatically
constructs such an object (a new one).

=cut

sub set_view {
    shift->SUPER::set_view( UI_VIEW->new( %{ $_[0] } ) );
}


##############################################################################
# Methods
##############################################################################


=head2 sort_objs

  my @sorted_objs = $ui_metadata->sort_objs(@unsorted_objs);

Returns a code ref for use in perl-style sorting, utilizing class metadata.

=cut

sub sort_objs {
    my $self = shift;
    my @objs = @_;
    my $class = $self->get_meta->get_name;
    my $sort_list = $class->introspect->get_ui->get_sort || return @objs;

    # Map tangram scalar types to numeric ('<=>') or string ('cmp') operators.
    my %_sort_opers = (string => 'cmp',
                       int => '<=>',
                       real => '<=>',
                       rawdate => 'cmp',
                       rawtime => 'cmp',
                       rawdatetime => 'cmp',
                       dmdatetime => 'cmp' );

    my $sort;
    my $i = 1;
    for my $each (@$sort_list) {
        my $attr = ref $each eq 'HASH' ? join '', keys %$each : $each;
        my $getter = 'get_'.$attr;
        my $type = $class->introspect->get_attributes->{$attr}->get_type;
        if (ref $each eq 'HASH' && $each->{$attr} ) {
            $sort .= '$b->'.$getter.' '.$_sort_opers{$type}.' $a->'.$getter;
        } else {
            $sort .= '$a->'.$getter.' '.$_sort_opers{$type}.' $b->'.$getter;
        }
        $sort .= $i < @$sort_list ? ' || ' : ';';
        $i++;
    }
    return sort { eval $sort } @objs;
}

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Base::Entity::Meta::UI::Test|Myco::Base::Entity::Meta::UI::Test>,
L<Myco::Base::Entity|Myco::Base::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<mkentity|mkentity>

=cut
