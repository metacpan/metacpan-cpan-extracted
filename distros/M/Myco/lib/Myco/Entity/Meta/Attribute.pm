package Myco::Entity::Meta::Attribute;

###############################################################################
# $Id: Attribute.pm,v 1.7 2006/03/19 19:34:07 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Meta::Attribute

=head1 SYNOPSIS

 # Note this class is normally used only via
 #   Myco::Entity::Meta

 ## Within an entity class definition - add attribute to class
 #   ::Attribute's constructor should only be used via
 #     ::Meta's add_attribute() as shown:

 my $md = Myco::Entity::Meta( name => __PACKAGE__ );
 $md->add_attribute(
    name => 'doneness',
    type => 'int',
    readonly => 0,                     # default is read/write
    access_list => { rw => ['admin'],
		     ro => [qw(average_joes junior_admins)] },
    tangram_options => { required => 1},
    synopsis => "How you'd like your meat cooked",
    syntax_msg => "correct format, please!",
    values => [qw(0 1 2 3 4 5)],
    value_labels => {0 => 'rare',
		     1 => 'medium-rare',
		     2 => 'medium',
		     3 => 'medium-well',
		     4 => 'well',
		     5 => 'charred'},
    ui => { widget => [ 'popup_menu' ],
	    label  => 'Cook until...',
	  },
  );

 ## Typical post-setup usage
 #   ...given a Myco::Entity::Meta enabled entity object $obj

 my $metadata = $obj->introspect;
 # Get reference to array of ::Meta::Attribute objects for $obj's class
 my $attributes = $metadata->get_attributes;
 # Look up attribute's type
 my $type = $attributes->{doneness}->get_type;
 # Use of stored accessor coderef - set doneness = 3
 $attributes->{doneness}->setval($obj, 3);

=head1 DESCRIPTION

Container for meta data describing an attribute of a Myco Entity class

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use Myco::Entity::Meta::Util;
use Myco::Entity::Meta::Attribute::UI;

##############################################################################
# Programatic Dependencies


##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;
use constant DEF_STR_FIELDSIZE => 60;
use constant DEF_FIELDSIZE => 20;

use constant ATTR_UI => 'Myco::Entity::Meta::Attribute::UI';
use constant META_UTIL => 'Myco::Entity::Meta::Util';

# A regex that matches any of the not-plain scalar Class::Tangram data types
my $_fancy_types_re =
  q{^(?:ref|i?array|i?set|dmdatetime|hash|perl_dump)$};

# Valid Class::Tangram entity attribute data types
my $data_types = \%Class::Tangram::defaults;

# Type-specific defaults:
my $_default_meta = {
                     sort_type => 'case_insensitive_string',
                     ui => { widget => ['textfield'] }
                    };
my $_type_defs =
    {
     int          => {
                      sort_type => 'number',
                     },
     date         => {
                      sort_type => 'date',
                      ui => { widget => ['textfield', -size => '12',
                                         -maxlength => '10', ],
                              suffix => q~[<a href="javascript:openCal('$formname','$params{-name}',document.$formname.$params{-name}.value)">E</a>]~,
                            },
                      tangram_options => { sql => 'DATE' },
                     },
     rawdate      => {
                      sort_type => 'date',
                      ui => { widget => ['textfield', -size => '12',
                                         -maxlength => '10', ],
                              suffix => q~[<a href="javascript:openCal('$formname','$params{-name}',document.$formname.$params{-name}.value)">E</a>]~,
                            },
                      tangram_options => { sql => 'DATE' },
                     },
     rawdatetime => {
                     sort_type => 'date',
                     tangram_options => { sql => 'DATE' },
                    },
     yesno       => { type => 'int',
                      values => [0, 1],
                      value_labels => {0 => 'yes',
                                       1 => 'no'},
                      sort_type => 'number',
                      ui => { widget => ['radio_group'] },
                    },
     truefalse   => { type => 'int',
                      values => [0, 1],
                      value_labels => {0 => 'False',
                                       1 => 'True' },
                      sort_type => 'number',
                    },

     ref         => { ui => undef },
     array       => { ui => undef },
     iarray      => { ui => undef },
     set         => { ui => undef },
     iset        => { ui => undef },
     hash        => { ui => undef },
     dmdatetime  => { ui => undef },
     perl_dump   => { ui => undef },
    };


