package Myco::Base::Entity::Meta;

###############################################################################
# $Id: Meta.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Meta

meta data container for Myco entity classes

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

 #### Entity class definition

 package Foo;
 use base qw(Myco::Base::Entity);

 # Constructor
 my $metadata = Myco::Base::Entity::Meta->new
  ( name => __PACKAGE__,
    access_list => {
                    rw => ['admin'],
                    ro => [qw(junior_admin plebian)]
                   },
    ui => {
           list => {
                    layout => [qw(__UI_IDENT__ attr2 attr3)]
                   },
           view => {
                    layout => [qw(attr2 attr3 attr1)]
                   }
          }
  );

 # Added attribute metadata
 $metadata->add_attribute(name => 'attr1', type => 'string');
 $metadata->add_attribute(name => 'attr2', type => 'string');

 ...  # declare more attributes, methods, etc.

 # Set access control list
 $metadata->set_access_list({rw => ['admin'],
                             ro => [qw(junior_admin plebian)]
                            });

 # Fill in $schema with all added attributes and discover other
 # metadata.  Should be placed at end of class file
 $metadata->activate_class;
 1;


 #### Entity class use

 use Foo;
 $instance = Foo->new();

 #  "introspect()" method is added to entity class
 #  automatically during the call to activate_class()

 # Access class metadata
 $metadata = Foo->introspect;
 $metadata = $instance->introspect;

 # Generate a text identifier for this object, suitable for use
 #   in UI list of like objects, etc.
 $id_string = $instance->introspect('__UI_IDENT__');


=head1 DESCRIPTION

...::Meta, as a companion to Myco::Base::Entity (and more
intimately Class::Tangram) allows a class to maintain and provide
access to metadata about itself.  This metadata includes details
regarding: attributes, methods, persistence, and user interface defaults.
Metadata elements, when possible, will carry documentation pulled from
respective sections of the classE<39>s POD documentation [future] (this
functionality will work only when POD is formatted as shown in
Myco::templates::entity.)

When used as intended, ...::Meta takes care of much of the process of
entity class declaration.  Object schema is declared via one or more calls of
C<$metadata-E<gt>add_attribute()>, with which a rich set of metadata about
a given attribute may be specified.  Placed at the end of the class file
is the call C<$metadata-E<gt>activate_class>, which triggers the discovery
of additional class details and the generation of a Class::Tangram-style
C<$schema> data structure (along with a call to
C<Class::Tangram::import_schema()>).

=head2 Upgrading existing classes

For exisiting classes with Class::Tangram-style C<$schema> data structures
much of the functionality provide by ...::Meta may be added with just
these modifications:

=over 4

=item 1. Add, after the C<use base ...;> statement:

 my $metadata = Myco::Base::Entity::Meta->new(name => __PACKAGE__);

=item 2. Remove this existing statement:

 Myco::Base::Entity::import_schema(__PACKAGE__);

=item 3. Add, at end of class file:

 $metadata->activate_class;

=back

When C<activate_class()> is called the existing C<$schema> will be parsed
to generate as much related metadata as possible.

As is desirable, then, the schema declaration may be updated, one attribute
at a time, such that attributes are declared via
C<$metadata-E<gt>add_attribute()> calls, thereby allowing a more complete
set of metadata to be specified.

=cut

### Inheritance
# We cannot inherit from Myco::Base::Entity because it'll screw up access
# checking. This isn't really an entity class, anyway.
use base qw(Class::Tangram);

# Dummy method for stepping into Entity classes that don't have any
# breakable subroutines. Call this method in any Entity class to use it.
sub _debug_hook {
    print 'debugging';
}


### Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use Myco::Base::Entity::Meta::Util;
use Myco::Base::Entity::Meta::UI;
use Myco::Base::Entity::Meta::Attribute;

# WEIRD:  uncommenting this causes bizarre compile failure
#use Myco::UI::Auth;

### Class Data

use constant META => 'Myco::Base::Entity::Meta::';
use constant META_UTIL => META . 'Util';
use constant META_UI => META . 'UI';
use constant META_ATTR => META . 'Attribute';
use constant META_ATTR_UI => META_ATTR . '::UI';

