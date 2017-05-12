package Myco::Base::Entity::Meta::Util;

###############################################################################
# $Id: Util.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Meta::Util - a Myco entity class

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

  use Myco;

  # Constructors. See Myco::Base::Entity for more.
  my $obj = Myco::Base::Entity::Meta::Util->new;

  # Accessors.
  my $value = $obj->get_fooattrib;
  $obj->set_fooattrib($value);

  $obj->save;
  $obj->destroy;

=head1 DESCRIPTION

Blah blah blah... Blah blah blah... Blah blah blah...
Blah blah blah blah blah... Blah blah...

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;

##############################################################################
# Programatic Dependencies


##############################################################################
# Constants
##############################################################################
use constant META => 'Myco::Base::Entity::Meta::';
use constant META_ATTR => META . 'Attribute';
use constant META_ATTR_UI => META_ATTR . '::UI';

# Regex matching classnames from this family of classes
my $meta_re = '^'.META;

# Type-specific defaults:
my $_default_meta = { ui => { widget => ['textfield'] } };
my $_type_defs =
  { rawdate     => { ui => { widget => ['textfield', -size => '12',
                                        -maxlength => '10', ],
                             suffix => q~[<a href="javascript:openCal('$formname','$params{-name}',document.$formname.$params{-name}.value)">E</a>]~,
                           },
                   },

### TODO:  create overriding new() to load _type_def defaults and then
  # override with passed in params.   This will allow definition
  # of new special-purpose data types with predefined UI behavior.  Some
  # examples (which won't function until new() is written) below.
  #
  # This new() is also where auto-generation of check functions will happen
  # (if $md->{values} is defined but not $md->{tangram_options}{check_func}.)
    yesno       => { type => 'int',
		     values => [0, 1],
		     value_labels => {0 => 'yes',
                                      1 => 'no'},
		     ui => { widget => ['radio_group'] },
                   },
    truefalse   => { type => 'int',
		     values => [0, 1],
		     value_labels => {0 => 'False',
                                      1 => 'True' },
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
##############################################################################
# Inheritance & Introspection
##############################################################################
#use base qw(Myco::Base::Entity);
#my $md = Myco::Base::Entity::Meta->new
#  ( name => __PACKAGE__,
#    tangram => { table => 'Myco::Base::Entity::Meta::Util' },
#    ui => { displayname => 'fooattrib' }
#  );

##############################################################################
# Function and Closure Prototypes
##############################################################################


##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Myco::Base::Entity.

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

=head2 fooattrib

 type: string   default: 'hello'

A whole lot of nothing

=cut

#$md->add_attribute(name => 'fooattrib',
#		   type => 'string',
#		   synopsis => 'foo for one',
#		   tangram_options => {init_default => 'hello'});

##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=head2 clone

  Myco::Base::Entity::Meta::Util->clone($meta_sub, $meta_super)

Will recursively clone a Meta:: object tree.

=cut

sub clone {
    my ($self, $sub, $super, %params) = @_;

    # Default... clone sub objects
    $params{enter_objects} = 1 unless exists $params{enter_objects};

    my $parent_node = defined $params{parent} ? $params{parent} : '';

    # Outer loop

    # We'll untilize ::Meta...'s Class::Tangram knowledge of itself to
    # direct our walk through the base class metadata... if we can.
    my $nodes;
    if ( UNIVERSAL::isa($super, 'Class::Tangram' ) ) {
        # Ah-ha!  We have a Class::Tangram-derived object!  What class?
        my $super_class = ref $super || $super;

        if ( $super_class eq 'Myco::Base::Entity::Meta') {
            # Very little is wanted in the way of inheritance for ::Meta
            # itself
            $nodes = [qw( access_list attributes synopsis ui )]
        } else {
            # Nodes?  If C::T doesn't know look directly (shhh)
            $nodes = [ keys %{ $super_class->attribute_options || $super } ];
        }
    } elsif ( ref $super eq 'HASH' ) {
        # We've got a non Class::Tangram hash... do direct hash access
        @$nodes = keys %$super;
    } else {
        warn "clone attempted on something other than a ::Meta... object or plain hash\n";
    }

    if ( $nodes ) {
        for my $node ( @$nodes) {
#            next if $node eq 'tangram_options';

            # Avoid deep recursion by not following a certain circ. ref
            next if ( $node eq 'attr' and
                      (ref $super eq META_ATTR_UI)
                          || (ref $super eq 'HASH' and $parent_node eq 'ui') );

            $self->clone_node($sub, $super, $node, %params);
        }
    }

    return $sub;
}

sub clone_node {
    my ($self, $sub, $super, $node, %params) = @_;

    $params{parent} = $node;

    my $getter = 'get_'.$node;
    my $setter = 'set_'.$node;

    # Whip up closures that know how to get, set this node
    my ($set_sub, $get_sub, $set_super, $get_super);

    #   ... super
    eval { $super->$getter };
    if ( ! $@ ) {
        $get_super = sub { $super->$getter };
    } else {
        $get_super = sub { $super->{$node} };
    }


    #   ... sub
    eval { $sub->$getter };
    if ( ! $@ ) {
        $set_sub = sub { $sub->$setter( $_[0] ) };
        $get_sub = sub { $sub->$getter };
    } else {
        $set_sub = sub { $sub->{$node} = $_[0] };
        $get_sub = sub { $sub->{$node} };
    }


    # Fetch node value
    my ($sub_node_val, $super_node_val) = ( $get_sub->(), $get_super->() );

    my $node_type = ref $super_node_val;
    if ($node_type eq 'ARRAY' or $node_type eq 'HASH') {
=pod
        if (ref $sub eq META and $node eq 'attributes') {
            for my $attr ( keys %$super_node_val ) {
                unless (exists $sub_node_val->{$attr}) {
                    warn "meta init:  fishyness when merging metadata for attrib $attr of class ". $self->get_name;
                    next;
                }

                # Clone the objs
                $self->clone( $sub_node_val->{$attr}, $super_node_val->{$attr},
                              %params );
            }
        } else {
=cut
            if ($node_type eq 'HASH') {
                return if ! keys %$super_node_val;

                # force this node in $sub to be HASH
                $set_sub->( $sub_node_val = {} )
                  if ref $sub_node_val ne 'HASH';
                # Some kinda normal hash.   Clone it!
                $self->clone( $sub_node_val, $super_node_val, %params );
            } else {
                # ditch if @$super empty or @$sub non-empty
                return if (! @$super_node_val
                           or (ref $sub_node_val eq 'ARRAY'
                               and @$sub_node_val));
                # Some kinda array.   Clone it!
                $set_sub->( [ @$super_node_val ] );
            }
#        }

    } elsif ($node_type =~ /$meta_re/o) {
        # Clone the other types of ::Meta objs

        return unless $params{enter_objects};  # are we cloning sub objects?

        my $sub_node_type = ref $sub_node_val;
        if ( ! $sub_node_type or $sub_node_type ne $node_type ) {
            # We'll be needing a new one
            $sub_node_val = {} unless $sub_node_type eq 'HASH';

            $sub_node_val = bless($sub_node_val, $node_type)
              unless $params{dont_bless};

            $set_sub->( $sub_node_val );
        }

        $self->clone( $sub_node_val, $super_node_val, %params );

    } else {
        # Some kinda scalar.   Clone it!
        $set_sub->( $super_node_val )
          if (defined $super_node_val and ! defined $sub_node_val);
    }
}


sub construct_meta_object {
    my $self = shift;
    my $referent = shift;
    my %params = @_;

    my $class = ref $referent || $referent;

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

    my $obj = $class->SUPER::new( %params );


    # Generate UI closure for this attribute
    my $ui = $obj->get_ui;

#    # Do metadata inheritence
#    Myco::Base::Entity::Meta->_clone_metadata(\%params, $typedef)

    return $obj;
}

=head2 barmeth

  $obj->barmeth(attribute => $value, ...)

blah blah blah

=cut

#sub barmeth {}


##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
#$md->activate_class;

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Base::Entity::Meta::Util::Test|Myco::Base::Entity::Meta::Util::Test>,
L<Myco::Base::Entity|Myco::Base::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<mkentity|mkentity>

=cut