##############################################################################
# Inheritance
##############################################################################
# We cannot inherit from Myco::Entity because it'll screw up access
# checking. This isn't really an entity class, anyway.
use base qw(Class::Tangram);

##############################################################################
# Function and Closure Prototypes
##############################################################################

# Check functions
my $chk_type = sub {
    Myco::Exception::DataValidation->throw
      (error => "illegal attribute type '${$_[0]}' specified")
        unless defined ${$_[0]}
        and exists $data_types->{$ {$_[0]}}
};

my $chk_ui = sub {
    my $type = ref ${$_[0]};
    Myco::Exception::DataValidation->throw
      (error => "must be hashref or ...::Meta::Attribute::UI object")
      unless $type eq 'HASH'
      or $type eq ATTR_UI
};

##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods --  as inherited from
Myco::Entity

=cut

### TODO:  add to new
  # This new() is also where auto-generation of check functions will happen
  # (if $md->{values} is defined but not $md->{tangram_options}{check_func}.)

sub new {
    my $referent = shift;
    my %params = @_;

    my $class = ref $referent || $referent;

    my $specd_widget = defined $params{ui}
      && defined $params{ui}{widget}
      && $params{ui}{widget}[0]
      || '';

    # my ($type, $type_defs, $typedef, $using_default_meta);
    my ($typedef, $using_default_meta);

    # Load defaults for this type
    if ( my $req_type = $params{type} ) {

        $typedef = __PACKAGE__->get_type_defaults->{$req_type};
        unless ( $typedef ) {
            $typedef = __PACKAGE__->get_type_defaults('default');
            $using_default_meta = 1;
        }

        delete $params{type}
          if exists $typedef->{type} && exists $params{type};

        META_UTIL->clone(\%params, $typedef, dont_bless => 1);
    }

    # Sort Types:
    $params{sort_types_hash} =
      { string => 'String',
        case_insensitive_string => 'CaseInsensitiveString',
        number => 'Number',
        date => 'Date',
        none => 'None' };

    my $obj = $class->SUPER::new( %params );

    # now clobber 'ui' default w/params
    if (exists $params{ui}) {
        for my $ui_attr ( keys %{$params{ui}} ) {
            my $setter = 'set_'.$ui_attr;
            $obj->get_ui->$setter( $params{ui}{$ui_attr} );
        }
    }

    ### Generate UI closure for this attribute
    my $values = $obj->get_values;
    my $ui = $obj->get_ui;
    if (defined $values and @$values
        and $using_default_meta and ! $specd_widget) {
        $ui->set_widget( ['popup_menu'] );
    }

#    # Do metadata inheritence
#    Myco::Entity::Meta->_clone_metadata(\%params, $typedef)

    return $obj;
}

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################
our $schema =
  { fields =>
      { transient =>
	    { name => { required => 1 },
	      access_list => {},
	      synopsis => {},
	      syntax_msg => {},
	      tangram_options => {},
	      type => { required => 1, check_func => $chk_type },
	      type_options => {},
	      values => {},
	      value_labels => {},
              sort_type => {},
              sort_types_hash => {},
	      ui => { check_func => $chk_ui },
              # tells whether MVC::Controller will include in web UIs
              ui_display => 1,
	      # Private (set only during call to ::Meta's activate_class()
	      #           method)
	      setter => {},
	      getter => {},
	    },
        int => { readonly => { init_default => 0 },
                 template => { },
               },
      },
  };
Class::Tangram::import_schema(__PACKAGE__);

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods.  Typical usage:

=over 3