use constant TANGRAM_SCHEMA_KEYS => [qw(table bases abstract)];


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

[Note the behavior described below by which some attributes provide
access to sections of a classE<39>s POD documentation has not yet been
implemented]

=head2 name

 type: string [required]

The name of the class described by this metadata object.

=head2 abstract

 type: string

The ABSTRACT section of the classE<39>s POD documentation.

=head2 access_list

 type: hash ref

Hash containing either or both of these keys:  rw, ro (for read-write,
read-only, respectively).  Each key corresponds to an anonymous array of
names user roles authorized for the given type of access.

=cut

sub get_access_list {
    my $ac = $_[0]->SUPER::get_access_list;
    $_[0]->SUPER::set_access_list($ac = {}) unless $ac;
    return $ac;
}

=head2 attributes

 type: hash ref [read-only]

A hash containing metadata describing the classE<39>s object attributes. The
hash maps attribute names to respective Myco::Base::Entity::Meta::Attribute
objects. New entries to this hash should be added using only the
C<add_attribute()> method (described below). There is no reason why
C<set_attributes> should ever be called.

=cut

sub get_attributes {
    my $attributes = $_[0]->SUPER::get_attributes;
    $_[0]->set_attributes($attributes = {}) unless $attributes;
    return $attributes;
}

=head2 queries

 type: hash ref [read-only]

A hash containing metadata describing object attributes for any queries defined
for this object. The hash is keyed my name. New entries to this hash should be added using only the C<add_query()> method (described below). There is no reason why C<set_queries> should ever be called.

=cut

sub get_queries {
    my $self = shift;
    my $queries = $self->SUPER::get_queries;
    $self->set_queries($queries = {}) unless $queries;
    return $queries;
}

=head2 code

 type: hash ref [read-only]

Metadata-related code references generated during the call to
C<activate_class()>.  Keys that may be present (shown with example of typical
usage):

=over 4

=item

I<displayname>

 print $metadata->get_code->{displayname}->($instance);

See metadata attribute C<ui> sub-key C<displayname> (below).

=back

=head2 description

 type: string

The DESCRIPTION section of the classE<39>s POD documentation.

=head2 inheritence

 type: array ref

Array of classes from which this class inherits (same as @ISA).

=head2 methods

 type: hash ref

A hash containing metadata describing the classE<39>s object methods.
Functionality not yet implemented.

=head2 related_docs

 type: string

The SEE ALSO section of the classE<39>s POD documentation.

=head2 revision_date

 type: string

The classE<39>s revision date, pulled from the DATE section of its
POD documentation.

=head2 synopsis

 type: string

The SYNOPSIS section of the classE<39>s POD documentation.

=head2 tangram

 type: hash ref

 { table => 'foo'
   bases => [qw( MyParent )] }

An anonymous hash containing a
L<Class::Tangram|Class::Tangram>-style schema definition [but --without-- a
'fields' key!].  This attribute may be left unset if related features
are not needed by the class being set up (like persistence or
schema inheritence).

=head2 template_filtering

 type: string

Provides control over how template attributes (defined in super classes) are
handled for the entity class being established.  Available settings:

=over 4

=item *

accept

(default) Super class template attributes become defined as native attributes.


=item *

block

Super class template attributes are ignored.

=item *

passthru

Super class template attributes remain as template attributes as
they are imported from the super class; they exist only as metadata (their
metadata is copied verbatim from the super class).  As such the template
attrbiutes may be considered as simply "passing through" from the super
class to any subclasses.

=back

=head2 ui

 type: hash ref

Metadata expressing desired default behavior when generating user interfaces
for this class.  Valid keys are as follows:

=cut

sub set_ui {
    my ($self, $ui) = @_;

    if (ref $ui eq META_UI) {
        # handed a META_UI obj... use it!
        $self->SUPER::set_ui($ui);
        # set the 'meta' attrib if empty
        $ui->set_meta($self) unless $ui->get_meta;

    } else {
        # val must be a META_UI->new happy hashref
        $self->SUPER::set_ui($ui = META_UI->new
                   ( %$ui,
                     meta => $self
                   ));
    }
}

# Create ..::UI object if none exists
sub get_ui {
    my $self = shift;
    my $ui = $self->SUPER::get_ui;
    return $ui if ref $ui;
    # Create ..::UI object since none exists
    $self->set_ui( );
    return $self->SUPER::get_ui;
}

=over 4

=item

I<attribute_options>

 type: hash ref  [read only]

 { hidden => [ 'attr1', 'attr3' ] }

Hash keys:   names of attribute UI metadata options (see I<options> under C<ui>
attribute of
L<Myco::Base::Entity::Meta::Attribute|Myco::Base::Entity::Meta::Attribute>).
Hash values:  reference to an array of entity attributes having the given
option set.  This will automatically be set up during metadata initialization.

I<displayname>

 type: string or code ref

 sub { $_[0]->get_attr1 . ' ' . $_[0]->get_attr2 }

The name of an attribute containing values that uniquely describe a given
object of this class -or- an anonymous subroutine that, if called
as an object method, returns a value that serves the same purpose.
This value is used has heading for views of individual objects and in lists
of objects (see key C<list>, below).

I<list>

 type: hash ref

 {
   layout => [qw(__DISPLAYNAME__ attr2 attr3)],
 }

Allows spefication of a display format used by default when objects of
this class are displayed in a list.  The C<layout> sub-array specifies the
entity attributes, and order thereof, used in the listing.  An array element
containing the string "__DISPLAYNAME__" will result in the list attribute for
the given position being populated as directed via the C<displayname>
key (above).

I<view>

 type: hash ref

 {
   layout => [qw(attr4 attr3)],
 }

Allows specification of a display format used by default when an object of
this class is viewed.  Attributes are displayed in the specified order.

=back


=head2 version

 type: string

The classE<39>s current version number, pulled from the VERSION section of its
POD documentation.

=cut

### Object Schema Definition
our $schema =
  {
   fields =>
    { transient =>
        { name => { required => 1 },
          access_list => {},
          abstract => {},
          code => {},
          description => {},
          inheritence => {},
          methods => {},
          related_docs => {},
          revision_date => {},
          synopsis => {},
          tangram => {},
          template_filtering => {},
          version => {},
        },
      hash => { attributes => {},
                queries => {}
              },
      ref => { ui => { class => 'Myco::Base::Entity::Meta::UI' } },
    },
  };
Class::Tangram::import_schema(__PACKAGE__);

### Methods

=head1 COMMON ENTITY INTERFACE

constructor, accessors, and other methods --  as inherited from
Class::Tangram.  Persistence related methods do not apply.

=cut


=head1 ADDED CLASS / INSTANCE METHODS

=head2 activate_class

 $metadata->activate_class;

Builds $schema for the entity class that $metadata describes into a
Class::Tangram complient schema data structure and then activates it using
C<Myco::Base::Entity::import_schema()>.  This statement should be placed
as the last line in the classE<39>s source file.

Additional detail about the entity class is discovered and stored within
$metadata.  For example, for each entity attribute a closure is created
capable of generating an appropriate user interface element for that
attribute.  (See ...::Meta::Attribute for more detail.)

INSTALLED METHODS

These new methods are installed directly into the described class namespace.

I<displayname()>

An instance method;  returns the displayname of the
calling entity instance, in accordance with the setting of the
C<displayname> class metadata attribute (see ATTBRIBUTES section).

I<introspect()>

Both a class and instance method;  returns a reference to the
...::Meta object describing the class.

=cut

sub new {
    shift->SUPER::new(@_);
}