=item *  Set attribute value

 $obj->set_attributeName($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data validation.
If there is any concern that the set method might be called with invalid data
then the call should be wrapped in an C<eval> block to catch exceptions
that would result.

=item *  Get attribute value

 $value = $obj->get_attributeName;

=back

A listing of available attributes follows:

=head2 access_list

 type: hash ref

Hash containing either or both of these keys:  rw, ro (for read-write,
read-only, respectively).  Each key corresponds to a anonymous array of
names of user roles authorized for the given type of access.

=cut

sub get_access_list {
    my $ac = $_[0]->SUPER::get_access_list;
    $_[0]->set_access_list($ac = {}) unless $ac;
    return $ac;
}

=head2 getter

 type: code ref

Reference to getter method of entity attribute.

=head2 name

 type: string   required: not empty

Name of entity attribute.

=head2 readonly

 type: int (boolean)

If set to true calls to entity attribute setter will result in throwing of
exception type Myco::Exception::MNI.

=head2 setter

 type: code ref

Reference to setter method of entity attribute.

=head2 synopsis

 type: string

Short (a few words) description of entity attribute.

=head2 tangram_options

 type: hash ref

Hash of L<Class::Tangram|Class::Tangram> entity attribute options.

=head2 template

 type: int (boolean)

If set to true entity attribute is marked as a "template", meaning the
following:

=over 4

=item *

the entity class does I<not> have use of this entity attribute (although
its metadata definition is available)

=item *

a sub-class of this entity class I<will> have this entity attribute added to
its schema; it is added directly to the sub-class, B<not inherited>.

=back

=head2 type

 type: string

Data type of entity attribute; must be a valid L<Class::Tangram|Class::Tangram>
data type.  [required: not undef]

=cut

########
### TODO:  Add coverage of types here.... including Myco custom types.
########

=head2 type_options

 type: hash ref

Additional detail regarding the entity attribute data type.  Valid option(s):

=over 4

=item * string_length: int

Maximum character length of string type entity attributes.  During schema
generation this results in the automatic addition of

  sql => 'VARCHAR(#)'

to the 'tangram_options' parameter, unless that parameter already has the
'sql' option set.  Also, if this entity attribute employs a textfield or
password_field as a user interface (either specified via the 'ui' metadata
attribute or as the default [for scalars]) then the closure generated
will include C<-maxlength =E<gt> #> in the CGI.pm method parameter list (see
below:  attribute 'ui').

=back

=head2 syntax_msg

 type: string

Short (under one line) description of valid entity attribute value syntax.

=head2 values

 type: array ref

Array of all valid values for this entity attribute.  Use only when
appropriate.  By default, setting this metadata parameter results in a
"popup_menu" being used as the user interface widget type, with values
displayed in the order given.

=over 4

=item

I<Special Array Values>

The special string values below may be included as members of the array
to customize this entity attributeE<39>s user interface behavior.
These values do NOT get stored in the entity object attribute.

=over 4

=item *

__select__

Including in the array the string "__select__" will make "<Select>" appear
as a popup menu choice.

=item *

__other__

If the array contains the string "__other__" then during widget generation
the popup menu will include the choice "<Other>", and
a text box will appear below labeled "Other:" that allows entry of an
alternate value which will be used as the input value for this entity
attribute if '<Other>' is selected.

=item *

__blank__

If the array contains the string "__blank__" then the popup menu will contain
a blank selection at the given position.

=back

=back

=head2 value_labels

 type: hash ref

Hash mapping entity attribute values (which should be the same as those
specified with the "values" parameter) to a user visible label;  for use when
generating value selection user interface widget for this entity attribute.

=head2 ui

 type: hash ref

 {
  label  => 'Sprocket',
  widget => ['popup_menu', -rows => 2, -columns => 2],
  # etc.
 }

A data structure containing instructions for generating a user interface
element for this entity attribute.  This data structure used in the creation
of a L<Myco::Entity::Meta::Attribute::UI|Myco::Entity::Meta::Attribute::UI>
object which becomes part of the attribute metadata.  Run-time access
to this metadata should only occur via accessor methods.

The following hash keys (corresponding to ::Meta::Attribute::UI object
attributes) are allowed:

=over

=item

I<closure>

 type: code ref

A reference to an anonymous subroutine capable of generating a user interface
element for this entity object attribute.  The subroutine is a closure and
can be thought of as the compiled representation of all other user interface
related metadata (values, value_labels, ui->widget, ui->label) for this entity
attribute.

See documentation of method C<create_closure()> from class
L<Myco::Entity::Meta::Attribute::UI|Myco::Entity::Meta::Attribute::UI>.

This attribute is set automatically by a call to C<set_widget()>.

I<label>

 type: string

Label text to appear in user iterface on or near this entity attributeE<39>s
inteface widget.

I<options>

 type: hash ref

 { hidden => 1 }

Options that affect the user interface behavior of this entity attribute.
Available options:

=over 4

=item *

hidden

 type: boolean

If set to true indicates that a widget for this attribute should not by
default be visable.  However, when generating an HTML-based form
for the pupose of creating/updating entity objects that contain this
attribute, the attribute B<should> be included as a hidden form field.

=item *

value_default

 type: string

If the attribute metadata contains the C<values> parameter
then during widget generation the value supplied with this option is
selected by default.

=item *

value_select

 type: boolean