sub activate_class {
    my $self = shift;
    my %params = @_;
    my $queries = $params{queries};
    my $class = $self->get_name;
    my $class_schema;


    my $class_ISA = [];
    {
        no strict qw(refs vars);
        $class_schema = $ {"${class}::schema"} ||= {};

        # Init 'inheritence' attrib
        $self->set_inheritence( $class_ISA = \ @{"${class}::ISA"} )
          if @{"${class}::ISA"};
    }

    # Template Attrib Filtering -- look up / set default
    my $template_filtering = $self->get_template_filtering;
    $self->set_template_filtering( $template_filtering = 'accept')
      unless $template_filtering;

    # Init 'tangram' attrib if needed
    my $t_opts = $self->get_tangram;
    $self->set_tangram( $t_opts = {} ) unless ref $t_opts eq 'HASH';


    # Generate attribute metadata for any old-style $schema->{fields} attribs
    my $attributes = $self->get_attributes;
    {
        last unless exists $class_schema->{fields};
        for my $type (keys %{ $class_schema->{fields} }) {
            my $type_fmt = ref $class_schema->{fields}{$type};
            if ($type_fmt eq 'HASH') {
                while (my ($newattr, $opts) =
                              each %{ $class_schema->{fields}{$type} }) {
                    # skip if we already have a attrib meta obj for this
                    next if exists $attributes->{$newattr};
                    # add it
                    my $attr_meta = $self->add_attribute(name => $newattr,
                                                         type => $type);
                    if (ref $opts eq 'HASH' and keys %$opts) {
                        $attr_meta->set_tangram_options($opts);
                        _parse_SQL_string_length($attr_meta, $opts);
                    }
                }
            } elsif ($type_fmt eq 'ARRAY') {
                for my $newattr (@{ $class_schema->{fields}{$type} }) {
                    $self->add_attribute(name => $newattr,
                                         type => $type);
                }
            } # else ignore type
        }

        # Create metadata for old_schema tangram options... unless
        # same key already exists:  Meta-data spec'd options override
        # old-style options of same name
        for my $schema_key ( @{+TANGRAM_SCHEMA_KEYS} ) {
            next unless defined($class_schema->{$schema_key});
            $t_opts->{$schema_key} = $class_schema->{$schema_key}
              unless defined $t_opts->{$schema_key};
        }
    }

    # Add to entity schema any metadata tangram options
    if (1) {
        while (my ($t_key, $t_val) = each %$t_opts) {
            $class_schema->{$t_key} = $t_val;
        }
    }

    # Generate $schema->{fields} from metadata
    #     first we'll zap any existing 'fields' entries
    $class_schema->{fields} = undef;
    while (my ($newattr, $newmeta) = each %$attributes) {
        if ( $newmeta->{template} ) {
            $newmeta->{template} = 53;  # leave a note for post inheritence
        } else {
            _gen_schema_field($class_schema, $newattr, $newmeta)
        }
    }

    ######################################################################
    # Schema Inheritence
    ######################################################################
    # If schema inheritence is in use generate metadata for inherited attribs
    #
    #  Schema inheritence (in Class::Tangram) happens two ways...
    #  via Perl inheritence (@ISA) and via the 'bases' schema key.
    #  Perl inheritence takes precedence for the _memory_ object behavior
    #  (ie. if @ISA is non-empty then the 'bases' key is ignored for _memory_
    #  behavior but it is _required_ (by Tangram) if the inherited attribs
    #  are to have persistence!!!)
    #
    #  Here we create metadata for attribs inherited either way
    #
    if (@$class_ISA or ref $t_opts->{bases} eq 'ARRAY') {
        my $CT_types = Class::Tangram::attribute_types($class);

        # Inherit non-Tangram/Class::Tangram metadata
        #
        # As with Class::Tangram itself, if @ISA is non-empty then
        #    we ignore 'bases'
        my @bases = @{ @$class_ISA ? $class_ISA : $t_opts->{bases} };

        # Locate non-tangram attr metadata in base classes and inherit
        for my $super ( @bases ) {
            if (UNIVERSAL::can($super, 'introspect')) {
                my $meta = $super->introspect;
                META_UTIL->clone( $self , $meta );
            }
        }
    }

    ##########################################################################
    # Init other metadata nooks and crannies
    #

    # This looks useful
    my $meta_ui = $self->get_ui;
    my $meta_ui_attr_opts = $meta_ui->get_attribute_options;

    # for each attribute
    #    process as appropriate if a template attrib
    #    set up stored method coderefs
    #    set up ui->attribute_options hash
    #    set up ui->widget default, if needed
    my (@blocked_template_attrs, @installed_template_attrs);
    while (my ($aname, $attr) = each %$attributes ) {

        ## Add to schema any "template" attributes, just discovered during
        ## metadata inheritence
        if ( exists $attr->{template}
             and ! exists $class_schema->{fields}{$aname} ) {
            if ($attr->{template} == 53) {
                # Hmmmm... we seem to be activating the class where this
                #   template attribute is defined... skip
                $attr->{template} = 1;
                next;
            }

            # Deal with special template attribute handling instruction
            if ($template_filtering) {
                if ( $template_filtering eq 'passthru') {
                    # Template attr metadata accepted as is,
                    # _not_ added to active schema
                    next;
                }
                if ( $template_filtering eq 'block') {
                    # No thanks... schedule trashing of this attrs metadata
                    push @blocked_template_attrs, $aname;
                    next;
                }
            }

            # Make this template attrib a native attribute of this entity class
            delete $attr->{template};
            _gen_schema_field($class_schema, $aname, $attr);
            push @installed_template_attrs, $attr;

        }

        # Axe blocked template attributes
        map { delete $attributes->{$_} } @blocked_template_attrs;

        ## coderefs for this attribute's accessors
        foreach my $getset (qw(get set)) {
            my $accessor = $getset.'_'.$aname;
            my $code = UNIVERSAL::can($class, $accessor);
            unless ($code) {
                # No locally defined getter method... fall back
                # to the SUPER-ish 'get' / 'set'
                my $super_getset = UNIVERSAL::can($class, $getset);
                $code = do {
                    if ($getset eq 'get') {
                        sub { $super_getset->($_[0], $aname) }
                    } else {
                        sub { $super_getset->(shift, $aname, @_) }
                    }
                };
            }
            # This should never happen... since Class::Tangram's get()
            #   ain't goin' nowhere
            Myco::Exception::Meta->throw
              (error => "Class $class -- unable to locate coderef for " .
                        "method  $accessor")
                unless $code;
            my $md_acc_setter = 'set_'.$getset.'ter';
            $attr->$md_acc_setter($code);

        }
        # Set up ui->attribute_options hash
        my $attr_ui = $attr->get_ui;
        if (my $opts = $attr_ui->get_options) {
            for my $option ( keys %$opts ) {
                $meta_ui_attr_opts->{$option} = []
                  unless exists $meta_ui_attr_opts->{$option};
                push @{ $meta_ui_attr_opts->{$option} }, $aname;
            }
        }

        # Set up default ui->widget if needed
        my $values = $attr->get_values;
        my $widget = $attr_ui->get_widget;
        if ( defined $values and @$values
             and (!defined $widget
                  or ! @$widget
                  or $widget->[0] eq 'textfield')) {
            $attr_ui->set_widget( [ 'popup_menu' ]);
        }

        #######################################
        ## Enforce attrib 'readonly' nature
        #######################################
        if ( $attr->get_readonly ) {
            no strict 'refs';

            # install set_ATTRIB() blocker
            my $bad_setter = 'set_'.$aname;
            *{$class.'::'.$bad_setter} = sub {
                Myco::Exception::MNI->throw
                    (error => "unknown method/attribute $class"
                     . "->$bad_setter called.  Attribute is read-only");
            } unless UNIVERSAL::can($class, $bad_setter);

            # install ATTRIB() blocker
            *{$class.'::'.$aname} = sub {
                Myco::Exception::MNI->throw
                    (error => "unknown method/attribute ${class}->$aname"
                                                                   .'called');
            } unless UNIVERSAL::can($class, $aname);
        }
    }

    ## create proper displayname anon sub, if we can
    my $ui_dname_closure;
    if (my $dname_spec = $meta_ui->get_displayname) {
        # ui..displayname is set... turn it into a proper anon sub
        my $ui_dname_sub = do {
            my $dname_spec_type = ref $dname_spec;
            if (! $dname_spec_type) {
                # dname_spec is an attrib name... make sure it's valid
                Myco::Exception::Meta->throw
                  (error => "Class $class, 'ui displayname' specified with " .
                            "invalid attribute name")
                  unless exists $attributes->{$dname_spec};

                # fetch coderef to this attribute's getter method
                $attributes->{$dname_spec}->get_getter;

            } elsif ($dname_spec_type eq 'CODE') {
                # dname_spec itself is a coderef... hopefully it's correct!
                $dname_spec;
            } else {
                Myco::Exception::Meta->throw
                  (error => "Class $class, 'ui displayname' must be name of " .
                            "attribute or coderef");
            }
        };
        # Okay!  Now wrap it in an instance method friendly closure
        $ui_dname_closure = sub {
            my $referent = shift;
            Myco::Exception::Meta->throw
              (error => "displayname() error -- may only be called as " .
                        "instance method")
              unless ref $referent;
            # generate the displayname for $referent object
            return $ui_dname_sub->($referent);
        };
    } else {
        # ui..displaname not specified... our dname_closure will return
        # the class name... a yucky concession prize
        $ui_dname_closure = sub { $class };
    }

    ## Establish 'code' hash
    my $codehash = $self->get_code;
    $self->set_code($codehash = {}) unless $codehash;
    # Save $ui_name_sub coderef in "code" metadata hash
    $codehash->{displayname} = $ui_dname_closure;

    ###################################
    ## Add class methods to $class !!!
    ###################################
    {
        no strict 'refs';
        # install introspect()
        *{"${class}::introspect"} = sub { $self };
        # install displayname()
        *{"${class}::displayname"} = $ui_dname_closure;
    }

    ##############################
    ## Make $class well-behaved
    ##############################
    Class::Tangram::import_schema($class);

    # For template attribs work with Class::Tangram to generate
    # accessors, etc. in the correct place (in a ::CT class _above_
    # the highest class in inheritance tree that "can")
    for my $attr ( @installed_template_attrs ) {
        my $aname = $attr->get_name;
        my $accessors = Class::Tangram::_mk_accessor($aname,
                                                     $attr->get_tangram_options,
                                                     $class, '', $attr->get_type,
                                                     'dontcarp');
        while (my ($accessor, $coderef) = each %$accessors) {
            my ($accessor_name) = $accessor =~ /^::(.+)$/;
            my @they_that_can = _can($class, $accessor_name);
            next if ! @they_that_can;
            my $intermediate_class = $class.'::CT';
            my $ancestor_class = $they_that_can[$#they_that_can];
            my $installing = $they_that_can[0] eq $intermediate_class
              && $ancestor_class ne $intermediate_class;
            if ($installing) {
                no strict 'refs';
                # clobber (maybe)
#               delete ${'::' . $ancestor_class . '::'}{$accessor_name};
                # install
                *{$ancestor_class.'::CT::'.$accessor_name} = $coderef;
            }
        }

    }

    #########################################################
    ## Add query at the end - to avoid compile loops/problems
    #########################################################
    $queries->( $self ) if $queries && ref $queries eq 'CODE';
}
sub _can {
    my ($class, $meth) = @_;
    no strict 'refs';
    my @isa = @{$class."::ISA"};
    my @hits;
    if (@isa) {
        for my $pkg (@isa) {
            if ($pkg->can($meth)) {
                push @hits, $pkg;
                push @hits, _can($pkg, $meth);
            } else {
                push @hits, _can($pkg, $meth);
            }
        }
    }
    return @hits;
}

sub _parse_SQL_string_length {
    my ($attr, $opts) = @_;
    if (exists $opts->{sql}) {
        my ($length) = $opts->{sql} =~
          /\b(?:VAR)?CHAR\(\s*(\d*)\s*\)/i;
        if (defined $length) {
            my $type_opt = $attr->get_type_options;
            $attr->set_type_options( $type_opt = {} ) unless ref $type_opt;
            $type_opt->{string_length} = $length
        }
    }
}


sub _gen_schema_field {
    my ($class_schema, $newattr, $newmeta) = @_;

    my $type = $newmeta->get_type;
    my $tangram_opts = $newmeta->get_tangram_options || {};

    # Generate 'sql' option if meta data type_option 'string_length' is set
    if ( $type =~ /^\s*string\s*$/
         and exists($newmeta->{type_options})
         and defined($newmeta->{type_options}{string_length})
         and ! defined($tangram_opts->{sql}) ) {
        $tangram_opts->{sql} = 'VARCHAR('
          .$newmeta->{type_options}{string_length}.')';
    }
    # Add metadata-added attribute to $schema
    $class_schema->{fields}{$type}{$newattr} = $tangram_opts;
}



=head2 add_attribute

 $metadata->add_attribute(
   name => 'doneness',
   tangram_options => {required => 1},
   type => 'int',
   synopsis => "How you'd like your meat cooked",
   syntax_msg => "single number: 0 through 5",
   values => [qw(0 1 2 3 4, 5)],
   value_labels => {0 => 'rare',
                    1 => 'medium-rare',
                    2 => 'medium',
                    3 => 'medium-well',
                    4 => 'well',
                    5 => 'charred'},
   ui => { label => "Cook until..",
           widget => [ 'popup_menu' ] },
 );

Adds a Myco::Base::Entity::Meta::Attribute object containing metadata
that describes an attribute.  Valid named parameters are as follows:

=over

=item * name  [required]

=item * readonly

=item * syntax_msg

=item * synopsis

=item * tangram_options

=item * template

=item * type  [required]

=item * type_options

=item * value_labels

=item * values

=item * ui

=back

For more detail see ATTRIBUTES section from
L<Myco::Base::Entity::Meta::Attribute|Myco::Base::Entity::Meta::Attribute>

Note:  an attribute declared via C<add_attribute()> overrides any same-named
attribute declared directly in a C<$schema data> structure.

=cut

sub add_attribute {
    my $self = shift;

    my $attributes = $self->get_attributes;
    $self->set_attributes($attributes = {}) unless (defined $attributes);
    my $attr = eval { Myco::Base::Entity::Meta::Attribute->new(@_); };
    Myco::Exception::Meta->throw
      (error => "Exception during attempt to constuct the new ".
                "::Meta::Attribute metadata object for entity class " .
                $self->get_name .
                " - syntax error with add_attribute() parameters?  Raw " .
                "exception message:\n$@") if $@;
    $attributes->{$attr->get_name} = $attr;
}


=head2 add_query

 $metadata->add_query( %query_attributes );

Adds a Myco::Base::Entity::Meta::Query object. For more detail see
L<Myco::Base::Entity::Meta::Query|Myco::Base::Entity::Meta::Query>

=cut

sub add_query {
    my $self = shift;
    my %query_attrs = @_;

    # Delaying require of::Query until runtime
    my $isa = join '', @Myco::Base::Entity::Meta::Query::ISA;
    eval "require Myco::Base::Entity::Meta::Query"
      unless $isa =~ 'Myco::QueryTemplate';

    my ($new_query, $query_name);
    # Will clobber 'default' query if no name is given
    if (! $query_attrs{name}) {
        $query_name = 'default';
        $query_attrs{name} = 'default';
    } else {
        $query_name = $query_attrs{name};
    }
    eval {
        $new_query = Myco::Base::Entity::Meta::Query->new( %query_attrs );
    };
    if ($@) {
        Myco::Exception::Meta->throw
            ( error => 'Exception during attempt to constuct the new'
              . ' Myco::Query object for entity class ' . $self->get_name
              . " Raw exception message:\n$@" );
    } else {
        my %old_queries = %{ $self->SUPER::get_queries };
        $self->SUPER::set_queries( {%old_queries, $query_name => $new_query } );
    }
}

=head2 add_virtuals

=cut

sub add_virtuals {
    my $self = shift;

    my $attributes = $self->get_attributes;
    $self->set_attributes($attributes = {}) unless (defined $attributes);
    my $attr = eval { Myco::Base::Entity::Meta::Attribute->new(@_); };
    Myco::Exception::Meta->throw
      (error => "Exception during attempt to constuct the new ".
                "::Meta::Attribute metadata object for entity class " .
                $self->get_name .
                " - syntax error with add_attribute() parameters?  Raw " .
                "exception message:\n$@") if $@;
    $attributes->{$attr->get_name} = $attr;
}


1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Base::Entity::Meta::Attribute|Myco::Base::Entity::Meta::Attribute>,
L<Myco::Base::Entity|Myco::Base::Entity>,
L<Myco::Base::Entity::Meta::Test|Myco::Base::Entity::Meta::Test>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<mkentity|mkentity>

=cut