This option is automatically set to true if the attribute metadata contains
the C<values> parameter and the list of values includes the string
'__select__'.

=back

I<suffix>

 type: string

Additional HTML that will be appended to the generated widget HTML.

I<widget>

 type: array ref

 ['popup_menu', -rows => 2, -columns => 2]

The first array element is the name of the L<CGI.pm|CGI> form element method to
be used to generate the widget.  Named parameters for this CGI.pm method
may optionally follow.  Named parameters -name, -values, and -value_labels
should _not_ be specified here (these will automatically be set as
appropriate, from, for example, other metadata attributes).

Setting this attribute will trigger the automatic setting of the 'closure'
attribute.


=over 4

=item

I<Default UI Widget>

If this piece of metadata is not supplied in class definition then during
metadata initialization for this entity asttribute,
an appropriate user interface widget may be automatically
chosen, depending on the type of the entity attribute (as indicated in the
'type' metadata attribute).  The default UI elements (L<CGI.pm|CGI> form
element method names) are listed below by major entity type categories:

=over 4

=item * scalars:  textfield

(string, int, real, rawdate, etc.)  If, however, the 'values' metadata
attribute is set then 'popup_menu' will be used instead.

=item * flat_array:  none

=item * other:  none

 (ref, (i)array, (i)set, hash, dmdatetime, perl_dump)

=back

=back

=back

=cut

sub set_ui {
    my ($self, $ui) = @_;

    if (ref $ui eq ATTR_UI) {
	# handed a ATTR_UI obj... use it!
	$self->SUPER::set_ui($ui);
	# set the 'attr' attrib if empty
	$ui->set_attr($self) unless $ui->get_attr;

    } else {
	# val must be a ATTR_UI->new happy hashref
	$self->SUPER::set_ui($ui = ATTR_UI->new
		   ( attr => $self,
                     %$ui,
		   ));
    }
#    unless ($ui->{get_closure}) {
#	# Our ui object gets some widget generation smarts:
#	$ui->create_closure;
#    }
}

sub get_ui {
    my $self = shift;
    my $ui = $self->SUPER::get_ui;
    return $ui if ref $ui;
    # Create ..::UI object since none exists
    $self->set_ui( );
    return $self->SUPER::get_ui;
}


##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=head2 get_type_defaults

Returns a reference to a hash (key == attribute type) of default meta data info
which is used during attribute object initialization.

=cut

my $defs_initted;
sub get_type_defaults {
    #_init_defs() unless $defs_initted;

    defined($_[1]) && $_[1] eq 'default' ? $_default_meta : $_type_defs;
}

sub _init_defs {
    # Spread some good ol' blessing around

    bless $_default_meta->{ui}, ATTR_UI;

    for my $typekey (keys %$_type_defs) {
        my $type = $_type_defs->{$typekey};
        if (ref $type eq 'HASH' and ref $type->{ui} eq 'HASH') {
            bless $type->{ui}, ATTR_UI;
        }
    }
    $defs_initted = 1;
}

=head2 getval

 # Given $attrmeta, an ::Attribute metadata object for some class,
 #   and $entity, an instance of same class
 $attrval = $attrmeta->getval($entity);

 # Complete, but unrealistic example of use
 $attrval = $entity->introspect->get_attributes->{attr1}
                                            ->getval($entity);

Get the value of an attribute of $entity, utilizing the getter code
reference retrieved C<via get_getter>.

=cut

# See ::Meta::Test for tests... since most related complexity lives
#       in ::Meta
sub getval {
    $_[0]->get_getter->($_[1]);
}


=head2 setval

 # Given $attrmeta, an ::Attribute metadata object for some class,
 #   and $entity, an instance of same class
 $attrval = $attrmeta->setval($entity, $value);

 # Complete, but unrealistic example of use
 $attrval = $entity->introspect->get_attributes->{attr1}
                                         ->setval($entity, $value);

Set value of an attribute of $entity, utilizing the setter code
reference retrieved C<via get_setter>.

=cut

# See ::Meta::Test for tests... since most related complexity lives
#       in ::Meta
sub setval {
    $_[0]->get_setter->($_[1], $_[2]);
}


1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::Meta|Myco::Entity::Meta>,
L<Myco::Entity|Myco::Entity>,
L<CGI|CGI>,
L<Myco::Entity::Meta::Attribute::Test|Myco::Entity::Meta::Attribute::Test>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
